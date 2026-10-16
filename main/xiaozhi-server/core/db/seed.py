"""Seed an (empty) database with defaults derived from config.yaml.

Usage (from main/xiaozhi-server):
    python -m core.db.seed                 # data/xiaozhi.db, or env XIAOZHI_DB
    python -m core.db.seed --db PATH

Idempotent: every insert is INSERT OR IGNORE (or guarded), so running it again changes nothing
and never overwrites values you edited by hand.
Only the standard library and yaml are used, so it runs without the server dependencies.
"""

import argparse
import json
import sqlite3
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import yaml

from core.db.database import PROJECT_DIR, Database, resolve_db_path

DEFAULT_AGENT_ID = "default"

# Settings that must exist even if config.yaml does not define them: (key, value, note)
_FIXED_SETTINGS: List[Tuple[str, Any, str]] = [
    ("server.timezone_offset", 7, "Hours from UTC, reported to the device by the OTA endpoint"),
    ("server.auth.enabled", False, "WebSocket token auth (trusted LAN: off)"),
    ("server.auth.allowed_devices", [], "Device ids that skip token auth"),
    ("device_max_output_size", 0, "Max characters spoken per device per day; 0 = unlimited"),
    ("tools.server_plugins_enabled", False, "Master switch for plugins_func/functions; off = no plugin tool reaches the LLM"),
    ("device.auto_register", True, "Unknown device ids are added to the default agent; false = refuse them"),
    ("guardrails.enabled", True, "Master switch for masking personal data in user text"),
    ("guardrails.mask_email", True, None),
    ("guardrails.mask_phone", True, None),
    ("guardrails.mask_card", True, None),
    ("guardrails.mask_name", True, "Uses the guardrail_name table"),
    ("guardrails.restore_in_reply", False, "Put real values back into the reply before TTS"),
]

# Settings copied from config.yaml (dotted key -> path in the yaml). A missing yaml key is skipped.
_YAML_SETTINGS: List[Tuple[str, Tuple[str, ...]]] = [
    ("server.websocket", ("server", "websocket")),
    ("delete_audio", ("delete_audio",)),
    ("close_connection_no_voice_time", ("close_connection_no_voice_time",)),
    ("tts_timeout", ("tts_timeout",)),
    ("tool_call_timeout", ("tool_call_timeout",)),
    ("enable_wakeup_words_response_cache", ("enable_wakeup_words_response_cache",)),
    ("enable_greeting", ("enable_greeting",)),
    ("enable_stop_tts_notify", ("enable_stop_tts_notify",)),
    ("stop_tts_notify_voice", ("stop_tts_notify_voice",)),
    ("enable_websocket_ping", ("enable_websocket_ping",)),
    ("tts_audio_send_delay", ("tts_audio_send_delay",)),
    ("exit_commands", ("exit_commands",)),
    ("wakeup_words", ("wakeup_words",)),
    ("xiaozhi", ("xiaozhi",)),
    ("module_test", ("module_test",)),
    ("prompt_template", ("prompt_template",)),
    ("system_error_response", ("system_error_response",)),
    ("end_prompt.enable", ("end_prompt", "enable")),
    ("end_prompt.prompt", ("end_prompt", "prompt")),
]

# Plugin parameter blocks (config.yaml `plugins:`). search_from_ragflow is skipped: RAGFlow is dropped.
_PLUGIN_SKIP = {"search_from_ragflow"}


def _dig(data: Dict[str, Any], path: Tuple[str, ...]):
    cur: Any = data
    for part in path:
        if not isinstance(cur, dict) or part not in cur:
            return None, False
        cur = cur[part]
    return cur, True


def _load_yaml_defaults(path: Optional[Path] = None) -> Dict[str, Any]:
    path = path or PROJECT_DIR / "config.yaml"
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def _setting_rows(cfg: Dict[str, Any]) -> List[Tuple[str, str, Optional[str]]]:
    rows: List[Tuple[str, Any, Optional[str]]] = []
    for key, path in _YAML_SETTINGS:
        value, found = _dig(cfg, path)
        if found and value is not None:
            rows.append((key, value, None))
    for name, params in (cfg.get("plugins") or {}).items():
        if name not in _PLUGIN_SKIP:
            rows.append((f"plugins.{name}", params, "Plugin parameters; only used when tools.server_plugins_enabled is true"))
    rows.extend(_FIXED_SETTINGS)
    return [(k, json.dumps(v, ensure_ascii=False), n) for k, v, n in rows]


