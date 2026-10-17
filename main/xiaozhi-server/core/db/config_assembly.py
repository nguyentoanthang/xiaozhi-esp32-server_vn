"""Build the server config dicts from the database.

- build_global_config(db): `setting` rows (dotted keys, JSON values) -> nested dict.
- build_base_config(db): global config plus the default agent's models; this is what the shared
  VAD/ASR/LLM/Memory/Intent instances are created from at startup.
- build_agent_config(db, mac) / get_agent_config(db, mac): the per-device dict that
  ConnectionHandler used to get from the Java API (same keys, see the design's "Config key inventory").

Only the standard library is imported here.
"""

import asyncio
import copy
import json
import sqlite3
from typing import Any, Dict, List, Optional

from core.db.database import Database, _log, utcnow_iso

MODEL_TYPES = ("VAD", "ASR", "LLM", "TTS", "Memory", "Intent")
# agent column that selects the model of each type
_AGENT_MODEL_COLUMN = {
    "VAD": "vad_id",
    "ASR": "asr_id",
    "LLM": "llm_id",
    "TTS": "tts_id",
    "Memory": "mem_id",
    "Intent": "intent_id",
}


class DeviceRefused(Exception):
    """An unknown device connected while setting `device.auto_register` is false."""

    def __init__(self, mac: Optional[str], reason: str = "unknown device"):
        super().__init__(f"Device {mac!r} refused: {reason}")
        self.mac = mac
        self.reason = reason


class NoDefaultAgent(RuntimeError):
    """The database has no agent with is_default=1 (run `python -m core.db.seed`)."""


# ------------------------------------------------------------------ settings

def _deep_merge(dst: Dict[str, Any], src: Dict[str, Any]) -> None:
    for k, v in src.items():
        if isinstance(v, dict) and isinstance(dst.get(k), dict):
            _deep_merge(dst[k], v)
        else:
            dst[k] = copy.deepcopy(v)


def _parse_json(text: Optional[str], default: Any = None) -> Any:
    if text is None or text == "":
        return default
    try:
        return json.loads(text)
    except (TypeError, ValueError) as e:
        _log("warning", f"Ignoring invalid JSON in the database: {e}")
        return default


def build_global_config(db: Database) -> Dict[str, Any]:
    """Turn `setting` rows into a nested dict: key 'server.timezone_offset' -> {'server': {'timezone_offset': ..}}."""
    config: Dict[str, Any] = {}
    # Sorted so that a parent key (e.g. 'end_prompt') is applied before its children ('end_prompt.enable')
    for row in db.query_all("SELECT key, value FROM setting ORDER BY key"):
        value = _parse_json(row["value"], None)
        parts = row["key"].split(".")
        cur = config
        for part in parts[:-1]:
            nxt = cur.get(part)
            if not isinstance(nxt, dict):
                nxt = cur[part] = {}
            cur = nxt
        leaf = parts[-1]
        if isinstance(value, dict) and isinstance(cur.get(leaf), dict):
            _deep_merge(cur[leaf], value)
        else:
            cur[leaf] = value
    return config


def get_setting(db: Database, key: str, default: Any = None) -> Any:
    """One setting by its dotted key."""
    row = db.query_one("SELECT value FROM setting WHERE key = ?", (key,))
    if row is None:
        return default
    return _parse_json(row["value"], default)


# -------------------------------------------------------------------- agents

def _default_agent_row(db: Database) -> sqlite3.Row:
    row = db.query_one("SELECT * FROM agent WHERE is_default = 1 ORDER BY rowid LIMIT 1")
    if row is None:
        raise NoDefaultAgent("No default agent in the database; run `python -m core.db.seed`")
    return row


def _load_model(db: Database, model_id: Optional[str], model_type: str) -> Optional[Dict[str, Any]]:
    """config_json of an enabled model row, or None (missing, disabled or of another type)."""
    if not model_id:
        return None
    row = db.query_one("SELECT * FROM model_config WHERE id = ?", (model_id,))
    if row is None:
        _log("warning", f"Model {model_id} does not exist; ignored")
        return None
    if row["model_type"] != model_type:
        _log("warning", f"Model {model_id} is of type {row['model_type']}, not {model_type}; ignored")
        return None
    if not row["enabled"]:
        _log("warning", f"Model {model_id} is disabled; ignored")
        return None
    cfg = _parse_json(row["config_json"], {})
    return cfg if isinstance(cfg, dict) else {}


def _assemble_models(db: Database, agent: sqlite3.Row) -> Dict[str, Any]:
    """selected_module + VAD/ASR/LLM/TTS/Memory/Intent dicts keyed by model id."""
    out: Dict[str, Any] = {"selected_module": {}}
    for mtype in MODEL_TYPES:
        model_id = agent[_AGENT_MODEL_COLUMN[mtype]]
        cfg = _load_model(db, model_id, mtype)
        if cfg is None:
            continue
        out["selected_module"][mtype] = model_id
        out[mtype] = {model_id: cfg}

    # The Memory row names the LLM it uses in its `llm` key; that LLM row must be included
    mem_id = out["selected_module"].get("Memory")
    if mem_id:
        mem_llm = out["Memory"][mem_id].get("llm")
        if mem_llm:
            llm_cfg = _load_model(db, mem_llm, "LLM")
            if llm_cfg is not None:
                out.setdefault("LLM", {})[mem_llm] = llm_cfg
    return out


