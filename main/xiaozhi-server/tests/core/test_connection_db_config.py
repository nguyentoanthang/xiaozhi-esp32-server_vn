"""ConnectionHandler config initialisation against a seeded SQLite database (no Java API).

Runs tests/core/_connection_smoke.py in a subprocess: it stubs the third-party packages that may
be missing in a dev environment (pydub, websockets, ...) so the stubs never leak into other tests.
"""
import json
import subprocess
import sys
from pathlib import Path

import pytest

HELPER = Path(__file__).with_name("_connection_smoke.py")


@pytest.fixture(scope="module")
def result():
    r = subprocess.run([sys.executable, str(HELPER)], capture_output=True, text=True, timeout=120)
    lines = [l for l in r.stdout.splitlines() if l.startswith("RESULT ")]
    assert lines, f"helper failed:\n{r.stdout[-2000:]}\n{r.stderr[-3000:]}"
    return json.loads(lines[-1][len("RESULT "):])


def test_unknown_device_is_registered_and_gets_the_agent_config(result):
    r = result["registered"]
    assert r["ok"] is True and r["ready"] is True and r["refused"] is False
    assert r["agent_id"] == "default"
    assert r["device_row"] == ["default", True]  # row created, last_connected_at written
    assert r["selected_module"]["LLM"] == "LLM_OpenRouter"
    assert r["selected_module"]["Memory"] == "Memory_mem_local_short"
    assert r["prompt_set"] and r["chat_history_conf"] == 2
    assert r["plugins"].startswith("your_")  # global plugins.* settings survive when the agent has none
    assert r["messages"] == []


def test_summary_memory_is_loaded_from_the_memory_table(result):
    assert result["summary_memory"] == "likes tea"


def test_refused_device_gets_a_message_and_is_closed(result):
    r = result["refused"]
    assert r["ok"] is False and r["refused"] is True and r["ready"] is False
    assert r["device_rows"] == 0
    assert r["messages"][0]["content"]["action"] == "device_refused"
    assert {"closed": 1008} in r["messages"]
