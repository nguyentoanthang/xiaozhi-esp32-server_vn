"""usage_by_device / usage_by_agent over a scripted scenario with an agent change midway."""
import pytest


def _usage(db, rid, mac, agent, tokens, cost, day="2026-03-10", kind="llm"):
    assert db.write_sync(
        "INSERT INTO ai_usage(record_id, created_at, kind, device_mac, agent_id, purpose, "
        "prompt_tokens, completion_tokens, total_tokens, cost) VALUES (?, ?, ?, ?, ?, 'chat', ?, ?, ?, ?)",
        (rid, f"{day}T12:00:00Z", kind, mac, agent, tokens, tokens // 2, tokens + tokens // 2, cost),
    )


@pytest.fixture
def scenario(seeded_db):
    db = seeded_db
    db.write_sync("INSERT INTO agent(id, name) VALUES ('b', 'Agent B')")
    for mac in ("m1", "m2"):
        db.write_sync("INSERT INTO device(mac, agent_id) VALUES (?, 'default')", (mac,))
    _usage(db, "r1", "m1", "default", 100, 0.01)
    _usage(db, "r2", "m1", "default", 200, 0.02)
    _usage(db, "r3", "m2", "default", 400, 0.04)
    # m1 is moved to agent b; rows copy agent_id at call time so history is not rewritten
    db.write_sync("UPDATE device SET agent_id = 'b' WHERE mac = 'm1'")
    _usage(db, "r4", "m1", "b", 1000, 0.10)
    _usage(db, "r5", "m1", "b", 2000, 0.20)
    _usage(db, "r6", "m1", "b", 50, None, kind="stt")  # unknown cost stays NULL
    _usage(db, "r7", "m2", "default", 10, 0.001, day="2026-03-11")
    return db


def _by(rows, *keys):
    return {tuple(r[k] for k in keys): r for r in rows}


def test_usage_by_device(scenario):
    rows = _by(scenario.query_all("SELECT * FROM usage_by_device"), "device_mac", "kind", "day")
    m1 = rows[("m1", "llm", "2026-03-10")]
    assert (m1["calls"], m1["prompt_tokens"], m1["total_tokens"]) == (4, 3300, 4950)
    assert m1["cost_usd"] == pytest.approx(0.33)
    assert rows[("m1", "stt", "2026-03-10")]["cost_usd"] is None
    assert rows[("m2", "llm", "2026-03-10")]["calls"] == 1
    assert rows[("m2", "llm", "2026-03-11")]["prompt_tokens"] == 10


def test_usage_by_agent_survives_agent_change(scenario):
    rows = _by(scenario.query_all("SELECT * FROM usage_by_agent"), "agent_id", "kind", "day")
    default = rows[("default", "llm", "2026-03-10")]
    b = rows[("b", "llm", "2026-03-10")]
    # m1's two calls before the move stay with 'default'; calls after belong to 'b'
    assert (default["calls"], default["prompt_tokens"]) == (3, 700)
    assert default["cost_usd"] == pytest.approx(0.07)
    assert (b["calls"], b["prompt_tokens"]) == (2, 3000)
    assert b["cost_usd"] == pytest.approx(0.30)
    assert rows[("default", "llm", "2026-03-11")]["calls"] == 1


def test_record_id_is_unique(scenario):
    assert not scenario.write_sync(
        "INSERT INTO ai_usage(record_id, created_at) VALUES ('r1', '2026-03-10T00:00:00Z')")
