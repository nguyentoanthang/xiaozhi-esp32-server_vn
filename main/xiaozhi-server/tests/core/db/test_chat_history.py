"""Chat history: rows in chat_session / chat_message / chat_audio, written through the db writer."""
import asyncio
import math
import struct
import types
from unittest.mock import MagicMock

import pytest

from core.db import set_database
from core.db.chat_history import (
    AUDIO_FORMAT,
    encode_pcm_to_opus_frames,
    load_audio_frames,
    pack_opus_frames,
    unpack_opus_frames,
)

MAC = "aa:bb:cc:dd:ee:ff"


@pytest.fixture
def process_db(seeded_db):
    """seeded_db as the process-wide database (what reportHandle / memory use)."""
    set_database(seeded_db)
    yield seeded_db
    set_database(None)


def make_conn(mode=2, **kw):
    attrs = dict(
        chat_history_conf=mode, device_id=MAC.upper(), session_id="sess-1", agent_id="default",
        config={}, logger=MagicMock(), audio_format="opus", sample_rate=24000, db_enabled=True,
    )
    attrs.update(kw)
    return types.SimpleNamespace(**attrs)


def run_report(conn, chat_type, text, audio, ms=1_700_000_000_000):
    from core.handle.reportHandle import report

    asyncio.run(report(conn, chat_type, text, audio, ms))


def messages(db):
    db.flush()
    return db.query_all("SELECT * FROM chat_message ORDER BY id")


# ------------------------------------------------------------- container

def test_opus_container_round_trip():
    frames = [b"\x01\x02\x03", b"", b"x" * 400, bytes(range(256))]
    assert unpack_opus_frames(pack_opus_frames(frames)) == frames
    assert pack_opus_frames([]) == b""


def test_opus_container_rejects_truncated_data():
    blob = pack_opus_frames([b"abcdef"])
    with pytest.raises(ValueError):
        unpack_opus_frames(blob[:-1])
    with pytest.raises(ValueError):
        unpack_opus_frames(b"\x00")


def test_encode_uses_60ms_frames_and_pads_the_last_one(monkeypatch):
    """Plumbing of encode_pcm_to_opus_frames with a fake Opus encoder (runs without libopus)."""
    import core.utils.opus_encoder_utils as oeu

    seen = []

    class FakeEncoder:
        def __init__(self, rate, channels, application):
            seen.append((rate, channels))

        def encode(self, frame_bytes, frame_size):
            assert frame_size == 960 and len(frame_bytes) == 1920  # 60 ms of 16 kHz s16le
            return b"F" + bytes([len(seen) % 256])

    monkeypatch.setattr(oeu, "Encoder", FakeEncoder)
    monkeypatch.setattr(oeu, "constants", MagicMock())
    pcm = b"\x01\x00" * (960 * 2 + 100)  # two full frames and a partial one
    frames = encode_pcm_to_opus_frames(pcm, 16000)
    assert len(frames) == 3 and seen == [(16000, 1)]
    assert encode_pcm_to_opus_frames(b"", 16000) == []


def _real_opus():
    import opuslib_next

    if getattr(opuslib_next, "__file__", None) is None:
        pytest.skip("real opuslib_next / libopus not available (tests use a stub)")
    return opuslib_next


