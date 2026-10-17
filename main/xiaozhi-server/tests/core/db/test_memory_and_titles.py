"""Memory (mem_local_short / nomem) persisted per device MAC, and the session title written at disconnect."""
import asyncio
import json
import sys
import types
from unittest.mock import MagicMock

import pytest

from core.db import build_agent_config, set_database
from core.db.chat_history import record_message
from core.utils.dialogue import Message

MAC = "aa:bb:cc:dd:ee:01"
OTHER = "aa:bb:cc:dd:ee:02"
SUMMARY = json.dumps({"spatiotemporal_archive": {"identity_graph": {"current_name": "Linh"}}})


@pytest.fixture
def process_db(seeded_db):
    set_database(seeded_db)
    for mac in (MAC, OTHER):
        build_agent_config(seeded_db, mac)  # auto-registers the device on the default agent
    yield seeded_db
    set_database(None)


class FakeLLM:
    model_name = "fake"
    api_key = "key"

    def __init__(self, reply):
        self.reply = reply
        self.calls = []

    def response_no_stream(self, system_prompt, user_prompt, **kwargs):
        self.calls.append((system_prompt, user_prompt, kwargs))
        return self.reply


def msgs(*pairs):
    return [Message(role=r, content=c) for r, c in pairs]


TALK = msgs(("user", "My name is Linh"), ("assistant", "Nice to meet you, Linh"))


@pytest.fixture(autouse=True)
def stub_missing_pydub():
    """core.utils.util imports pydub, which is not installed in every dev environment. Stub it for
    these tests only and forget the modules that were imported against the stub."""
    before = set(sys.modules)
    if "pydub" not in sys.modules:
        try:
            import pydub  # noqa: F401
        except ImportError:
            sys.modules["pydub"] = MagicMock()
    yield
    for name in set(sys.modules) - before:
        if name.startswith(("pydub", "core.utils.util", "core.providers.memory")):
            del sys.modules[name]


def memory_provider(mac, llm, summary=None):
    from core.providers.memory.mem_local_short.mem_local_short import MemoryProvider

    provider = MemoryProvider({}, summary)
    provider.init_memory(role_id=mac, llm=llm, summary_memory=summary)
    return provider


def stored(db, mac):
    db.flush()
    row = db.query_one("SELECT summary, updated_at FROM memory WHERE device_mac = ?", (mac,))
    return None if row is None else (row["summary"], row["updated_at"])


# ------------------------------------------------------------------ memory

def test_summary_is_saved_for_the_device_mac(process_db):
    llm = FakeLLM(SUMMARY)
    provider = memory_provider(MAC.upper(), llm)  # stored under the normalised (lower-case) MAC
    asyncio.run(provider.save_memory(TALK, "sess"))
    summary, updated_at = stored(process_db, MAC)
    assert summary == SUMMARY and updated_at.endswith("Z")
    assert stored(process_db, OTHER) is None
    # The LLM saw the conversation and used the dedicated settings
    system_prompt, user_prompt, kwargs = llm.calls[0]
    assert "User: My name is Linh" in user_prompt and "Assistant: Nice to meet you" in user_prompt
    assert kwargs["max_tokens"] == 2000 and kwargs["temperature"] == 0.2


def test_saved_summary_is_overwritten_each_conversation_and_kept_per_mac(process_db):
    asyncio.run(memory_provider(MAC, FakeLLM(SUMMARY)).save_memory(TALK, "s1"))
    asyncio.run(memory_provider(OTHER, FakeLLM('{"a": 1}')).save_memory(TALK, "s2"))
    newer = json.dumps({"v": 2})
    provider = memory_provider(MAC, FakeLLM("```json\n" + newer + "\n```"), summary=SUMMARY)
    asyncio.run(provider.save_memory(TALK, "s3"))
    assert stored(process_db, MAC)[0] == newer
    assert stored(process_db, OTHER)[0] == '{"a": 1}'
    assert process_db.query_one("SELECT COUNT(*) AS n FROM memory")["n"] == 2  # one row per device


def test_previous_memory_is_part_of_the_prompt(process_db):
    llm = FakeLLM(SUMMARY)
    asyncio.run(memory_provider(MAC, llm, summary='{"old": true}').save_memory(TALK, "s"))
    assert '{"old": true}' in llm.calls[0][1]


def test_summary_is_loaded_on_the_next_connect(process_db):
    asyncio.run(memory_provider(MAC, FakeLLM(SUMMARY)).save_memory(TALK, "s1"))
    process_db.flush()
    cfg = build_agent_config(process_db, MAC)  # what the next connection reads
    assert cfg["summaryMemory"] == SUMMARY
    assert build_agent_config(process_db, OTHER)["summaryMemory"] is None
    provider = memory_provider(MAC, FakeLLM(""), summary=cfg["summaryMemory"])
    assert asyncio.run(provider.query_memory("anything")) == SUMMARY


def test_invalid_json_keeps_the_old_memory(process_db):
    process_db.write_sync("INSERT INTO memory(device_mac, summary, updated_at) VALUES (?, 'old', 'x')", (MAC,))
    provider = memory_provider(MAC, FakeLLM("sorry, I cannot do that"), summary="old")
    asyncio.run(provider.save_memory(TALK, "s"))
    assert stored(process_db, MAC)[0] == "old"
    assert provider.short_memory == "old"


