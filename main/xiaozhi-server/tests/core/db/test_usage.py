"""The ai_usage recorder (core/db/usage.py) and call_llm_no_stream, on a seeded temporary database."""
import threading

import pytest

from core.db import set_database
from core.db.usage import (
    Attribution,
    UsageScope,
    attribution_from_conn,
    bind_attribution,
    current_attribution,
    record_usage,
    track_stream,
)
from core.utils.llm_call import call_llm_no_stream


@pytest.fixture
def udb(seeded_db):
    set_database(seeded_db)
    yield seeded_db
    set_database(None)


def usage_rows(db, where="1=1"):
    db.flush()
    return db.query_all(f"SELECT * FROM ai_usage WHERE {where} ORDER BY id")


class Record:
    """Duck-typed core.providers.llm.openrouter.usage.UsageRecord."""

    def __init__(self, **kw):
        self.call_kind = "no_stream"
        self.requested_model = "fake/m"
        self.__dict__.update(kw)


class ReportingLLM:
    model_name = "fake/m"

    def __init__(self, record=None, fail=False):
        self.record, self.fail = record, fail

    def response_no_stream(self, system_prompt, user_prompt, **kwargs):
        from core.db import usage

        if self.record is not None and usage._scope.get() is not None:
            usage._scope.get().absorb(self.record)  # what the bridge sink does for emit_usage()
        if self.fail:
            raise RuntimeError("llm down")
        return "ok"


A1 = Attribution(device_mac="aa:01", agent_id="default", session_id="s1")


def test_record_usage_stores_every_field(udb):
    assert record_usage(
        kind="llm", purpose="chat", attribution=A1, call_kind="chat", requested_model="r", served_model="s",
        provider="p", generation_id="g", prompt_tokens=10, completion_tokens=5, total_tokens=15,
        cached_tokens=4, cost=0.5, upstream_cost=0.4, is_byok=True, ttft_ms=7, duration_ms=9,
    )
    (row,) = usage_rows(udb)
    assert (row["session_id"], row["device_mac"], row["agent_id"], row["purpose"]) == ("s1", "aa:01", "default", "chat")
    assert (row["prompt_tokens"], row["cached_tokens"], row["cost"], row["upstream_cost"], row["is_byok"]) == (10, 4, 0.5, 0.4, 1)
    assert row["created_at"].endswith("Z") and row["record_id"]


def test_missing_usage_is_stored_as_null_not_zero(udb):
    record_usage(purpose="chat", attribution=A1)
    (row,) = usage_rows(udb)
    assert row["prompt_tokens"] is None and row["total_tokens"] is None and row["cost"] is None
    assert udb.query_one("SELECT SUM(cost) AS c, COUNT(*) AS n FROM ai_usage")["c"] is None


def test_ambient_attribution_is_per_context(udb):
    seen = []
    with bind_attribution(A1):
        assert current_attribution() == A1
        t = threading.Thread(target=lambda: seen.append(current_attribution()))
        t.start()
        t.join()
        record_usage(purpose="memory")
    assert seen == [None]  # a thread started by hand does not inherit it
    assert current_attribution() is None
    (row,) = usage_rows(udb)
    assert (row["device_mac"], row["agent_id"], row["session_id"]) == ("aa:01", "default", "s1")


def test_attribution_from_conn_lowercases_the_mac_and_falls_back_to_default_agent():
    class Conn:
        device_id = "AA:BB:01"
        agent_id = None
        session_id = "s9"
        config = {"default_agent_id": "dflt"}

    assert attribution_from_conn(Conn()) == Attribution("aa:bb:01", "dflt", "s9")
    assert attribution_from_conn(object()) == Attribution(None, None, None)


def test_call_llm_no_stream_records_provider_usage(udb):
    record = Record(prompt_tokens=11, completion_tokens=3, total_tokens=14, cached_tokens=2, cost=0.002,
                    served_model="fake/m-v2", generation_id="g1", selected_provider="Acme", duration_ms=55)
    assert call_llm_no_stream(ReportingLLM(record), "memory", "sys", "user", A1) == "ok"
    (row,) = usage_rows(udb)
    assert (row["purpose"], row["kind"], row["call_kind"]) == ("memory", "llm", "no_stream")
    assert (row["prompt_tokens"], row["total_tokens"], row["cached_tokens"], row["cost"]) == (11, 14, 2, 0.002)
    assert (row["served_model"], row["provider"], row["generation_id"], row["duration_ms"]) == ("fake/m-v2", "Acme", "g1", 55)
    assert (row["device_mac"], row["agent_id"], row["session_id"]) == ("aa:01", "default", "s1")


def test_call_llm_no_stream_without_reported_usage_and_with_ambient_attribution(udb):
    with bind_attribution(A1):
        call_llm_no_stream(ReportingLLM(), "title", "sys", "user")
    (row,) = usage_rows(udb)
    assert row["purpose"] == "title" and row["requested_model"] == "fake/m"
    assert row["total_tokens"] is None and row["cost"] is None
    assert (row["device_mac"], row["agent_id"]) == ("aa:01", "default")


