"""Offline tests for the OpenRouter LLM provider, using a fake client and stream.

No network: the SDK client is replaced before any provider is built (the shared
conftest also replaces httpx.Client, so the real SDK client must never be created).
Live checks (L1-L9 of the plan) are NOT here; they need a real key.
"""

import pytest

import gc
from types import SimpleNamespace

import httpx
from openrouter import components, errors
from openrouter.types import UNSET

import core.providers.llm.openrouter.openrouter as orp
from core.providers.llm.openrouter import usage as usage_mod
from core.providers.llm.openrouter.openrouter import LLMProvider

_REAL_CREATE_CLIENT = orp._create_client

CFG = {
    "type": "openrouter",
    "model_name": "openai/gpt-4o-mini",
    "api_key": "sk-or-TEST-SECRET",
    "temperature": "0.4",
}


# ---------------------------------------------------------------- fakes
class FakeStream:
    def __init__(self, items):
        self.items = list(items)
        self.closed = False
        self.pulled = 0

    def __iter__(self):
        return self

    def __next__(self):
        if self.pulled >= len(self.items):
            raise StopIteration
        item = self.items[self.pulled]
        self.pulled += 1
        if isinstance(item, BaseException):
            raise item
        return item

    def close(self):
        self.closed = True


class FakeClient:
    def __init__(self, items=None):
        self.requests = []
        self.streams = []
        self.items = items or []
        self.chat = SimpleNamespace(send=self._send)

    def _send(self, **kwargs):
        self.requests.append(kwargs)
        stream = FakeStream(self.items)
        self.streams.append(stream)
        return stream


def chunk(content=UNSET, tool_calls=None, finish=None, usage=None, choices=True,
          id="gen-1", model="served/model", error=None, metadata=None):
    delta = SimpleNamespace(content=content, tool_calls=tool_calls)
    return SimpleNamespace(
        id=id, model=model, error=error, usage=usage, openrouter_metadata=metadata,
        choices=[SimpleNamespace(delta=delta, finish_reason=finish, index=0)] if choices else [],
    )


def tc(index, id=None, name=None, arguments=None):
    function = None if name is None and arguments is None else SimpleNamespace(
        name=name, arguments=arguments)
    return SimpleNamespace(index=index, id=id, type=None, function=function)


def usage_obj(prompt=10, completion=5, cost=0.0002):
    return SimpleNamespace(
        prompt_tokens=prompt, completion_tokens=completion, total_tokens=prompt + completion,
        cost=cost, is_byok=False,
        cost_details=SimpleNamespace(upstream_inference_cost=0.0001),
        prompt_tokens_details=SimpleNamespace(cached_tokens=4, cache_write_tokens=0),
        completion_tokens_details=SimpleNamespace(reasoning_tokens=2),
    )


@pytest.fixture(autouse=True)
def isolated(monkeypatch):
    orp._clients.clear()
    created = []

    def fake_create(api_key, base_url, timeout_ms):
        client = FakeClient()
        created.append((api_key, base_url, timeout_ms, client))
        return client

    monkeypatch.setattr(orp, "_create_client", fake_create)
    records = []
    usage_mod.register_usage_sink(records.append)
    yield SimpleNamespace(created=created, records=records)
    usage_mod.unregister_usage_sink(records.append)
    orp._clients.clear()


def make(items, **cfg):
    provider = LLMProvider({**CFG, **cfg})
    provider.client.items = items
    return provider


DIALOGUE = [{"role": "system", "content": "sys"}, {"role": "user", "content": "hi"}]


# ---------------------------------------------------------------- (a) text
def test_a_text_streaming_yields_str_only(isolated):
    p = make([chunk("Hel"), chunk(UNSET), chunk("lo"), chunk("", finish="stop")])
    out = list(p.response("sess-1", DIALOGUE))
    assert out == ["Hel", "lo"]
    assert all(isinstance(x, str) for x in out)
    assert p.client.streams[0].closed
    (rec,) = isolated.records
    assert rec.call_kind == "chat" and rec.session_id == "sess-1"
    assert rec.finish_reason == "stop" and rec.aborted is False
    assert rec.generation_id == "gen-1" and rec.served_model == "served/model"
    assert rec.requested_model == "openai/gpt-4o-mini"
    assert rec.ttft_ms is not None and rec.duration_ms is not None


