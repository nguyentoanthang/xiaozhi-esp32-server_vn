"""Subprocess helper for test_guardrail_and_history_flow.py (not collected by pytest).

Imports core.connection / the ASR and TTS base classes with stubs for the third-party packages that
are not installed in every dev environment, then drives, on a seeded temporary database:
- the per-connection guardrail (settings and names read from SQLite),
- ASRProviderBase.handle_voice_stop (masking before logging, LLM entry and the report queue),
- the TTS-side restore of placeholders,
- the disconnect path (report queue drain, session title, memory row).
It prints one JSON line. It runs in its own process so the stubs never leak into other tests.
"""
import asyncio
import importlib.abc
import importlib.machinery
import json
import os
import sqlite3
import sys
import tempfile
import threading
import time
import types
from pathlib import Path
from unittest.mock import MagicMock, patch

SERVER_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(SERVER_DIR))
os.chdir(SERVER_DIR)

STUB_TOPS = set()


class _Stub(importlib.abc.MetaPathFinder, importlib.abc.Loader):
    def find_spec(self, name, path, target=None):
        if name.split(".")[0] in STUB_TOPS:
            return importlib.machinery.ModuleSpec(name, self, is_package=True)

    def create_module(self, spec):
        m = MagicMock(name=spec.name)
        m.__path__ = []
        m.__spec__ = spec
        m.__name__ = spec.name
        return m

    def exec_module(self, module):
        pass


sys.meta_path.append(_Stub())

import tests.conftest  # noqa: E402,F401  (opus stub, provider mocks)

for _ in range(60):
    try:
        import core.connection as conn_module  # noqa: E402
        import core.providers.asr.base as asr_base  # noqa: E402
        import core.providers.tts.base as tts_base  # noqa: E402
        break
    except ModuleNotFoundError as e:
        STUB_TOPS.add(e.name.split(".")[0])
else:
    raise SystemExit("could not import the connection / asr / tts modules")

import core.handle.reportHandle as report_handle  # noqa: E402
from core.db import Database, build_base_config, set_database  # noqa: E402
from core.db.seed import seed_database  # noqa: E402
from core.utils.cache.manager import CacheType, cache_manager  # noqa: E402
from core.utils.dialogue import Message  # noqa: E402

MAC = "AA:BB:CC:00:00:01"
TEXT = "call Linh at 0912 345 678 or mail linh@example.com"


class FakeLLM:
    model_name = "fake"
    api_key = "key"

    def __init__(self):
        self.prompts = []

    def response_no_stream(self, system_prompt, user_prompt, **kwargs):
        self.prompts.append(user_prompt)
        if "naming" in system_prompt.lower() or "name chat sessions" in system_prompt:
            return '{"title": "Call Linh", "summary": "User asked to call."}'
        return '{"memory": "kept"}'


class FakeMemory:
    """Stands in for mem_local_short: stores through the same table and records what it saw."""

    def __init__(self, db):
        self.db = db
        self.seen = []

    async def save_memory(self, msgs, session_id=None):
        self.seen = [m.content for m in msgs]
        self.db.write_sync(
            "INSERT OR REPLACE INTO memory(device_mac, summary, updated_at) VALUES (?, ?, 't')",
            ("aa:bb:cc:00:00:01", json.dumps(self.seen)),
        )


class Asr(asr_base.ASRProviderBase):
    def __init__(self, text):
        super().__init__()
        self.text = text

    async def speech_to_text_wrapper(self, pcm_data, session_id):
        return self.text, None

    async def speech_to_text(self, opus_data, session_id, audio_format="opus", artifacts=None):
        return self.text, None


async def make_handler(base, db):
    handler = conn_module.ConnectionHandler(base, None, None, None, None, None, None)
    handler.loop = asyncio.get_running_loop()
    handler.headers = {"device-id": MAC}
    handler.device_id = MAC
    handler.websocket = MagicMock()

    def fake_initialize_modules(logger, private_config, *flags):
        return {}

    with patch.object(conn_module, "initialize_modules", fake_initialize_modules):
        await handler._initialize_private_config_async()
    db.flush()
    return handler


