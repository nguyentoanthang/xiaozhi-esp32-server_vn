"""OpenRouter secrets are loaded locally and never persisted with model settings."""
import asyncio

import pytest

from config import config_loader


@pytest.fixture
def local_env(tmp_path, monkeypatch):
    monkeypatch.setattr(config_loader, "get_project_dir", lambda: str(tmp_path) + "/")
    monkeypatch.delenv("OPENROUTER_API_KEY", raising=False)
    return tmp_path / ".env"


@pytest.mark.parametrize("override, expected", [(None, "file-key"), ("env-key", "env-key"), ("", "")])
def test_key_source_precedence(local_env, monkeypatch, override, expected):
    local_env.write_text('OPENROUTER_API_KEY="file-key"\n', encoding="utf-8-sig")
    if override is not None:
        monkeypatch.setenv("OPENROUTER_API_KEY", override)
    # The file must be resolved relative to the server, not the current directory.
    elsewhere = local_env.parent / "elsewhere"
    elsewhere.mkdir()
    monkeypatch.chdir(elsewhere)
    cfg = {"LLM": {"chat": {"type": "openrouter", "api_key": "old-db-key"},
                   "other": {"type": "openai", "api_key": "other-key"}},
           "ASR": {"speech": {"type": "openrouter_stt"}}}
    config_loader.apply_provider_secrets(cfg)
    assert cfg["LLM"]["chat"]["api_key"] == expected
    assert cfg["ASR"]["speech"]["api_key"] == expected
    assert cfg["LLM"]["other"]["api_key"] == "other-key"


@pytest.mark.parametrize("contents", [None, "OPENROUTER_API_KEY=\n"])
def test_missing_or_empty_key_does_not_use_database_secret(local_env, contents):
    if contents is not None:
        local_env.write_text(contents, encoding="utf-8")
    cfg = {"LLM": {"chat": {"type": "openrouter", "api_key": "old-db-key"}}}
    config_loader.apply_provider_secrets(cfg)
    assert cfg["LLM"]["chat"]["api_key"] == ""


def test_startup_and_device_configs_get_key_without_changing_database(local_env, seeded_db, monkeypatch):
    import core.db

    local_env.write_text("OPENROUTER_API_KEY=test-only-key\n", encoding="utf-8")
    monkeypatch.setattr(core.db, "get_database", lambda *args: seeded_db)
    before = [dict(row) for row in seeded_db.query_all("SELECT * FROM model_config ORDER BY id")]
    bootstrap = {"server": {}, "log": {}, "db": {"path": seeded_db.path}}
    base = asyncio.run(config_loader.load_config_from_db(bootstrap))
    device = asyncio.run(config_loader.get_private_config(base, "aa:bb:cc:dd:ee:09"))
    for cfg in (base, device):
        assert cfg["LLM"]["LLM_OpenRouter"]["api_key"] == "test-only-key"
        assert cfg["ASR"]["ASR_OpenRouter"]["api_key"] == "test-only-key"
        assert cfg["LLM"]["LLM_OpenRouter"]["model_name"] == "openai/gpt-4o-mini"
    after = [dict(row) for row in seeded_db.query_all("SELECT * FROM model_config ORDER BY id")]
    assert after == before