def test_request_shape(isolated):
    p = make([chunk("x")], fallback_models="b/two", provider_sort="price", max_tokens="99",
             record_routing=True)
    p.bind_connection(device_id="aa:bb:cc")
    list(p.response("sess-9", DIALOGUE, temperature=0.9))
    req = p.client.requests[0]
    assert req["model"] == "openai/gpt-4o-mini"
    assert req["stream"] is True
    assert req["temperature"] == 0.9  # per-call beats instance default 0.4
    assert req["max_completion_tokens"] == 99
    assert req["models"] == ["openai/gpt-4o-mini", "b/two"]
    assert req["provider"]["sort"] == "price"
    assert req["x_open_router_metadata"] == "enabled"
    assert req["session_id"] == "sess-9"
    assert req["user"] and "aa:bb:cc" not in req["user"]
    assert req["timeout_ms"] == 30000
    assert req["retries"] is orp.RETRY_NONE
    assert "tools" not in req and "stream_options" not in req


def test_metadata_is_not_requested_by_default(isolated):
    p = make([chunk("x")])
    list(p.response("sess-1", DIALOGUE))
    assert "x_open_router_metadata" not in p.client.requests[0]


def test_retries_are_disabled():
    assert orp.RETRY_NONE.strategy == "none"
    assert orp.RETRY_NONE.retry_connection_errors is False


def test_dialogue_is_not_mutated_and_missing_content_filled(isolated):
    p = make([chunk("x")])
    dialogue = [{"role": "assistant"}, {"role": "user", "content": "q"}]
    list(p.response("", dialogue))
    assert "content" not in dialogue[0]
    assert p.client.requests[0]["messages"][0]["content"] == ""
    assert "session_id" not in p.client.requests[0]


def test_think_blocks_are_stripped(isolated):
    p = make([chunk("a<think>"), chunk("hidden"), chunk("</think>b"), chunk("c")])
    assert list(p.response("s", DIALOGUE)) == ["a", "b", "c"]


# ---------------------------------------------------------------- (b) tools
def test_b_tool_call_fragments_across_chunks(isolated):
    items = [
        chunk(tool_calls=[tc(0, id="call_1", name="get_weather", arguments="")]),
        chunk(tool_calls=[tc(0, arguments='{"city":')]),
        chunk(tool_calls=[tc(0, arguments=' "Hue"}')]),
        chunk(tool_calls=[tc(1, id="call_2", name="other", arguments="{}")], finish="tool_calls"),
    ]
    p = make(items)
    out = list(p.response_with_functions("s", DIALOGUE, functions=[{"type": "function"}]))
    assert all(content is None for content, _ in out)
    merged = []
    for _, fragments in out:
        merge_tool_calls(merged, fragments)
    assert merged == [
        {"id": "call_1", "name": "get_weather", "arguments": '{"city": "Hue"}'},
        {"id": "call_2", "name": "other", "arguments": "{}"},
    ]
    assert all(hasattr(f, "index") for _, frags in out for f in frags)
    req = p.client.requests[0]
    assert req["tools"] == [{"type": "function"}] and req["tool_choice"] == "auto"
    (rec,) = isolated.records
    assert rec.call_kind == "chat_functions" and rec.tool_call_count == 2
    assert rec.finish_reason == "tool_calls"


def test_b_unset_tool_call_fields_are_safe(isolated):
    items = [
        chunk("Sure"),
        chunk(tool_calls=[SimpleNamespace(index=UNSET, id=UNSET, type=UNSET,
                                          function=SimpleNamespace(name=UNSET, arguments=UNSET))]),
    ]
    p = make(items)
    out = list(p.response_with_functions("s", DIALOGUE, functions=[{"x": 1}]))
    assert out[0] == ("Sure", None)
    frag = out[1][1][0]
    assert frag.index == 0 and frag.id is None and frag.function.name is None
    assert frag.function.arguments == ""


