"""Guardrails and chat history wired into the connection, ASR and TTS code (no network).

Runs tests/core/_guardrail_flow_smoke.py in a subprocess so its stubs of missing third-party
packages never leak into the other tests.
"""
import json
import subprocess
import sys
from pathlib import Path

import pytest

HELPER = Path(__file__).with_name("_guardrail_flow_smoke.py")
RAW = "call Linh at 0912 345 678 or mail linh@example.com"
MASKED = "call [NAME_1] at [PHONE_1] or mail [EMAIL_1]"


@pytest.fixture(scope="module")
def result():
    r = subprocess.run([sys.executable, str(HELPER)], capture_output=True, text=True, timeout=180)
    lines = [l for l in r.stdout.splitlines() if l.startswith("RESULT ")]
    assert lines, f"helper failed:\n{r.stdout[-2000:]}\n{r.stderr[-3000:]}"
    return json.loads(lines[-1][len("RESULT "):])


def test_asr_text_is_masked_before_log_llm_and_report(result):
    m = result["masked"]
    assert m["chat"] == [MASKED]  # what reaches the LLM entry point
    assert m["reported"] == [MASKED]  # what reaches the chat history queue
    assert m["logs"] == [f"Recognized text: {MASKED}"]
    assert m["logs_have_raw"] is False


def test_json_form_masks_only_the_content_field(result):
    assert json.loads(result["masked"]["dict_chat"][0]) == {"content": MASKED, "language": "en"}


def test_names_and_settings_are_read_from_the_database_per_connection(result):
    m = result["masked"]
    assert "enabled" in m["names_loaded"]
    assert m["disabled_name_not_masked"] == ["Hello, ask Hidden"]  # guardrail_name.enabled = 0
    assert result["switch_off_chat"] == ["call Linh at 0912 345 678 or mail linh@example.com"]


def test_placeholders_are_restored_for_the_tts_only_when_enabled(result):
    assert result["tts_restore_off"] == "Calling [NAME_1]"
    assert result["tts_restore_on"] == "Calling Linh on 0912 345 678"


def test_disconnect_stores_messages_title_summary_and_memory(result):
    d = result["disconnect"]
    # Both messages were drained from the report queue before the connection was closed, in order,
    # with audio; the stored text is the masked text
    assert d["messages"] == [[1, MASKED, True], [2, "Calling [NAME_1]", True]]
    assert d["session"]["title"] == "Call Linh" and d["session"]["summary"] == "User asked to call."
    assert d["session"]["ended_at"] and d["session"]["device_mac"] == "aa:bb:cc:00:00:01"
    # Title and memory saw the masked conversation and not the temporary few-shot messages
    assert d["title_prompt"] == f"User: {MASKED}\nAssistant: Calling [NAME_1]"
    assert d["memory_seen"] == [MASKED, "Calling [NAME_1]"]
    assert json.loads(d["memory_row"]) == d["memory_seen"]


def test_history_off_starts_no_report_thread_and_stores_nothing(result):
    assert result["history_off"] == {"report_thread": False, "sessions_for_it": 0}


@pytest.mark.parametrize("path", ["asr", "detect"])
def test_device_subtitle_shows_the_original_text_and_everything_else_the_masked_one(result, path):
    r = result["subtitle"][path]
    assert r["stt"] == [RAW]  # the device sees what the user said
    assert r["llm"] == [MASKED]  # the LLM entry, the report queue and the dialogue never see it
    assert r["reported"] == [MASKED]
    assert r["logs_have_raw"] is False


def test_subtitle_for_the_json_asr_form_shows_the_original_content(result):
    r = result["subtitle"]["asr_dict"]
    assert json.loads(r["llm"][0]) == {"content": MASKED, "language": "en"}
    # send_stt_message pulls the `content` field out of the JSON form for the subtitle
    assert [json.loads(t)["content"] for t in r["stt"]] == [RAW]
    assert r["logs_have_raw"] is False


def test_subtitle_does_not_break_the_placeholder_numbering_used_for_restore(result):
    assert result["subtitle"]["restore_state"] == ["[EMAIL_1]", "[NAME_1]", "[PHONE_1]"]
