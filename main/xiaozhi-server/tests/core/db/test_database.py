import sqlite3
import threading

import pytest

from core.db.database import Database, resolve_db_path

TABLES = {
    "setting", "model_config", "agent", "replacement_word", "memory", "device",
    "chat_session", "chat_message", "chat_audio", "guardrail_name", "ai_usage",
}


def _names(db, kind):
    rows = db.query_all("SELECT name FROM sqlite_master WHERE type = ?", (kind,))
    return {r["name"] for r in rows}


def test_schema_has_all_tables_views_indexes(db):
    assert TABLES <= _names(db, "table")
    assert {"usage_by_device", "usage_by_agent"} <= _names(db, "view")
    assert {"idx_msg_session", "idx_usage_time", "idx_usage_device", "idx_usage_agent",
            "idx_replacement_unique"} <= _names(db, "index")
    assert db.query_one("PRAGMA user_version")[0] == 1


def test_schema_applies_twice(tmp_path):
    path = str(tmp_path / "twice.db")
    Database(path).close()
    db = Database(path)  # second open applies the schema again
    try:
        assert TABLES <= _names(db, "table")
        assert db.query_one("PRAGMA user_version")[0] == 1
    finally:
        db.close()


def test_pragmas(db):
    assert db.query_one("PRAGMA journal_mode")[0] == "wal"
    assert db.query_one("PRAGMA foreign_keys")[0] == 1
    assert db.query_one("PRAGMA busy_timeout")[0] == 5000


def test_resolve_path_env_and_default(monkeypatch, tmp_path):
    monkeypatch.setenv("XIAOZHI_DB", str(tmp_path / "env.db"))
    assert resolve_db_path() == str(tmp_path / "env.db")
    assert resolve_db_path(str(tmp_path / "arg.db")) == str(tmp_path / "arg.db")
    monkeypatch.delenv("XIAOZHI_DB")
    assert resolve_db_path().replace("\\", "/").endswith("xiaozhi-server/data/xiaozhi.db")


def test_write_then_read_through_writer_thread(db):
    names = []
    fut = db.submit(lambda conn: names.append(threading.current_thread().name))
    fut.result(5)
    assert names == ["xiaozhi-db-writer"]
    assert db.write_sync("INSERT INTO setting(key, value) VALUES (?, ?)", ("a", "1"))
    assert db.query_one("SELECT value FROM setting WHERE key = 'a'")["value"] == "1"


def test_reads_use_one_connection_per_thread(db):
    main_conn = db._reader()
    seen = []
    t = threading.Thread(target=lambda: seen.append(db._reader()))
    t.start()
    t.join()
    assert seen[0] is not main_conn
    assert db._reader() is main_conn


def test_readers_cannot_write(db):
    with pytest.raises(sqlite3.OperationalError):
        db.query_all("INSERT INTO setting(key, value) VALUES ('x', '1')")


def test_failing_write_is_logged_not_raised(db):
    # NULL violates NOT NULL; the writer must survive and keep serving later writes
    fut = db.write("INSERT INTO setting(key, value) VALUES (?, ?)", ("k", None))
    assert db.wait(fut) is False
    assert db.write_sync("INSERT INTO setting(key, value) VALUES ('ok', '2')") is True
    assert db.query_one("SELECT value FROM setting WHERE key = 'ok'")["value"] == "2"
    assert db.query_one("SELECT 1 FROM setting WHERE key = 'k'") is None


def test_failing_write_message_is_logged(db, monkeypatch):
    logged = []
    monkeypatch.setattr("core.db.database._log", lambda level, msg: logged.append((level, msg)))
    db.wait(db.write("INSERT INTO nope VALUES (1)"))
    assert any(level == "error" and "Database write failed" in msg for level, msg in logged)


def test_failed_write_rolls_back_whole_transaction(db):
    def fn(conn):
        conn.execute("INSERT INTO setting(key, value) VALUES ('half', '1')")
        conn.execute("INSERT INTO setting(key, value) VALUES (NULL, NULL)")

    assert db.wait(db.submit(fn)) is False
    assert db.query_one("SELECT 1 FROM setting WHERE key = 'half'") is None


def test_foreign_keys_enforced_on_writer(db):
    assert not db.write_sync("INSERT INTO device(mac, agent_id) VALUES ('m', 'no-such-agent')")


def test_many_writes_keep_order_and_flush(db):
    for i in range(200):
        db.write("INSERT INTO setting(key, value) VALUES (?, ?)", (f"k{i:03d}", str(i)))
    assert db.flush()
    assert db.query_one("SELECT COUNT(*) FROM setting")[0] == 200


def test_insert_returns_lastrowid(db):
    rowid = db.insert("INSERT INTO chat_audio(format, sample_rate, data) VALUES ('opus-frames', 24000, ?)",
                      (b"\x00\x01",)).result(5)
    assert rowid == 1


def test_async_helpers(db):
    import asyncio

    async def go():
        assert await db.awrite("INSERT INTO setting(key, value) VALUES ('x', '1')")
        row = await db.aquery_one("SELECT value FROM setting WHERE key = 'x'")
        assert row["value"] == "1"
        assert len(await db.aquery_all("SELECT * FROM setting")) == 1

    asyncio.run(go())


def test_close_is_clean_and_write_after_close_does_not_raise(tmp_path):
    db = Database(str(tmp_path / "c.db"))
    db.write_sync("INSERT INTO setting(key, value) VALUES ('a', '1')")
    writer = db._writer
    db.close()
    assert writer is not None and not writer.is_alive()
    assert db.write_sync("INSERT INTO setting(key, value) VALUES ('b', '1')") is False
    db.close()  # idempotent
    with sqlite3.connect(db.path) as conn:
        assert conn.execute("SELECT COUNT(*) FROM setting").fetchone()[0] == 1
