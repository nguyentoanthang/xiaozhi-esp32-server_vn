"""LLM pipeline tests.

Mock mode (default): builds a real provider from the config in data/.config.yaml;
network calls go through the shim injected by conftest -- no requests are sent.
Live mode (``RUN_LIVE_API_TESTS=1``): calls the real LLM provider, following the
ThreadPoolExecutor + 10s timeout pattern of ``performance_tester_llm.py``.

Interface contract (core/providers/llm/base.py):
    response(session_id, dialogue) -> Iterator[str], a synchronous streaming generator
    response_no_stream(system_prompt, user_content) -> str

Special handling:
- CozeLLM checks bot_id / user_id rather than api_key
- Ollama needs model_name + a locally available service
- placeholder detection ("your_" / "placeholder" / "xxx" / "sk-xxx")
- Because the LLM is a synchronous generator, asyncio.wait_for cannot be used directly -> use a thread pool
"""
from __future__ import annotations

import concurrent.futures
import sys
from pathlib import Path

import pytest

from tests.conftest import (
    CONFIG,
    LIVE_API_TESTS,
    get_provider_config,
    get_provider_type,
    get_selected_provider_name,
    has_real_key,
)

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))


def _build_provider():
    name = get_selected_provider_name("LLM")
    if not name:
        pytest.skip("selected_module.LLM is not set")
    cfg = get_provider_config("LLM", name)
    if not cfg:
        pytest.skip(f"LLM provider '{name}' config is missing")

    # In any mode: key is a placeholder -> skip. Real requests need a real key; in mock mode
    # running without a real key would also hit the real SDK network stack (openai/edge_tts) and fail.
    if name == "CozeLLM":
        if any(x in cfg.get("bot_id", "") for x in ["your_"]) or any(
            x in cfg.get("user_id", "") for x in ["your_"]
        ):
            pytest.skip("LLM 'CozeLLM' bot_id/user_id is not configured")
    elif name == "Ollama":
        if not cfg.get("model_name"):
            pytest.skip("LLM 'Ollama' model_name is not configured")
    elif not has_real_key(cfg, "api_key"):
        if LIVE_API_TESTS:
            pytest.skip(f"LLM '{name}' api_key is not configured")
        else:
            pytest.skip(
                f"LLM '{name}' api_key is a placeholder (mock mode does not send real requests). "
                "For real requests: export RUN_LIVE_API_TESTS=1 and fill in a real key, then re-run."
            )

    ptype = get_provider_type("LLM", name)
    if not ptype:
        pytest.skip(f"LLM '{name}' type field is missing")
    from core.utils.llm import create_instance

    return create_instance(ptype, cfg)


def _collect_with_timeout(provider, session_id: str, dialogue, timeout: float = 10.0):
    """Call the synchronous generator response() via a thread pool with a 10s timeout."""
    with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
        future = executor.submit(lambda: list(provider.response(session_id, dialogue)))
        return future.result(timeout=timeout)


def test_llm_response_streams_non_empty() -> None:
    """response(session_id, dialogue) should produce a non-empty token stream."""
    provider = _build_provider()
    dialogue = [
        {"role": "system", "content": "You are an assistant"},
        {"role": "user", "content": "Say hi in one sentence"},
    ]
    chunks = _collect_with_timeout(provider, "test-session", dialogue, timeout=10.0)

    full = "".join(chunks).strip()
    assert isinstance(full, str), f"LLM chunks join should be str, got {type(full).__name__}"
    assert full, f"LLM returned an empty response (provider={type(provider).__name__})"


def test_llm_response_no_stream_returns_string() -> None:
    """response_no_stream should return a non-empty string."""
    provider = _build_provider()
    text = provider.response_no_stream("You are an assistant", "Introduce Beijing").strip()

    assert isinstance(text, str), f"response_no_stream should return str, got {type(text).__name__}"
    assert text, "response_no_stream returned an empty string"


def test_llm_dialogue_min_length_one_user() -> None:
    """A dialogue with at least one user message should work."""
    provider = _build_provider()
    dialogue = [{"role": "user", "content": "ping"}]
    chunks = _collect_with_timeout(provider, "s1", dialogue, timeout=10.0)

    assert "".join(chunks).strip(), "A single user message should return content"
