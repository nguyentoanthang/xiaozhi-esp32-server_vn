"""Automatic seeding at first start (ensure_seeded) and the config loader path that uses it."""
import asyncio
import os
import sqlite3

import pytest

from core.db import Database, NoDefaultAgent, build_base_config, close_database, set_database
from core.db.seed import ensure_seeded, main as seed_main


def _count(db, table):
    return db.query_one(f"SELECT COUNT(*) AS n FROM {table}")["n"]


def test_fresh_database_is_seeded(db):
    assert _count(db, "agent") == 0
    assert ensure_seeded(db) is True
    assert _count(db, "agent") == 1
    assert db.query_one("SELECT id FROM agent WHERE is_default = 1")["id"] == "default"
    assert _count(db, "setting") > 0 and _count(db, "model_config") > 0
    # The startup config can be built right away
    assert build_base_config(db)["selected_module"]["LLM"] == "LLM_OpenRouter"


def test_missing_file_is_created_and_seeded(tmp_path):
    path = tmp_path / "sub" / "new.db"
    assert not path.exists()
    database = Database(str(path))  # creates the file and the tables
    try:
        assert path.exists()
        assert ensure_seeded(database) is True
        assert _count(database, "agent") == 1
    finally:
        database.close()


def test_existing_database_is_not_seeded_again(seeded_db):
    assert ensure_seeded(seeded_db) is False


def test_deleted_rows_are_not_resurrected(seeded_db):
    db = seeded_db
    assert db.write_sync("DELETE FROM setting WHERE key = 'guardrails.mask_card'")
    assert db.write_sync("DELETE FROM model_config WHERE id = 'ASR_OpenRouter'")
    assert db.write_sync("UPDATE agent SET name = 'My agent' WHERE id = 'default'")

    assert ensure_seeded(db) is False

    assert db.query_one("SELECT 1 FROM setting WHERE key = 'guardrails.mask_card'") is None
    assert db.query_one("SELECT 1 FROM model_config WHERE id = 'ASR_OpenRouter'") is None
    assert db.query_one("SELECT name FROM agent WHERE id = 'default'")["name"] == "My agent"


def test_a_second_default_agent_is_enough_to_skip(db):
    db.write_sync("INSERT INTO agent(id, name, is_default) VALUES ('mine', 'Mine', 1)")
    assert ensure_seeded(db) is False
    assert _count(db, "agent") == 1


def test_seeding_failure_is_not_raised_and_leaves_no_default_agent(db, monkeypatch):
    import core.db.seed as seed_module

    def boom(conn, yaml_path=None):
        raise RuntimeError("disk full")

    monkeypatch.setattr(seed_module, "seed_database", boom)
    assert ensure_seeded(db) is False
    with pytest.raises(NoDefaultAgent):
        build_base_config(db)


def test_cli_seed_still_works_and_is_idempotent(tmp_path, capsys):
    path = str(tmp_path / "cli.db")
    assert seed_main(["--db", path]) == 0
    assert "agent=1" in capsys.readouterr().out
    assert seed_main(["--db", path]) == 0
    assert "agent=0" in capsys.readouterr().out
    conn = sqlite3.connect(path)
    try:
        assert conn.execute("SELECT COUNT(*) FROM agent").fetchone()[0] == 1
    finally:
        conn.close()


def test_config_loader_seeds_an_empty_database_on_first_start(tmp_path):
    from config.config_loader import load_config_from_db

    path = str(tmp_path / "first.db")
    bootstrap = {"db": {"path": path}, "server": {"port": 8000}, "log": {}}
    set_database(None)
    try:
        config = asyncio.run(load_config_from_db(bootstrap))
        assert config["selected_module"]["VAD"] == "VAD_SileroVAD"
        assert config["default_agent_id"] == "default"
        assert config["db_enabled"] is True
    finally:
        close_database()
    assert os.path.exists(path)
