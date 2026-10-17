import asyncio
import json

import pytest

from core.db.config_assembly import (
    DeviceRefused,
    build_agent_config,
    build_base_config,
    build_global_config,
    get_agent_config,
    touch_device,
)

MAC = "aa:bb:cc:dd:ee:01"

# Every key of the design's "Config key inventory" table
TOP_LEVEL_KEYS = {
    "selected_module", "VAD", "ASR", "LLM", "TTS", "Memory", "Intent",
    "correct_words", "prompt", "summaryMemory", "plugins", "mcp_endpoint", "context_providers",
    "chat_history_conf", "device_max_output_size", "delete_audio", "tts_timeout",
}
TTS_EXTRAS = {"private_voice", "language", "volume", "rate", "pitch"}


def test_global_config_nested_shape(seeded_db):
    g = build_global_config(seeded_db)
    assert g["server"]["timezone_offset"] == 7
    assert g["server"]["auth"] == {"enabled": False, "allowed_devices": []}
    assert g["exit_commands"] == ["exit", "quit", "goodbye"]
    assert g["xiaozhi"]["audio_params"]["sample_rate"] == 24000
    assert g["xiaozhi"]["type"] == "hello"
    assert isinstance(g["end_prompt"]["enable"], bool) and g["end_prompt"]["prompt"]
    assert g["tools"] == {"server_plugins_enabled": False}
    assert g["device"] == {"auto_register": True}
    assert g["guardrails"]["enabled"] is True and g["guardrails"]["restore_in_reply"] is False
    assert g["plugins"]["get_weather"]["api_key"].startswith("your_")
    assert g["prompt_template"] == "agent-base-prompt.txt"
    assert {"close_connection_no_voice_time", "tts_timeout", "tool_call_timeout", "wakeup_words",
            "delete_audio", "enable_greeting", "device_max_output_size"} <= set(g)
    assert "log" not in g


def test_dotted_parent_and_child_keys_merge(db):
    db.write_sync("INSERT INTO setting(key, value) VALUES ('a', ?)", (json.dumps({"x": 1, "y": 2}),))
    db.write_sync("INSERT INTO setting(key, value) VALUES ('a.y', '3')")
    db.write_sync("INSERT INTO setting(key, value) VALUES ('a.z.w', '\"v\"')")
    assert build_global_config(db)["a"] == {"x": 1, "y": 3, "z": {"w": "v"}}


def test_agent_config_has_every_inventory_key(seeded_db):
    db = seeded_db
    db.write_sync(
        "UPDATE agent SET tts_voice = 'vi-VN-HoaiMyNeural', "
        "tts_params_json = ?, plugins_json = ?, mcp_endpoint = 'wss://mcp.example/mcp/x', "
        "context_providers_json = ? WHERE id = 'default'",
        (
            json.dumps({"language": "vi", "volume": 60, "rate": 5, "pitch": -5}),
            json.dumps({"get_weather": {"description": "w"}}),
            json.dumps([{"url": "http://ctx", "headers": {}}]),
        ),
    )
    db.write_sync("INSERT INTO replacement_word(agent_id, source, target) VALUES (NULL, 'AI', 'ay ai')")
    cfg = build_agent_config(db, MAC)  # auto-registers
    assert TOP_LEVEL_KEYS <= set(cfg)
    assert cfg["selected_module"] == {
        "VAD": "VAD_SileroVAD", "ASR": "ASR_OpenRouter", "LLM": "LLM_OpenRouter", "TTS": "TTS_EdgeTTS",
        "Memory": "Memory_mem_local_short", "Intent": "Intent_function_call",
    }
    for mtype in ("VAD", "ASR", "LLM", "TTS", "Memory", "Intent"):
        sel = cfg["selected_module"][mtype]
        assert sel in cfg[mtype] and "type" in cfg[mtype][sel]
    assert TTS_EXTRAS <= set(cfg["TTS"]["TTS_EdgeTTS"])
    assert cfg["TTS"]["TTS_EdgeTTS"]["private_voice"] == "vi-VN-HoaiMyNeural"
    assert cfg["correct_words"] == ["AI|ay ai"]
    assert cfg["prompt"] and cfg["summaryMemory"] is None
    assert cfg["plugins"] == {"get_weather": {"description": "w"}}
    assert cfg["mcp_endpoint"] == "wss://mcp.example/mcp/x"
    assert cfg["context_providers"][0]["url"] == "http://ctx"
    assert cfg["chat_history_conf"] == 2
    assert cfg["device_max_output_size"] == 0
    assert cfg["delete_audio"] is True and cfg["tts_timeout"] == 15
    assert "VLLM" not in cfg and "voiceprint" not in cfg