def test_llm_error_keeps_the_old_memory(process_db):
    class Broken(FakeLLM):
        def response_no_stream(self, *a, **kw):
            raise RuntimeError("network down")

    provider = memory_provider(MAC, Broken(""), summary="old")
    asyncio.run(provider.save_memory(TALK, "s"))
    assert stored(process_db, MAC) is None and provider.short_memory == "old"


def test_one_message_is_not_enough_to_save(process_db):
    llm = FakeLLM(SUMMARY)
    asyncio.run(memory_provider(MAC, llm).save_memory(msgs(("user", "hi")), "s"))
    assert llm.calls == [] and stored(process_db, MAC) is None


def test_unregistered_device_does_not_break_saving(process_db):
    # memory.device_mac references device(mac): the write fails, is logged and nothing is raised
    provider = memory_provider("ff:ff:ff:ff:ff:ff", FakeLLM(SUMMARY), summary="old")
    asyncio.run(provider.save_memory(TALK, "s"))
    assert stored(process_db, "ff:ff:ff:ff:ff:ff") is None
    assert provider.short_memory == "old"


def test_nomem_writes_nothing(process_db):
    from core.providers.memory.nomem.nomem import MemoryProvider

    provider = MemoryProvider({})
    provider.init_memory(role_id=MAC, llm=FakeLLM(SUMMARY))
    assert asyncio.run(provider.save_memory(TALK, "s")) is None
    assert asyncio.run(provider.query_memory("x")) == ""
    assert process_db.query_one("SELECT COUNT(*) AS n FROM memory")["n"] == 0


def test_agent_with_nomem_row_selects_the_nomem_provider(process_db):
    process_db.write_sync("UPDATE agent SET mem_id = 'Memory_nomem' WHERE id = 'default'")
    cfg = build_agent_config(process_db, MAC)
    assert cfg["selected_module"]["Memory"] == "Memory_nomem"
    assert cfg["Memory"]["Memory_nomem"]["type"] == "nomem"


# ----------------------------------------------------------- session title

def conn_for(db, mode=2, llm=None, dialogue=None):
    record_message(db, session_id="sess-9", device_mac=MAC, agent_id="default", chat_type=1, content="hello")
    db.flush()
    return types.SimpleNamespace(
        logger=MagicMock(), db_enabled=True, chat_history_conf=mode, session_id="sess-9", llm=llm,
        dialogue=types.SimpleNamespace(dialogue=dialogue if dialogue is not None else TALK),
    )


def session(db):
    db.flush()
    return db.query_one("SELECT title, summary, ended_at FROM chat_session WHERE id = 'sess-9'")


def test_title_and_summary_are_written_at_disconnect(process_db):
    from core.handle.sessionEndHandle import finish_chat_session

    llm = FakeLLM('{"title": "Meeting Linh", "summary": "The user introduced themselves."}')
    finish_chat_session(conn_for(process_db, llm=llm))
    row = session(process_db)
    assert (row["title"], row["summary"]) == ("Meeting Linh", "The user introduced themselves.")
    assert row["ended_at"].endswith("Z")
    assert "User: My name is Linh" in llm.calls[0][1]


def test_title_reply_without_json_uses_the_first_line(process_db):
    from core.handle.sessionEndHandle import finish_chat_session

    finish_chat_session(conn_for(process_db, llm=FakeLLM('"Greetings"\nmore text')))
    row = session(process_db)
    assert row["title"] == "Greetings" and row["summary"] is None


def test_llm_failure_still_marks_the_session_ended(process_db):
    from core.handle.sessionEndHandle import finish_chat_session

    class Broken(FakeLLM):
        def response_no_stream(self, *a, **kw):
            raise RuntimeError("timeout")

    conn = conn_for(process_db, llm=Broken(""))
    finish_chat_session(conn)  # must not raise
    row = session(process_db)
    assert row["title"] is None and row["ended_at"] is not None


def test_no_title_when_history_is_off_or_nothing_was_said(process_db):
    from core.handle.sessionEndHandle import finish_chat_session

    llm = FakeLLM('{"title": "x"}')
    finish_chat_session(conn_for(process_db, mode=0, llm=llm))
    assert llm.calls == [] and session(process_db)["ended_at"] is None
    finish_chat_session(conn_for(process_db, llm=llm, dialogue=msgs(("assistant", "Hello!"))))
    assert llm.calls == [] and session(process_db)["title"] is None


def test_title_skips_temporary_few_shot_messages_and_reads_json_user_content(process_db):
    from core.handle.sessionEndHandle import conversation_text

    shots = [Message(role="user", content="Tell me a story", is_temporary=True)]
    shots += msgs(("user", json.dumps({"speaker": "Linh", "content": "what time is it"})), ("assistant", "noon"))
    assert conversation_text(shots) == "User: what time is it\nAssistant: noon"


def test_llm_helper_checks_the_purpose():
    from core.utils.llm_call import call_llm_no_stream

    llm = FakeLLM("ok")
    for purpose in ("chat", "memory", "title"):
        assert call_llm_no_stream(llm, purpose, "s", "u", max_tokens=5) == "ok"
    with pytest.raises(ValueError):
        call_llm_no_stream(llm, "other", "s", "u")
    assert llm.calls[0] == ("s", "u", {"max_tokens": 5})
