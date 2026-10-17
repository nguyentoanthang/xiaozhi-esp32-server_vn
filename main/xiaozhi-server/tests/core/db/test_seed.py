import json
import os
import sqlite3
import subprocess
import sys
from pathlib import Path

from core.db.seed import seed_database

SERVER_DIR = Path(__file__).resolve().parents[3]


def _dump(path):
    conn = sqlite3.connect(path)
    try:
        return {
            t: conn.execute(f"SELECT * FROM {t} ORDER BY 1").fetchall()
            for t in ("setting", "model_config", "agent", "device", "replacement_word")
        }
    finally:
        conn.close()


def test_seed_is_idempotent(db):
    conn = sqlite3.connect(db.path)
    first = seed_database(conn)
    before = _dump(db.path)
    second = seed_database(conn)
    conn.close()
    assert first["setting"] > 20 and first["model_config"] == 8 and first["agent"] == 1
    assert second == {"setting": 0, "model_config": 0, "agent": 0}
    assert _dump(db.path) == before


def test_seed_does_not_overwrite_hand_edits(seeded_db):
    db = seeded_db
    db.write_sync("UPDATE setting SET value = '99' WHERE key = 'tts_timeout'")
    db.write_sync("UPDATE agent SET is_default = 0 WHERE id = 'default'")
    db.write_sync("INSERT INTO agent(id, name, is_default) VALUES ('mine', 'Mine', 1)")
    conn = sqlite3.connect(db.path)
    assert seed_database(conn)["agent"] == 0  # a default agent already exists
    conn.close()
    assert db.query_one("SELECT value FROM setting WHERE key = 'tts_timeout'")["value"] == "99"


def test_seed_content(seeded_db):
    db = seeded_db
    models = {r["id"]: r for r in db.query_all("SELECT * FROM model_config")}
    assert set(models) == {
        "VAD_SileroVAD", "ASR_FunASR", "ASR_OpenRouter", "LLM_OpenRouter", "TTS_EdgeTTS",
        "Memory_mem_local_short", "Memory_nomem", "Intent_function_call",
    }
    assert models["ASR_FunASR"]["enabled"] == 0  # kept for A/B comparison
    assert models["ASR_OpenRouter"]["enabled"] == 1
    assert json.loads(models["ASR_OpenRouter"]["config_json"])["type"] == "openrouter_stt"
    llm = json.loads(models["LLM_OpenRouter"]["config_json"])
    assert llm["type"] == "openrouter" and llm["api_key"] == ""
    assert json.loads(models["Memory_mem_local_short"]["config_json"])["llm"] == "LLM_OpenRouter"
    assert json.loads(models["Intent_function_call"]["config_json"])["functions"] == []
    agent = db.query_one("SELECT * FROM agent WHERE is_default = 1")
    assert (agent["asr_id"], agent["llm_id"], agent["mem_id"], agent["intent_id"], agent["history_mode"]) == (
        "ASR_OpenRouter", "LLM_OpenRouter", "Memory_mem_local_short", "Intent_function_call", 2)


def test_seed_has_no_secrets_and_no_log_block(seeded_db):
    db = seeded_db
    keys = {r["key"] for r in db.query_all("SELECT key FROM setting")}
    assert not any(k == "log" or k.startswith("log.") for k in keys)
    for row in db.query_all("SELECT value FROM setting WHERE key LIKE 'plugins.%'"):
        for k, v in json.loads(row["value"]).items():
            if k == "api_key":
                assert v == "" or v.startswith("your_") or v.endswith("xxx")
    dumped = json.dumps([tuple(r) for r in db.query_all("SELECT config_json FROM model_config")])
    assert "sk-" not in dumped


def test_seed_cli_twice(tmp_path):
    path = tmp_path / "cli.db"
    for _ in range(2):
        r = subprocess.run(
            [sys.executable, "-m", "core.db.seed", "--db", str(path)],
            cwd=SERVER_DIR, capture_output=True, text=True,
        )
        assert r.returncode == 0, r.stderr
    assert "setting=0, model_config=0, agent=0" in r.stdout
    conn = sqlite3.connect(path)
    assert conn.execute("SELECT COUNT(*) FROM model_config").fetchone()[0] == 8
    conn.close()


def test_seed_cli_env_var(tmp_path):
    path = tmp_path / "env.db"
    r = subprocess.run(
        [sys.executable, "-m", "core.db.seed"], cwd=SERVER_DIR, capture_output=True, text=True,
        env={**os.environ, "XIAOZHI_DB": str(path)},
    )
    assert r.returncode == 0, r.stderr
    assert path.exists()