def test_memory_llm_row_is_included(seeded_db):
    cfg = build_agent_config(seeded_db, MAC)
    assert cfg["Memory"]["Memory_mem_local_short"]["llm"] == "LLM_OpenRouter"
    assert "LLM_OpenRouter" in cfg["LLM"]
    # With a different main LLM the memory LLM is still present next to it
    seeded_db.write_sync(
        "INSERT INTO model_config(id, model_type, model_code, name, config_json) "
        "VALUES ('LLM_Other', 'LLM', 'openai', 'Other', ?)", (json.dumps({"type": "openai"}),))
    seeded_db.write_sync("UPDATE agent SET llm_id = 'LLM_Other' WHERE id = 'default'")
    cfg = build_agent_config(seeded_db, MAC)
    assert set(cfg["LLM"]) == {"LLM_Other", "LLM_OpenRouter"}
    assert cfg["selected_module"]["LLM"] == "LLM_Other"


def test_summary_memory_comes_from_memory_table_per_mac(seeded_db):
    db = seeded_db
    build_agent_config(db, MAC)
    db.write_sync("INSERT INTO memory(device_mac, summary, updated_at) VALUES (?, 'likes tea', 't')", (MAC,))
    assert build_agent_config(db, MAC)["summaryMemory"] == "likes tea"
    assert build_agent_config(db, "aa:bb:cc:dd:ee:02")["summaryMemory"] is None


def test_disabled_model_is_not_selected(seeded_db):
    db = seeded_db
    db.write_sync("UPDATE agent SET asr_id = 'ASR_FunASR' WHERE id = 'default'")
    cfg = build_agent_config(db, MAC)
    assert "ASR" not in cfg["selected_module"] and "ASR" not in cfg
    db.write_sync("UPDATE model_config SET enabled = 1 WHERE id = 'ASR_FunASR'")
    assert build_agent_config(db, MAC)["selected_module"]["ASR"] == "ASR_FunASR"


def test_base_config_is_global_plus_default_agent(seeded_db):
    cfg = build_base_config(seeded_db)
    assert cfg["server"]["timezone_offset"] == 7
    assert cfg["selected_module"]["LLM"] == "LLM_OpenRouter"
    assert cfg["ASR"]["ASR_OpenRouter"]["type"] == "openrouter_stt"
    assert cfg["prompt"]


def test_auto_register_on_creates_device_on_default_agent(seeded_db):
    db = seeded_db
    cfg = build_agent_config(db, MAC.upper())  # MAC is normalised
    assert cfg["agent_id"] == "default"
    row = db.query_one("SELECT agent_id, last_connected_at FROM device WHERE mac = ?", (MAC,))
    assert row["agent_id"] == "default" and row["last_connected_at"]
    build_agent_config(db, MAC)  # second call: no duplicate
    assert db.query_one("SELECT COUNT(*) FROM device")[0] == 1


def test_auto_register_off_refuses_unknown_device(seeded_db):
    db = seeded_db
    db.write_sync("UPDATE setting SET value = 'false' WHERE key = 'device.auto_register'")
    with pytest.raises(DeviceRefused) as exc:
        build_agent_config(db, MAC)
    assert exc.value.mac == MAC
    assert db.query_one("SELECT COUNT(*) FROM device")[0] == 0
    # A known device still connects
    db.write_sync("INSERT INTO device(mac, agent_id) VALUES (?, 'default')", (MAC,))
    assert build_agent_config(db, MAC)["agent_id"] == "default"


def test_missing_device_id_is_refused(seeded_db):
    with pytest.raises(DeviceRefused):
        build_agent_config(seeded_db, None)


def test_get_agent_config_async_and_touch(seeded_db):
    cfg = asyncio.run(get_agent_config(seeded_db, MAC))
    assert TOP_LEVEL_KEYS <= set(cfg)
    seeded_db.write_sync("UPDATE device SET last_connected_at = 'old' WHERE mac = ?", (MAC,))
    touch_device(seeded_db, MAC)
    seeded_db.flush()
    assert seeded_db.query_one("SELECT last_connected_at FROM device WHERE mac = ?", (MAC,))[0] != "old"


def test_replacement_words_global_and_agent_override(seeded_db):
    db = seeded_db
    db.write_sync("INSERT INTO replacement_word(agent_id, source, target) VALUES (NULL, 'AI', 'a-i')")
    db.write_sync("INSERT INTO replacement_word(agent_id, source, target) VALUES (NULL, 'GPT', 'gee pee tee')")
    assert sorted(build_agent_config(db, MAC)["correct_words"]) == ["AI|a-i", "GPT|gee pee tee"]
    # a per-agent row with the same source wins; a duplicate (agent, source) pair is rejected
    db.write_sync("INSERT INTO replacement_word(agent_id, source, target) VALUES ('default', 'AI', 'ay eye')")
    assert not db.write_sync("INSERT INTO replacement_word(agent_id, source, target) VALUES (NULL, 'AI', 'dup')")
    assert sorted(build_agent_config(db, MAC)["correct_words"]) == ["AI|ay eye", "GPT|gee pee tee"]
