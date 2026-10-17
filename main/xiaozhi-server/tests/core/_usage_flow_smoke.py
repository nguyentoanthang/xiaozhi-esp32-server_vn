"""Subprocess helper for test_usage_flow.py (not collected by pytest).

Imports core.connection and the ASR base class with stubs for the third-party packages that are not
installed in every dev environment, then drives, on a seeded temporary database, the ai_usage wiring:
- ConnectionHandler.chat (streaming LLM, with and without usage reported by the provider),
- the disconnect path (title and memory calls, run in a worker thread),
- the intent LLM reply helper,
- the OpenRouter STT provider through ASRProviderBase.handle_voice_stop (fake client).
It prints one JSON line. It runs in its own process so the stubs never leak into other tests.
"""
import asyncio
import importlib.abc
import importlib.machinery
import json
import os
import queue
import sqlite3
import sys
import tempfile
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
        break
    except ModuleNotFoundError as e:
        STUB_TOPS.add(e.name.split(".")[0])
else:
    raise SystemExit("could not import the connection / asr modules")

from core.db import Database, build_base_config, set_database  # noqa: E402
from core.db.seed import seed_database  # noqa: E402
from core.providers.llm.openrouter.usage import UsageRecord, emit_usage  # noqa: E402
from core.utils.cache.manager import CacheType, cache_manager  # noqa: E402
from core.utils.dialogue import Message  # noqa: E402

MAC = "AA:BB:CC:00:00:01"


class StreamLLM:
    """LLM like the OpenRouter provider: emits a usage record when its stream / call ends."""

    model_name = "fake/model"
    api_key = "key"

    def __init__(self, report=True):
        self.report = report

    def _stream(self, call_kind, as_tuple):
        record = UsageRecord(
            call_kind=call_kind, requested_model=self.model_name, served_model="fake/model-v2",
            generation_id="gen-1", prompt_tokens=100, completion_tokens=20, total_tokens=120,
            cached_tokens=64, cost=0.0042, ttft_ms=12, duration_ms=90,
        )
        try:
            for piece in ("Hello ", "there"):
                yield (piece, None) if as_tuple else piece
        finally:
            if self.report:
                emit_usage(record)

    def response(self, session_id, dialogue, **kwargs):
        yield from self._stream("chat", False)

    def response_with_functions(self, session_id, dialogue, functions=None, **kwargs):
        yield from self._stream("chat_functions", True)

    def response_no_stream(self, system_prompt, user_prompt, **kwargs):
        record = UsageRecord(
            call_kind="no_stream", requested_model=self.model_name, prompt_tokens=50,
            completion_tokens=10, total_tokens=60, cost=0.001, duration_ms=30,
        )
        try:
            if "name chat sessions" in system_prompt:
                return '{"title": "Greeting", "summary": "The user said hello."}'
            return '{"memory": "kept"}'
        finally:
            if self.report:
                emit_usage(record)


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
    handler.tts = types.SimpleNamespace(tts_text_queue=queue.Queue(), store_tts_text=lambda *a: None)
    handler.features = {"emoji": False}
    return handler


def rows(db, where="1=1"):
    db.flush()
    return [dict(r) for r in db.query_all(f"SELECT * FROM ai_usage WHERE {where} ORDER BY id")]


def wait_for(db, predicate, timeout=10):
    deadline = time.time() + timeout
    while time.time() < deadline:
        db.flush()
        if predicate():
            return True
        time.sleep(0.1)
    return False


async def chat_flow(handler, llm, functions):
    handler.llm = llm
    handler.func_handler = types.SimpleNamespace(get_functions=lambda: [{"name": "x"}])
    handler.intent_type = "function_call" if functions else "intent_llm"
    await asyncio.to_thread(handler.chat, "hello")
    # an interrupted reply: the consumer stops after the first piece, the row is still written
    handler.client_abort = True
    await asyncio.to_thread(handler.chat, "again", 1)
    handler.client_abort = False


async def disconnect_flow(handler, db):
    from core.providers.memory.mem_local_short.mem_local_short import MemoryProvider

    handler.llm = StreamLLM()
    handler.memory = MemoryProvider({}, None)
    handler.memory.init_memory(role_id=handler.device_id, llm=handler.llm, summary_memory=None)
    handler.timeout_task = None
    handler.dialogue.put(Message(role="user", content="hello"))
    handler.dialogue.put(Message(role="assistant", content="Hello there"))
    await handler._save_and_close(None)
    wait_for(
        db,
        lambda: len(rows(db, f"session_id = '{handler.session_id}' AND purpose IN ('memory', 'title')")) >= 2,
    )


class FakeSttClient:
    def __init__(self):
        self.stt = self
        self.calls = []

    async def create_transcription_async(self, **kwargs):
        self.calls.append({k: v for k, v in kwargs.items() if k != "input_audio"})
        usage = types.SimpleNamespace(cost=0.0007, input_tokens=None, output_tokens=None, total_tokens=None, seconds=2.5)
        return types.SimpleNamespace(text="  hello world ", usage=usage)


async def stt_flow(handler, tmp):
    from core.providers.asr.openrouter_stt import ASRProvider

    heard = []

    async def fake_chat(conn, text, display_text=None):
        heard.append(text)

    client = FakeSttClient()
    provider = ASRProvider(
        {"api_key": "k", "model_name": "openai/whisper-large-v3", "output_dir": tmp}, True, client=client
    )
    with patch.object(asr_base, "startToChat", fake_chat), patch.object(
        asr_base, "enqueue_asr_report", lambda conn, text, audio: None
    ):
        await provider.handle_voice_stop(handler, [b"\x01\x00" * 16000])
    return heard, client.calls


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
    result = {}

    async def scenario():
        handler = await make_handler(base, db)
        result["first"] = {"session_id": handler.session_id, "agent_id": handler.agent_id}
        await chat_flow(handler, StreamLLM(report=True), functions=True)
        await chat_flow(handler, StreamLLM(report=False), functions=False)
        # intent LLM reply helper (purpose intent)
        from core.providers.intent.intent_llm.intent_llm import IntentProvider

        intent = IntentProvider({})
        intent.llm = StreamLLM()
        result["intent_reply"] = await intent.replyResult("system text", "what time is it", handler)
        result["heard"], result["stt_calls"] = await stt_flow(handler, tmp)
        # the device moves to another agent: a new connection gets the new attribution, old rows stay
        db.write_sync(
            "INSERT INTO agent(id, name, asr_id, llm_id, tts_id, mem_id, intent_id, vad_id) "
            "SELECT 'other', 'Other', asr_id, llm_id, tts_id, mem_id, intent_id, vad_id FROM agent WHERE id = 'default'"
        )
        db.write_sync("UPDATE device SET agent_id = 'other' WHERE mac = ?", (MAC.lower(),))
        second = await make_handler(base, db)
        result["second"] = {"session_id": second.session_id, "agent_id": second.agent_id}
        await chat_flow(second, StreamLLM(report=True), functions=False)
        await disconnect_flow(second, db)

    asyncio.run(scenario())
    result["rows"] = rows(db)
    db.close()
    print("RESULT " + json.dumps(result))


if __name__ == "__main__":
    main()