# ---------------------------------------------------------------- (c)/(d) usage
def test_c_usage_in_trailing_chunk_with_empty_choices(isolated):
    meta = SimpleNamespace(
        attempt=1, generation_time=321,
        endpoints=SimpleNamespace(available=[
            SimpleNamespace(provider="Other", selected=False),
            SimpleNamespace(provider="DeepInfra", selected=True)]),
        attempts=None)
    p = make([chunk("hi"), chunk("", finish="stop"),
              chunk(choices=False, usage=usage_obj(), metadata=meta)])
    assert list(p.response("s", DIALOGUE)) == ["hi"]
    (rec,) = isolated.records
    assert (rec.prompt_tokens, rec.completion_tokens, rec.total_tokens) == (10, 5, 15)
    assert rec.cost == 0.0002 and rec.upstream_inference_cost == 0.0001
    assert rec.cached_tokens == 4 and rec.cache_write_tokens == 0 and rec.reasoning_tokens == 2
    assert rec.is_byok is False
    assert rec.selected_provider == "DeepInfra" and rec.attempts == 1
    assert rec.generation_time_ms == 321


def test_d_usage_in_last_content_chunk(isolated):
    p = make([chunk("a"), chunk("b", usage=usage_obj(prompt=7, completion=1, cost=0.0))])
    assert list(p.response("s", DIALOGUE)) == ["a", "b"]
    (rec,) = isolated.records
    assert rec.prompt_tokens == 7 and rec.cost == 0.0  # zero cost is kept, not None


def test_no_usage_leaves_none(isolated):
    p = make([chunk("a")])
    list(p.response("s", DIALOGUE))
    (rec,) = isolated.records
    assert rec.prompt_tokens is None and rec.cost is None and rec.selected_provider is None


def test_metadata_falls_back_to_last_attempt(isolated):
    meta = SimpleNamespace(attempt=2, generation_time=None,
                           endpoints=SimpleNamespace(available=[]),
                           attempts=[SimpleNamespace(provider="A"), SimpleNamespace(provider="B")])
    p = make([chunk("a", metadata=meta)])
    list(p.response("s", DIALOGUE))
    assert isolated.records[0].selected_provider == "B"


# ---------------------------------------------------------------- (e) chunk.error
def test_e_chunk_error_raises_and_is_recorded(isolated):
    err = SimpleNamespace(code=429, message="rate limited",
                          metadata=SimpleNamespace(error_type="rate_limit"))
    p = make([chunk("a"), chunk(error=err, choices=False), chunk("never")])
    got = []
    with pytest.raises(RuntimeError, match="429"):
        for x in p.response("s", DIALOGUE):
            got.append(x)
    assert got == ["a"]
    assert p.client.streams[0].closed
    (rec,) = isolated.records
    assert rec.error_type == "rate_limit" and rec.error_status == 429
    assert rec.error_message == "rate limited" and rec.aborted is False


def test_e_finish_reason_error(isolated):
    p = make([chunk("a", finish="error")])
    with pytest.raises(RuntimeError):
        list(p.response("s", DIALOGUE))
    assert isolated.records[0].error_type == "finish_reason_error"


# ---------------------------------------------------------------- (f) validation / http errors
def test_f_response_validation_error_is_reraised_and_recorded(isolated):
    exc = errors.ResponseValidationError(
        "bad", httpx.Response(200, text="raw"), ValueError("cause"), body='{"error": "x"}')
    p = make([chunk("a"), exc])
    with pytest.raises(errors.ResponseValidationError):
        list(p.response("s", DIALOGUE))
    assert p.client.streams[0].closed
    (rec,) = isolated.records
    assert rec.error_type == "ResponseValidationError" and rec.error_status == 200


def test_error_raised_by_send_is_recorded(isolated):
    p = make([])

    def boom(**_kw):
        raise httpx.ConnectError("down")

    p.client.chat.send = boom
    with pytest.raises(httpx.ConnectError):
        list(p.response("s", DIALOGUE))
    (rec,) = isolated.records
    assert rec.error_type == "ConnectError" and rec.duration_ms is not None


def test_api_key_never_appears_in_records_or_logs(isolated, monkeypatch):
    logged = []

    class FakeLogger:
        def bind(self, **_kw):
            return self

        def __getattr__(self, _name):
            return lambda msg, *a, **k: logged.append(str(msg))

    monkeypatch.setattr(orp, "logger", FakeLogger())
    p = make([chunk("a"), RuntimeError("x")])
    with pytest.raises(RuntimeError):
        list(p.response("s", DIALOGUE))
    assert logged  # the failure was logged
    assert "TEST-SECRET" not in repr(isolated.records[0].to_dict())
    assert not any("TEST-SECRET" in line for line in logged)


