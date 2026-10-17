"""ai_usage wired into the connection, disconnect path, intent helper and STT provider (no network).

Runs tests/core/_usage_flow_smoke.py in a subprocess so its stubs of missing third-party packages
never leak into the other tests.
"""
import json
import subprocess
import sys
from pathlib import Path

import pytest

HELPER = Path(__file__).with_name("_usage_flow_smoke.py")
MAC = "aa:bb:cc:00:00:01"


@pytest.fixture(scope="module")
def result():
    r = subprocess.run([sys.executable, str(HELPER)], capture_output=True, text=True, timeout=180)
    lines = [l for l in r.stdout.splitlines() if l.startswith("RESULT ")]
    assert lines, f"helper failed:\n{r.stdout[-2000:]}\n{r.stderr[-3000:]}"
    return json.loads(lines[-1][len("RESULT "):])


def rows(result, **match):
    return [r for r in result["rows"] if all(r[k] == v for k, v in match.items())]


def test_streaming_chat_rows_carry_provider_usage_and_attribution(result):
    first = result["first"]
    with_tools = rows(result, session_id=first["session_id"], call_kind="chat_functions")
    assert len(with_tools) == 2  # the normal reply and the interrupted one both wrote a row
    row = with_tools[0]
    assert (row["kind"], row["purpose"], row["device_mac"], row["agent_id"]) == ("llm", "chat", MAC, "default")
    assert (row["prompt_tokens"], row["completion_tokens"], row["total_tokens"], row["cached_tokens"]) == (100, 20, 120, 64)
    assert row["cost"] == pytest.approx(0.0042)
    assert (row["requested_model"], row["served_model"], row["generation_id"]) == ("fake/model", "fake/model-v2", "gen-1")


def test_provider_without_usage_still_gets_a_row_with_null_tokens(result):
    first = result["first"]
    plain = rows(result, session_id=first["session_id"], call_kind="chat")
    assert len(plain) == 2
    for row in plain:
        assert (row["purpose"], row["device_mac"], row["agent_id"]) == ("chat", MAC, "default")
        assert row["requested_model"] == "fake/model"
        assert row["prompt_tokens"] is None and row["total_tokens"] is None and row["cost"] is None
        assert row["duration_ms"] is not None


def test_intent_llm_call_is_attributed(result):
    (row,) = rows(result, purpose="intent")
    assert (row["session_id"], row["device_mac"], row["agent_id"]) == (result["first"]["session_id"], MAC, "default")
    assert row["total_tokens"] == 60 and row["call_kind"] == "no_stream"


def test_stt_row_has_attribution_seconds_and_cost(result):
    (row,) = rows(result, kind="stt")
    assert result["heard"] == ["hello world"]  # text is stripped
    assert (row["purpose"], row["session_id"], row["device_mac"], row["agent_id"]) == (
        "stt", result["first"]["session_id"], MAC, "default")
    assert row["audio_seconds"] == 2.5 and row["cost"] == pytest.approx(0.0007)
    assert row["requested_model"] == "openai/whisper-large-v3"
    assert row["served_model"] is None and row["provider"] is None and row["generation_id"] is None
    call = result["stt_calls"][0]
    assert call["session_id"] == result["first"]["session_id"]
    assert call["user"] and MAC not in json.dumps(call)  # pseudonym, never the raw MAC


def test_rows_written_after_the_agent_change_use_the_new_agent_old_rows_keep_theirs(result):
    second = result["second"]
    assert second["agent_id"] == "other"
    assert {r["agent_id"] for r in rows(result, session_id=result["first"]["session_id"])} == {"default"}
    after = rows(result, session_id=second["session_id"])
    assert {r["agent_id"] for r in after} == {"other"}
    assert {r["device_mac"] for r in after} == {MAC}


def test_memory_and_title_calls_at_disconnect_are_attributed_in_the_worker_thread(result):
    second = result["second"]
    for purpose in ("memory", "title"):
        (row,) = rows(result, session_id=second["session_id"], purpose=purpose)
        assert (row["device_mac"], row["agent_id"], row["total_tokens"]) == (MAC, "other", 60)