def _model_rows(cfg: Dict[str, Any]) -> List[Tuple[str, str, str, str, Dict[str, Any], int]]:
    """(id, model_type, model_code, name, config, enabled)"""
    vad = dict((cfg.get("VAD") or {}).get("SileroVAD") or {"type": "silero"})
    asr = dict((cfg.get("ASR") or {}).get("FunASR") or {"type": "fun_local"})
    tts = dict((cfg.get("TTS") or {}).get("EdgeTTS") or {"type": "edge"})
    return [
        ("VAD_SileroVAD", "VAD", "SileroVAD", "SileroVAD", vad, 1),
        # FunASR is the working ASR until the OpenRouter STT provider exists (phase 4)
        ("ASR_FunASR", "ASR", "FunASR", "FunASR", asr, 1),
        (
            "ASR_OpenRouter", "ASR", "openrouter_stt", "OpenRouter STT",
            {
                "type": "openrouter_stt",
                "api_key": "",
                "model_name": "openai/whisper-large-v3",
                "language": "",
                "audio_format": "pcm",
                "timeout_ms": 15000,
                "output_dir": "tmp/",
            },
            0,  # disabled until phase 4 implements the provider
        ),
        (
            "LLM_OpenRouter", "LLM", "openrouter", "OpenRouter",
            {
                "type": "openrouter",
                "model_name": "openai/gpt-4o-mini",
                "api_key": "",
                "base_url": "https://openrouter.ai/api/v1",
                "timeout": 30,
            },
            1,
        ),
        ("TTS_EdgeTTS", "TTS", "EdgeTTS", "EdgeTTS", tts, 1),
        (
            "Memory_mem_local_short", "Memory", "mem_local_short", "Local short memory",
            {"type": "mem_local_short", "llm": "LLM_OpenRouter"},
            1,
        ),
        ("Memory_nomem", "Memory", "nomem", "No memory", {"type": "nomem"}, 1),
        (
            "Intent_function_call", "Intent", "function_call", "Function call",
            {"type": "function_call", "functions": []},
            1,
        ),
    ]


def seed_database(conn: sqlite3.Connection, yaml_path: Optional[Path] = None) -> Dict[str, int]:
    """Insert the default rows. Returns the number of rows added per table (0 on a second run)."""
    cfg = _load_yaml_defaults(yaml_path)
    added = {"setting": 0, "model_config": 0, "agent": 0}

    def count(cur: sqlite3.Cursor) -> int:
        return max(cur.rowcount, 0)

    with conn:  # one transaction
        for key, value, note in _setting_rows(cfg):
            added["setting"] += count(conn.execute(
                "INSERT OR IGNORE INTO setting(key, value, note) VALUES (?, ?, ?)", (key, value, note)
            ))
        for mid, mtype, code, name, mcfg, enabled in _model_rows(cfg):
            added["model_config"] += count(conn.execute(
                "INSERT OR IGNORE INTO model_config(id, model_type, model_code, name, config_json, enabled) "
                "VALUES (?, ?, ?, ?, ?, ?)",
                (mid, mtype, code, name, json.dumps(mcfg, ensure_ascii=False), enabled),
            ))
        # Only create the default agent when no agent is marked as default yet
        has_default = conn.execute("SELECT 1 FROM agent WHERE is_default = 1").fetchone()
        if not has_default:
            added["agent"] += count(conn.execute(
                "INSERT OR IGNORE INTO agent(id, name, is_default, system_prompt, vad_id, asr_id, llm_id, tts_id, "
                "mem_id, intent_id, history_mode) VALUES (?, ?, 1, ?, ?, ?, ?, ?, ?, ?, 2)",
                (
                    DEFAULT_AGENT_ID, "Default agent", cfg.get("prompt"),
                    "VAD_SileroVAD", "ASR_FunASR", "LLM_OpenRouter", "TTS_EdgeTTS",
                    "Memory_mem_local_short", "Intent_function_call",
                ),
            ))
    return added


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Create and seed the xiaozhi SQLite database")
    parser.add_argument("--db", help="database file (default: env XIAOZHI_DB, then data/xiaozhi.db)")
    args = parser.parse_args(argv)

    db = Database(args.db)  # creates the file and applies the schema
    try:
        conn = sqlite3.connect(db.path)
        try:
            conn.execute("PRAGMA foreign_keys = ON")
            added = seed_database(conn)
        finally:
            conn.close()
    finally:
        db.close()
    print(f"Database: {resolve_db_path(args.db)}")
    print("Rows added: " + ", ".join(f"{t}={n}" for t, n in added.items()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