# ---------------------------------------------------------------- (g) abort
def test_g_generator_closed_early_closes_stream_and_marks_aborted(isolated):
    p = make([chunk("a"), chunk("b"), chunk("c")])
    gen = p.response("s", DIALOGUE)
    assert next(gen) == "a"
    gen.close()
    assert p.client.streams[0].closed
    assert p.client.streams[0].pulled == 1
    (rec,) = isolated.records
    assert rec.aborted is True and rec.prompt_tokens is None
    assert rec.generation_id == "gen-1"


def test_g_break_then_garbage_collect_still_cleans_up(isolated):
    p = make([chunk("a"), chunk("b")])
    gen = p.response("s", DIALOGUE)
    for _ in gen:
        break  # like chat() on client_abort: break without close()
    del gen
    gc.collect()
    assert p.client.streams[0].closed
    assert len(isolated.records) == 1 and isolated.records[0].aborted is True


def test_g_function_generator_closed_early(isolated):
    p = make([chunk(tool_calls=[tc(0, id="i", name="n", arguments="")]), chunk("b")])
    gen = p.response_with_functions("s", DIALOGUE, functions=[{"x": 1}])
    next(gen)
    gen.close()
    assert p.client.streams[0].closed
    assert isolated.records[0].aborted is True and len(isolated.records) == 1


# ---------------------------------------------------------------- (h) no_stream
def test_h_response_no_stream_passes_kwargs(isolated):
    p = make([chunk("Hel"), chunk("lo")])
    text = p.response_no_stream("sys", "user", max_tokens=33, temperature=0.1)
    assert text == "Hello"
    req = p.client.requests[0]
    assert req["max_completion_tokens"] == 33 and req["temperature"] == 0.1
    assert req["messages"] == [{"role": "system", "content": "sys"},
                               {"role": "user", "content": "user"}]
    assert "session_id" not in req
    (rec,) = isolated.records
    assert rec.session_id == "" and rec.call_kind == "chat"


def test_h_no_stream_record_carries_device_after_bind(isolated):
    p = make([chunk("x")])
    p.bind_connection(device_id="11:22:33:44:55:66")
    p.response_no_stream("s", "u")
    assert isolated.records[0].device_id == "11:22:33:44:55:66"
    assert p.client.requests[0]["user"]


# ---------------------------------------------------------------- (i) interleaved
def test_i_two_interleaved_calls_make_two_separate_records(isolated):
    p = make([chunk("a", id="g1"), chunk("b", id="g1", usage=usage_obj(prompt=1))])
    g1 = p.response("s1", DIALOGUE)
    g2 = p.response("s2", DIALOGUE)
    assert next(g1) == "a"
    assert next(g2) == "a"
    assert next(g1) == "b"
    assert next(g2) == "b"
    assert list(g1) == [] and list(g2) == []
    assert len(isolated.records) == 2
    assert {r.session_id for r in isolated.records} == {"s1", "s2"}
    assert isolated.records[0].record_id != isolated.records[1].record_id


def test_record_emitted_exactly_once_on_normal_end_and_gc(isolated):
    p = make([chunk("a")])
    gen = p.response("s", DIALOGUE)
    list(gen)
    gen.close()
    del gen
    gc.collect()
    assert len(isolated.records) == 1


# ---------------------------------------------------------------- client / config
def test_shared_client_cache(isolated):
    LLMProvider(CFG)
    LLMProvider(CFG)
    assert len(isolated.created) == 1
    LLMProvider({**CFG, "api_key": "other"})
    LLMProvider({**CFG, "timeout": 10})
    LLMProvider({**CFG, "base_url": "http://localhost:1/v1"})
    assert len(isolated.created) == 4
    assert isolated.created[0][1:3] == ("https://openrouter.ai/api/v1", 30000)


def test_create_client_disables_retries_and_sets_timeout(monkeypatch):
    seen = {}

    def fake_sdk(**kwargs):
        seen.update(kwargs)
        return object()

    monkeypatch.setattr(orp, "OpenRouter", fake_sdk)
    _REAL_CREATE_CLIENT("k", "http://x/v1", 12000)
    assert seen["retry_config"] is orp.RETRY_NONE
    assert seen["timeout_ms"] == 12000 and seen["server_url"] == "http://x/v1"
    assert seen["api_key"] == "k"