def test_pcm_to_opus_to_pcm_round_trip():
    """User audio is encoded once on save and decodes back to speech-like PCM (needs libopus)."""
    opus = _real_opus()
    rate, seconds = 16000, 1
    samples = [int(12000 * math.sin(2 * math.pi * 440 * i / rate)) for i in range(rate * seconds)]
    pcm = struct.pack(f"<{len(samples)}h", *samples)

    frames = encode_pcm_to_opus_frames(pcm, rate)
    assert 15 <= len(frames) <= 18  # 1 s in 60 ms frames
    assert sum(len(f) for f in frames) < len(pcm) // 4  # much smaller than PCM

    decoder = opus.Decoder(rate, 1)
    out = b"".join(decoder.decode(f, rate * 60 // 1000) for f in unpack_opus_frames(pack_opus_frames(frames)))
    decoded = struct.unpack(f"<{len(out) // 2}h", out)
    assert len(decoded) >= len(samples)
    # After the codec warm-up the tone is still there: energy is the same order of magnitude
    tail = decoded[rate // 4: rate // 2]
    rms = math.sqrt(sum(x * x for x in tail) / len(tail))
    assert 4000 < rms < 12000


# --------------------------------------------------------- history_mode

def test_mode_0_writes_nothing(process_db):
    conn = make_conn(mode=0)
    run_report(conn, 1, "hello", [b"\x00\x00" * 100])
    run_report(conn, 2, "hi there", [b"op"])
    assert messages(process_db) == []
    assert process_db.query_all("SELECT * FROM chat_session") == []


def test_mode_1_writes_text_only(process_db, monkeypatch):
    import core.handle.reportHandle as rh

    monkeypatch.setattr(rh, "encode_pcm_to_opus_frames", lambda pcm, rate: pytest.fail("must not encode"))
    conn = make_conn(mode=1)
    run_report(conn, 1, "hello", [b"\x00\x00" * 100])
    run_report(conn, 2, "hi there", [b"op1", b"op2"])
    rows = messages(process_db)
    assert [(r["chat_type"], r["content"], r["audio_id"]) for r in rows] == [(1, "hello", None), (2, "hi there", None)]
    assert process_db.query_one("SELECT COUNT(*) AS n FROM chat_audio")["n"] == 0
    session = process_db.query_one("SELECT * FROM chat_session")
    assert (session["id"], session["device_mac"], session["agent_id"]) == ("sess-1", MAC, "default")
    assert session["started_at"].endswith("Z") and session["ended_at"] is None


def test_mode_2_stores_user_pcm_as_opus_and_agent_opus_as_is(process_db, monkeypatch):
    import core.handle.reportHandle as rh

    encoded = []

    def fake_encode(pcm, rate):
        encoded.append((pcm, rate))
        return [b"E1", b"E2"]

    monkeypatch.setattr(rh, "encode_pcm_to_opus_frames", fake_encode)
    conn = make_conn(mode=2)
    run_report(conn, 1, "hello", [b"\x01\x00" * 50, b"\x02\x00" * 50])
    run_report(conn, 2, "hi there", [b"opus-packet-1", b"opus-packet-2"])

    # User PCM is joined and encoded once at 16 kHz; agent packets are not touched
    assert encoded == [(b"\x01\x00" * 50 + b"\x02\x00" * 50, 16000)]
    user, agent = messages(process_db)
    assert user["audio_id"] is not None and agent["audio_id"] is not None
    assert load_audio_frames(process_db, user["audio_id"]) == [b"E1", b"E2"]
    assert load_audio_frames(process_db, agent["audio_id"]) == [b"opus-packet-1", b"opus-packet-2"]
    audio = process_db.query_all("SELECT format, sample_rate FROM chat_audio ORDER BY id")
    assert [(a["format"], a["sample_rate"]) for a in audio] == [(AUDIO_FORMAT, 16000), (AUDIO_FORMAT, 24000)]


def test_text_only_item_in_mode_2_has_no_audio(process_db):
    run_report(make_conn(mode=2), 1, "typed text", [])
    (row,) = messages(process_db)
    assert row["audio_id"] is None


def test_encoding_failure_keeps_the_text_row(process_db, monkeypatch):
    import core.handle.reportHandle as rh

    def broken(pcm, rate):
        raise RuntimeError("no libopus")

    monkeypatch.setattr(rh, "encode_pcm_to_opus_frames", broken)
    conn = make_conn(mode=2)
    run_report(conn, 1, "hello", [b"\x00\x00" * 10])
    (row,) = messages(process_db)
    assert row["content"] == "hello" and row["audio_id"] is None
    conn.logger.bind.return_value.error.assert_called()


def test_user_text_in_asr_json_form_is_stored_as_plain_content(process_db):
    run_report(make_conn(mode=1), 1, '{"speaker": "Linh", "content": "mail [EMAIL_1]"}', None)
    (row,) = messages(process_db)
    assert row["content"] == "mail [EMAIL_1]"


def test_messages_keep_their_order_and_tool_rows_are_type_3(process_db):
    conn = make_conn(mode=1)
    run_report(conn, 1, "weather?", None, 1_700_000_000_000)
    run_report(conn, 3, '[{"type": "tool", "text": "get_weather()"}]', None, 1_700_000_000_500)
    run_report(conn, 2, "sunny", None, 1_700_000_001_000)
    assert [r["chat_type"] for r in messages(process_db)] == [1, 3, 2]
    assert process_db.query_one("SELECT COUNT(*) AS n FROM chat_session")["n"] == 1


def test_missing_agent_id_falls_back_to_the_default_agent_id(process_db):
    run_report(make_conn(mode=1, agent_id=None, config={"default_agent_id": "default"}), 1, "hi", None)
    process_db.flush()
    assert process_db.query_one("SELECT agent_id FROM chat_session")["agent_id"] == "default"


def test_writer_failure_never_breaks_the_conversation(seeded_db):
    # A closed database cannot accept writes; report() must log and return normally
    set_database(seeded_db)
    seeded_db.close()
    try:
        run_report(make_conn(mode=2), 1, "hello", None)
    finally:
        set_database(None)


def test_failing_insert_is_logged_by_the_writer_and_next_write_works(process_db):
    from core.db.chat_history import record_message

    bad = record_message(
        process_db, session_id="s", device_mac=MAC, agent_id="a", chat_type=1, content=None  # NOT NULL
    )
    assert process_db.wait(bad) is False
    run_report(make_conn(mode=1), 1, "still works", None)
    assert [r["content"] for r in messages(process_db)] == ["still works"]
    # the failed transaction left nothing behind
    assert process_db.query_one("SELECT COUNT(*) AS n FROM chat_session WHERE id = 's'")["n"] == 0