def _tts_extras(agent: sqlite3.Row) -> Dict[str, Any]:
    """Per-agent TTS overrides. Providers read these from their own config dict."""
    extras: Dict[str, Any] = {}
    if agent["tts_voice"]:
        extras["private_voice"] = agent["tts_voice"]
    params = _parse_json(agent["tts_params_json"], {}) or {}
    for key in ("language", "volume", "rate", "pitch"):
        if params.get(key) not in (None, ""):
            extras[key] = params[key]
    return extras


def _correct_words(db: Database, agent_id: str) -> List[str]:
    """'source|target' strings. Global rows (agent_id NULL) apply to every agent;
    a row of this agent overrides a global row with the same source."""
    words: Dict[str, str] = {}
    rows = db.query_all(
        "SELECT agent_id, source, target FROM replacement_word "
        "WHERE agent_id IS NULL OR agent_id = ? ORDER BY (agent_id IS NOT NULL), id",
        (agent_id,),
    )
    for row in rows:
        words[row["source"]] = row["target"]
    return [f"{s}|{t}" for s, t in words.items()]


def _assemble_agent(db: Database, agent: sqlite3.Row, mac: Optional[str]) -> Dict[str, Any]:
    glob = build_global_config(db)
    cfg = _assemble_models(db, agent)

    tts_id = cfg["selected_module"].get("TTS")
    if tts_id:
        cfg["TTS"][tts_id].update(_tts_extras(agent))

    cfg["correct_words"] = _correct_words(db, agent["id"])

    prompt = agent["system_prompt"]
    cfg["prompt"] = prompt if prompt else glob.get("prompt")

    summary = None
    if mac:
        row = db.query_one("SELECT summary FROM memory WHERE device_mac = ?", (mac,))
        if row is not None:
            summary = row["summary"]
    cfg["summaryMemory"] = summary

    plugins = _parse_json(agent["plugins_json"], {})
    cfg["plugins"] = plugins if isinstance(plugins, dict) else {}
    cfg["mcp_endpoint"] = agent["mcp_endpoint"] or None
    providers = _parse_json(agent["context_providers_json"], [])
    cfg["context_providers"] = providers if isinstance(providers, list) else []
    cfg["chat_history_conf"] = int(agent["history_mode"])

    # Guardrail settings and name list are read per connection, so edits apply from the next connection
    cfg["guardrails"] = glob.get("guardrails") or {}
    cfg["guardrail_names"] = [
        row["name"] for row in db.query_all("SELECT name FROM guardrail_name WHERE enabled = 1")
    ]

    cfg["device_max_output_size"] = glob.get("device_max_output_size", 0)
    cfg["delete_audio"] = bool(glob.get("delete_audio", True))
    cfg["tts_timeout"] = glob.get("tts_timeout", 15)
    return cfg


def build_base_config(db: Database) -> Dict[str, Any]:
    """Global settings plus the default agent's models and prompt (startup config)."""
    config = build_global_config(db)
    agent = _default_agent_row(db)
    models = _assemble_models(db, agent)
    config["selected_module"] = models.pop("selected_module")
    config.update(models)
    prompt = agent["system_prompt"]
    if prompt:
        config["prompt"] = prompt
    if agent["mcp_endpoint"]:
        config["mcp_endpoint"] = agent["mcp_endpoint"]
    config["default_agent_id"] = agent["id"]
    return config


# ------------------------------------------------------------------- devices

def normalize_mac(mac: Optional[str]) -> str:
    return (mac or "").strip().lower()


def register_device(db: Database, mac: str) -> None:
    """Insert an unknown device pointing at the default agent (waits for the writer)."""
    agent = _default_agent_row(db)
    fut = db.write(
        "INSERT OR IGNORE INTO device(mac, agent_id, last_connected_at) VALUES (?, ?, ?)",
        (mac, agent["id"], utcnow_iso()),
    )
    if not db.wait(fut):
        raise RuntimeError(f"Could not register device {mac}")
    _log("info", f"Device {mac} auto-registered to agent {agent['id']}")


def build_agent_config(db: Database, mac: Optional[str]) -> Dict[str, Any]:
    """Per-device config for `mac`. Blocking: call it from a worker thread (see get_agent_config).

    Raises DeviceRefused for an unknown device when `device.auto_register` is false.
    """
    mac = normalize_mac(mac)
    if not mac:
        raise DeviceRefused(mac, "missing device id")

    device = db.query_one("SELECT mac, agent_id FROM device WHERE mac = ?", (mac,))
    if device is None:
        if not get_setting(db, "device.auto_register", True):
            raise DeviceRefused(mac)
        register_device(db, mac)
        device = db.query_one("SELECT mac, agent_id FROM device WHERE mac = ?", (mac,))

    agent = db.query_one("SELECT * FROM agent WHERE id = ?", (device["agent_id"],))
    if agent is None:  # foreign keys make this unlikely; fall back to the default agent
        _log("warning", f"Agent {device['agent_id']} of device {mac} is missing; using the default agent")
        agent = _default_agent_row(db)
    cfg = _assemble_agent(db, agent, mac)
    cfg["agent_id"] = agent["id"]
    return cfg


async def get_agent_config(db: Database, mac: Optional[str]) -> Dict[str, Any]:
    """Async wrapper: runs build_agent_config in a worker thread so the event loop is never blocked."""
    return await asyncio.to_thread(build_agent_config, db, mac)


def touch_device(db: Database, mac: Optional[str]) -> None:
    """Record last_connected_at through the writer thread (fire and forget)."""
    mac = normalize_mac(mac)
    if mac:
        db.write("UPDATE device SET last_connected_at = ? WHERE mac = ?", (utcnow_iso(), mac))