def test_missing_key_does_not_crash_construction():
    p = LLMProvider({"model_name": "m"})
    assert p.api_key == ""


def test_placeholder_key_is_reported(monkeypatch):
    errors_logged = []

    class FakeLogger:
        def bind(self, **_kw):
            return self

        def error(self, msg):
            errors_logged.append(msg)

        def debug(self, *_a, **_k):
            pass

    monkeypatch.setattr(orp, "logger", FakeLogger())
    LLMProvider({"model_name": "m", "api_key": "your_key"})
    assert errors_logged


# ---------------------------------------------------------------- real SDK models
def real_chunk(payload):
    base = {"id": "gen-r", "created": 1, "model": "m", "object": "chat.completion.chunk"}
    return components.ChatStreamChunk.model_validate({**base, **payload})


def test_real_sdk_chunks_text_tools_and_usage(isolated):
    items = [
        real_chunk({"choices": [{"index": 0, "finish_reason": None,
                                 "delta": {"role": "assistant", "content": "Hi"}}]}),
        real_chunk({"choices": [{"index": 0, "finish_reason": None,
                                 "delta": {"tool_calls": [{"index": 0, "id": "c1",
                                           "function": {"name": "f", "arguments": ""}}]}}]}),
        real_chunk({"choices": [{"index": 0, "finish_reason": None,
                                 "delta": {"tool_calls": [{"index": 0,
                                           "function": {"arguments": "{}"}}]}}]}),
        real_chunk({"choices": [{"index": 0, "finish_reason": "tool_calls", "delta": {}}]}),
        real_chunk({"choices": [], "usage": {
            "prompt_tokens": 20, "completion_tokens": 3, "total_tokens": 23, "cost": 0.0005,
            "cost_details": {"upstream_inference_cost": 0.0004,
                             "upstream_inference_prompt_cost": 0.0003,
                             "upstream_inference_completions_cost": 0.0001},
            "prompt_tokens_details": {"cached_tokens": 8},
            "completion_tokens_details": {"reasoning_tokens": 1},
            "is_byok": False}}),
    ]
    p = make(items)
    out = list(p.response_with_functions("s", DIALOGUE, functions=[{"x": 1}]))
    merged = []
    for _, frags in out:
        if frags:
            merge_tool_calls(merged, frags)
    assert out[0] == ("Hi", None)
    assert merged == [{"id": "c1", "name": "f", "arguments": "{}"}]
    (rec,) = isolated.records
    assert rec.prompt_tokens == 20 and rec.cost == 0.0005
    assert rec.upstream_inference_cost == 0.0004 and rec.cached_tokens == 8
    assert rec.reasoning_tokens == 1 and rec.finish_reason == "tool_calls"
    assert rec.cache_write_tokens is None  # not reported -> None


def test_real_sdk_chunk_error_field(isolated):
    items = [real_chunk({"choices": [], "error": {"code": 502, "message": "upstream down"}})]
    p = make(items)
    with pytest.raises(RuntimeError, match="502"):
        list(p.response("s", DIALOGUE))
    assert isolated.records[0].error_status == 502


# ---------------------------------------------------------------- helper
def merge_tool_calls(tool_calls_list, tools_call):
    """Same logic as ConnectionHandler._merge_tool_calls (copied; connection.py is heavy to import)."""
    for tool_call in tools_call:
        tool_index = getattr(tool_call, "index", None)
        if tool_index is None:
            if tool_call.function.name:
                tool_index = len(tool_calls_list)
            else:
                tool_index = len(tool_calls_list) - 1 if tool_calls_list else 0
        if tool_index >= len(tool_calls_list):
            tool_calls_list.append({"id": "", "name": "", "arguments": ""})
        if tool_call.id:
            tool_calls_list[tool_index]["id"] = tool_call.id
        if tool_call.function.name:
            tool_calls_list[tool_index]["name"] = tool_call.function.name
        if tool_call.function.arguments:
            tool_calls_list[tool_index]["arguments"] += tool_call.function.arguments