def test_failed_llm_call_still_records_and_reraises(udb):
    with pytest.raises(RuntimeError):
        call_llm_no_stream(ReportingLLM(fail=True), "intent", "s", "u", A1)
    (row,) = usage_rows(udb)
    assert row["purpose"] == "intent"


def test_purposes_are_checked():
    with pytest.raises(ValueError):
        call_llm_no_stream(ReportingLLM(), "bogus", "s", "u")


def test_writer_failure_does_not_break_the_call(udb):
    udb.close()  # the writer is gone: every write is dropped (logged)
    assert call_llm_no_stream(ReportingLLM(Record(total_tokens=1)), "memory", "s", "u", A1) == "ok"
    assert record_usage(purpose="chat", attribution=A1, db=udb) is True  # queued call returns, the Future failed


def test_broken_database_does_not_raise(monkeypatch):
    def boom(*a, **k):
        raise OSError("disk gone")

    monkeypatch.setattr("core.db.usage.get_database", boom)
    assert record_usage(purpose="chat", attribution=A1) is False
    assert call_llm_no_stream(ReportingLLM(), "memory", "s", "u", A1) == "ok"


def test_track_stream_writes_one_row_and_also_when_closed_early(udb):
    def stream():
        from core.db import usage

        try:
            yield "a"
            yield "b"
        finally:
            usage._scope.get().absorb(Record(call_kind="chat", total_tokens=7))

    scope = UsageScope("chat", A1, call_kind="chat")
    assert list(track_stream(stream(), scope)) == ["a", "b"]
    early = track_stream(stream(), UsageScope("chat", A1, call_kind="chat"))
    assert next(early) == "a"
    early.close()
    rows = usage_rows(udb)
    assert [r["total_tokens"] for r in rows] == [7, 7] and [r["call_kind"] for r in rows] == ["chat", "chat"]


def test_track_stream_row_is_written_when_the_stream_fails(udb):
    def stream():
        yield "a"
        raise RuntimeError("boom")

    with pytest.raises(RuntimeError):
        list(track_stream(stream(), UsageScope("chat", A1, call_kind="chat")))
    (row,) = usage_rows(udb)
    assert row["purpose"] == "chat" and row["total_tokens"] is None


def test_views_sum_a_scripted_scenario_with_an_agent_change_midway(udb):
    """Device m1 moves from 'default' to 'b' after two calls; rows copy the agent at call time."""
    udb.write_sync("INSERT INTO agent(id, name) VALUES ('b', 'Agent B')")
    m1_old, m1_new = Attribution("m1", "default", "s1"), Attribution("m1", "b", "s2")
    m2 = Attribution("m2", "default", "s3")
    record_usage(purpose="chat", attribution=m1_old, prompt_tokens=100, completion_tokens=10, total_tokens=110, cost=0.01)
    record_usage(purpose="memory", attribution=m1_old, prompt_tokens=200, completion_tokens=20, total_tokens=220, cost=0.02)
    record_usage(purpose="chat", attribution=m2, prompt_tokens=400, completion_tokens=40, total_tokens=440, cost=0.04)
    udb.write_sync("INSERT INTO device(mac, agent_id) VALUES ('m1', 'b')")  # the re-assignment
    record_usage(purpose="chat", attribution=m1_new, prompt_tokens=1000, completion_tokens=100, total_tokens=1100, cost=0.10)
    record_usage(purpose="title", attribution=m1_new, prompt_tokens=50, completion_tokens=5, total_tokens=55)  # cost unknown
    record_usage(kind="stt", purpose="stt", attribution=m1_new, audio_seconds=3.0, cost=0.003)
    udb.flush()

    by_device = {(r["device_mac"], r["kind"]): r for r in udb.query_all("SELECT * FROM usage_by_device")}
    m1 = by_device[("m1", "llm")]
    assert (m1["calls"], m1["prompt_tokens"], m1["completion_tokens"], m1["total_tokens"]) == (4, 1350, 135, 1485)
    assert m1["cost_usd"] == pytest.approx(0.13)  # NULL cost rows add nothing
    assert by_device[("m1", "stt")]["cost_usd"] == pytest.approx(0.003)
    assert by_device[("m2", "llm")]["total_tokens"] == 440

    by_agent = {(r["agent_id"], r["kind"]): r for r in udb.query_all("SELECT * FROM usage_by_agent")}
    default, b = by_agent[("default", "llm")], by_agent[("b", "llm")]
    # m1's two calls before the move stay on 'default' (plus all of m2); calls after belong to 'b'
    assert (default["calls"], default["total_tokens"]) == (3, 770)
    assert default["cost_usd"] == pytest.approx(0.07)
    assert (b["calls"], b["total_tokens"]) == (2, 1155)
    assert b["cost_usd"] == pytest.approx(0.10)
    purposes = {r["purpose"]: r["n"] for r in udb.query_all(
        "SELECT purpose, COUNT(*) AS n FROM ai_usage WHERE kind = 'llm' GROUP BY purpose")}
    assert purposes == {"chat": 3, "memory": 1, "title": 1}