async def asr_flow(handler, raw):
    """Run handle_voice_stop with a fake recognizer; return (text sent to chat, reported text, logs)."""
    chat, reported, logs = [], [], []

    async def fake_chat(conn, text, display_text=None):
        chat.append(text)

    log = MagicMock()
    log.bind.return_value.info.side_effect = lambda m, *a: logs.append(str(m))
    log.bind.return_value.debug.side_effect = lambda m, *a: logs.append(str(m))
    log.bind.return_value.error.side_effect = lambda m, *a: logs.append(str(m))
    handler.voiceprint_provider = None
    with patch.object(asr_base, "startToChat", fake_chat), patch.object(
        asr_base, "enqueue_asr_report", lambda conn, text, audio: reported.append(text)
    ), patch.object(asr_base, "logger", log):
        await Asr(raw).handle_voice_stop(handler, [b"\x01\x00" * 100])
    return chat, reported, logs


async def subtitle_flow(handler, source, payload):
    """Drive the real startToChat through the ASR or the `detect` text path.

    Returns what each sink saw: device subtitle (stt message), LLM entry (chat), dialogue/report text, logs.
    """
    import core.handle.receiveAudioHandle as rah
    import core.handle.textHandler.listenMessageHandler as lmh

    stt, llm, reported, logs = [], [], [], []

    async def fake_stt(conn, text):
        stt.append(text)

    log = MagicMock()
    for level in ("info", "debug", "error", "warning"):
        getattr(log.bind.return_value, level).side_effect = lambda m, *a: logs.append(str(m))
    handler.logger = log
    handler.voiceprint_provider = None
    handler.intent_type = "function_call"
    handler.max_output_size = 0
    handler.client_is_speaking = False
    handler.chat = lambda text: llm.append(text)
    handler.executor = types.SimpleNamespace(submit=lambda fn, *a: fn(*a))
    handler.config = dict(handler.config, wakeup_words=["hello"])

    def fake_report(conn, text, audio):
        reported.append(text)

    with patch.object(rah, "send_stt_message", fake_stt), patch.object(
        asr_base, "enqueue_asr_report", fake_report
    ), patch.object(lmh, "enqueue_asr_report", fake_report), patch.object(asr_base, "logger", log):
        if source == "asr":
            await Asr(payload).handle_voice_stop(handler, [bytes(200) * 100])
        else:
            await lmh.ListenTextMessageHandler().handle(handler, {"state": "detect", "text": payload})
    return {"stt": stt, "llm": llm, "reported": reported, "logs": logs, "dialogue": [m.content for m in handler.dialogue.dialogue]}


def disconnect_flow(base, db, handler):
    """Queue reports, then run the real _save_and_close and wait for its background thread."""
    llm, memory = FakeLLM(), FakeMemory(db)
    handler.llm, handler.memory = llm, memory
    handler.timeout_task = None
    handler.dialogue.put(Message(role="user", content="few-shot", is_temporary=True))
    handler.dialogue.put(Message(role="user", content=TEXT_MASKED[0]))
    handler.dialogue.put(Message(role="assistant", content="Calling [NAME_1]"))

    with patch.object(report_handle, "encode_pcm_to_opus_frames", lambda pcm, rate: [b"OP"]):
        handler._init_report_threads()
        report_handle.enqueue_asr_report(handler, TEXT_MASKED[0], [b"\x01\x00" * 50])
        report_handle.enqueue_tts_report(handler, "Calling [NAME_1]", [b"packet"])
        asyncio.run(handler._save_and_close(None))
    deadline = time.time() + 10
    while time.time() < deadline:
        db.flush()
        row = db.query_one("SELECT title FROM chat_session WHERE id = ?", (handler.session_id,))
        if row is not None and row["title"] and memory.seen:
            break
        time.sleep(0.1)
    db.flush()
    return llm, memory


TEXT_MASKED = [None]


