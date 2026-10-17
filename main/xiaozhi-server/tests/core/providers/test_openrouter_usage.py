"""Offline tests for core/providers/llm/openrouter/usage.py."""

import pytest

import json


from core.providers.llm.openrouter import usage


@pytest.fixture
def clean_sinks():
    saved = list(usage._sinks)
    yield
    usage._sinks[:] = saved


def test_record_dict_has_no_text_fields():
    d = usage.UsageRecord(session_id="s1").to_dict()
    assert d["session_id"] == "s1"
    assert d["aborted"] is False
    assert d["tool_call_count"] == 0
    for forbidden in ("prompt", "response", "content", "messages", "api_key"):
        assert forbidden not in d


def test_sinks_receive_record_and_errors_are_swallowed(clean_sinks):
    seen = []

    def bad(_record):
        raise ValueError("boom")

    usage.register_usage_sink(bad)
    usage.register_usage_sink(seen.append)
    usage.register_usage_sink(seen.append)  # idempotent
    record = usage.UsageRecord()
    usage.emit_usage(record)  # must not raise
    assert seen == [record]


def test_unregister(clean_sinks):
    seen = []
    usage.register_usage_sink(seen.append)
    usage.unregister_usage_sink(seen.append)
    usage.emit_usage(usage.UsageRecord())
    assert seen == []


def test_default_log_sink_emits_tagged_json(monkeypatch):
    lines = []

    class FakeLogger:
        def bind(self, **_kw):
            return self

        def info(self, msg):
            lines.append(msg)

    monkeypatch.setattr(usage, "logger", FakeLogger())
    record = usage.UsageRecord(
        session_id="s", device_id="aa:bb", prompt_tokens=12, cost=0.0, routing={}
    )
    usage.log_usage_sink(record)
    assert len(lines) == 1
    assert lines[0].startswith("llm_usage ")
    payload = json.loads(lines[0][len("llm_usage "):])
    assert payload["session_id"] == "s"
    assert payload["device_id"] == "aa:bb"
    assert payload["prompt_tokens"] == 12
    assert payload["cost"] == 0.0  # zero cost is kept, only None is dropped
    assert "completion_tokens" not in payload
    assert "routing" not in payload


def test_log_sink_is_registered_by_default():
    assert usage.log_usage_sink in usage._sinks
