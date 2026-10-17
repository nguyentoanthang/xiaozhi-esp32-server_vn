"""Chat history storage: chat_session / chat_message / chat_audio.

All writes go through the Database writer thread (never the event loop, never blocking a
conversation). Audio is stored as Opus packets in a small length-prefixed container
(chat_audio.format = 'opus-frames'): per packet a 2-byte big-endian length, then the packet.

Only the standard library is imported at module level; the Opus encoder is imported lazily.
"""

import struct
from concurrent.futures import Future
from datetime import datetime, timezone
from typing import List, Optional, Sequence

from core.db.database import Database, _log, utcnow_iso

TAG = "core.db.chat_history"

AUDIO_FORMAT = "opus-frames"
USER_SAMPLE_RATE = 16000  # PCM that reaches the ASR is 16 kHz mono s16le
OPUS_FRAME_MS = 60

CHAT_USER, CHAT_AGENT, CHAT_TOOL = 1, 2, 3


def pack_opus_frames(frames: Sequence[bytes]) -> bytes:
    """Opus packets -> one BLOB (2-byte big-endian length + packet, repeated)."""
    parts: List[bytes] = []
    for frame in frames:
        if len(frame) > 0xFFFF:
            raise ValueError("Opus packet too large")
        parts.append(struct.pack(">H", len(frame)))
        parts.append(bytes(frame))
    return b"".join(parts)


def unpack_opus_frames(blob: bytes) -> List[bytes]:
    """Inverse of pack_opus_frames."""
    frames: List[bytes] = []
    pos = 0
    while pos < len(blob):
        if pos + 2 > len(blob):
            raise ValueError("Truncated Opus container")
        (n,) = struct.unpack_from(">H", blob, pos)
        pos += 2
        if pos + n > len(blob):
            raise ValueError("Truncated Opus container")
        frames.append(blob[pos:pos + n])
        pos += n
    return frames


def encode_pcm_to_opus_frames(
    pcm: bytes, sample_rate: int = USER_SAMPLE_RATE, frame_ms: int = OPUS_FRAME_MS
) -> List[bytes]:
    """Encode mono s16le PCM to Opus packets with the server's own encoder (one lossy encode)."""
    from core.utils.opus_encoder_utils import OpusEncoderUtils

    if len(pcm) % 2:
        pcm = pcm[:-1]
    frames: List[bytes] = []
    encoder = OpusEncoderUtils(sample_rate=sample_rate, channels=1, frame_size_ms=frame_ms)
    try:
        encoder.encode_pcm_to_opus_stream(pcm, end_of_stream=True, callback=frames.append)
    finally:
        encoder.close()
    return frames


def _iso_from_ms(ms: Optional[int]) -> str:
    if not ms:
        return utcnow_iso()
    return datetime.fromtimestamp(ms / 1000, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def record_message(
    db: Database,
    *,
    session_id: str,
    device_mac: str,
    agent_id: str,
    chat_type: int,
    content: str,
    opus_frames: Optional[Sequence[bytes]] = None,
    sample_rate: int = USER_SAMPLE_RATE,
    created_ms: Optional[int] = None,
) -> Future:
    """Queue one message (creating the session row on first use, and the audio row when given).

    The three inserts run in one writer transaction, so the FIFO writer keeps messages in order
    and a message never points at a missing audio row.
    """
    now = _iso_from_ms(created_ms)
    blob = pack_opus_frames(opus_frames) if opus_frames else None

    def work(conn):
        conn.execute(
            "INSERT OR IGNORE INTO chat_session(id, device_mac, agent_id, started_at) VALUES (?, ?, ?, ?)",
            (session_id, device_mac, agent_id, now),
        )
        audio_id = None
        if blob:
            audio_id = conn.execute(
                "INSERT INTO chat_audio(format, sample_rate, data) VALUES (?, ?, ?)",
                (AUDIO_FORMAT, sample_rate, blob),
            ).lastrowid
        return conn.execute(
            "INSERT INTO chat_message(session_id, chat_type, content, audio_id, created_at) "
            "VALUES (?, ?, ?, ?, ?)",
            (session_id, chat_type, content, audio_id, now),
        ).lastrowid

    return db.submit(work)


def mark_session_ended(db: Database, session_id: str) -> Future:
    """Set ended_at (no-op if the session has no row, i.e. history was off or nothing was said)."""
    return db.write("UPDATE chat_session SET ended_at = ? WHERE id = ?", (utcnow_iso(), session_id))


def set_session_title(
    db: Database, session_id: str, title: Optional[str], summary: Optional[str]
) -> Future:
    return db.write(
        "UPDATE chat_session SET title = ?, summary = ? WHERE id = ?", (title, summary, session_id)
    )


def load_audio_frames(db: Database, audio_id: int) -> Optional[List[bytes]]:
    """Read a stored clip back as Opus packets (None if the row does not exist)."""
    row = db.query_one("SELECT format, data FROM chat_audio WHERE id = ?", (audio_id,))
    if row is None:
        return None
    if row["format"] != AUDIO_FORMAT:
        _log("warning", f"Unknown chat_audio format {row['format']!r} for id {audio_id}")
        return None
    return unpack_opus_frames(row["data"])