def main():
    tmp = tempfile.mkdtemp()
    db = Database(os.path.join(tmp, "flow.db"))
    conn = sqlite3.connect(db.path)
    seed_database(conn)
    conn.close()
    set_database(db)
    base = build_base_config(db)
    base["log"] = {"log_dir": tmp, "data_dir": tmp}
    cache_manager.set(CacheType.CONFIG, "main_config", base)

    db.write_sync("INSERT INTO guardrail_name(name) VALUES ('Linh')")
    db.write_sync("INSERT INTO guardrail_name(name, enabled) VALUES ('Hidden', 0)")
    result = {}

    # 1) guardrail from the database: names loaded at connection time, ASR text masked everywhere
    async def scenario_masking():
        handler = await make_handler(base, db)
        chat, reported, logs = await asr_flow(handler, TEXT)
        chat2, _, _ = await asr_flow(handler, {"content": TEXT, "language": "en"})
        chat3, _, _ = await asr_flow(handler, "Hello, ask Hidden")
        return handler, chat, reported, logs, chat2, chat3

    handler, chat, reported, logs, chat2, chat3 = asyncio.run(scenario_masking())
    result["masked"] = {
        "chat": chat,
        "reported": reported,
        "logs_have_raw": any(("0912" in l or "linh" in l.lower() or "example.com" in l) for l in logs),
        "logs": [l for l in logs if "Recognized text" in l],
        "dict_chat": chat2,
        "disabled_name_not_masked": chat3,
        "names_loaded": sorted(handler.config.get("guardrails", {}).keys()),
    }
    if not chat:
        raise SystemExit("no chat text; logs: " + json.dumps(logs))
    TEXT_MASKED[0] = chat[0]

    # 1b) the device subtitle shows the original text; the LLM, report and logs only get the masked one
    async def scenario_subtitle():
        h = await make_handler(base, db)
        out = {}
        out["asr"] = await subtitle_flow(h, "asr", TEXT)
        out["asr_dict"] = await subtitle_flow(h, "asr", {"content": TEXT, "language": "en"})
        out["detect"] = await subtitle_flow(h, "detect", TEXT)
        out["restore_state"] = sorted(h.guardrail._originals)
        return out

    sub = asyncio.run(scenario_subtitle())
    for v in sub.values():
        if isinstance(v, dict):
            v["logs_have_raw"] = any(("0912" in l or "linh" in l.lower() or "example.com" in l) for l in v["logs"])
            del v["logs"]
    result["subtitle"] = sub

    # 2) TTS side restore (restore_in_reply off, then on)
    gr = handler.guardrail
    tts_self = types.SimpleNamespace(conn=handler)
    result["tts_restore_off"] = tts_base.TTSProviderBase._restore_masked_text(tts_self, "Calling [NAME_1]")
    gr.restore_in_reply = True
    result["tts_restore_on"] = tts_base.TTSProviderBase._restore_masked_text(tts_self, "Calling [NAME_1] on [PHONE_1]")
    gr.restore_in_reply = False

    # 3) disconnect: queue drained, rows stored, title and memory written
    llm, memory = disconnect_flow(base, db, handler)
    sess = db.query_one("SELECT * FROM chat_session WHERE id = ?", (handler.session_id,))
    rows = db.query_all("SELECT chat_type, content, audio_id FROM chat_message WHERE session_id = ? ORDER BY id", (handler.session_id,))
    result["disconnect"] = {
        "session": dict(sess) if sess else None,
        "messages": [[r["chat_type"], r["content"], r["audio_id"] is not None] for r in rows],
        "title_prompt": llm.prompts[0] if llm.prompts else None,
        "memory_seen": memory.seen,
        "memory_row": db.query_one("SELECT summary FROM memory WHERE device_mac = 'aa:bb:cc:00:00:01'")["summary"],
    }

    # 4) master switch off: a new connection masks nothing
    db.write_sync("UPDATE setting SET value = 'false' WHERE key = 'guardrails.enabled'")

    async def scenario_off():
        h = await make_handler(base, db)
        return (await asr_flow(h, TEXT))[0]

    result["switch_off_chat"] = asyncio.run(scenario_off())

    # 5) history off for the agent: nothing is stored, nothing to drain
    db.write_sync("UPDATE setting SET value = 'true' WHERE key = 'guardrails.enabled'")
    db.write_sync("UPDATE agent SET history_mode = 0 WHERE id = 'default'")

    async def scenario_history_off():
        h = await make_handler(base, db)
        h.dialogue.put(Message(role="user", content="hi"))
        h.dialogue.put(Message(role="assistant", content="hello"))
        h.llm, h.memory = FakeLLM(), FakeMemory(db)
        h.timeout_task = None
        report_handle.enqueue_asr_report(h, "hi", [])
        await h._save_and_close(None)
        return h

    h = asyncio.run(scenario_history_off())
    time.sleep(0.5)
    db.flush()
    result["history_off"] = {
        "report_thread": h.report_thread is not None,
        "sessions_for_it": db.query_one("SELECT COUNT(*) FROM chat_session WHERE id = ?", (h.session_id,))[0],
    }
    db.close()
    print("RESULT " + json.dumps(result))


if __name__ == "__main__":
    main()
