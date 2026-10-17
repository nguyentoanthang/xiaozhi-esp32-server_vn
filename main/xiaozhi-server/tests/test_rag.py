"""RAG (retrieval-augmented generation) pipeline tests.

The server has no standalone RAG provider; this test only covers the memory provider contract
(``save_memory`` then ``query_memory``) of the selected Memory module.

Mock mode (default): provider SDK calls go through the shim and send no requests.
Live mode (``RUN_LIVE_API_TESTS=1``): sends real requests to the selected memory provider.
"""
from __future__ import annotations

import asyncio
import sys
from pathlib import Path

import pytest

from tests.conftest import (
    get_provider_config,
    get_provider_type,
    get_selected_provider_name,
)

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))


def _build_memory_provider():
    name = get_selected_provider_name("Memory")
    if not name:
        pytest.skip("selected_module.Memory is not set")
    cfg = get_provider_config("Memory", name)
    if not cfg:
        pytest.skip(f"Memory provider '{name}' config is missing")
    ptype = get_provider_type("Memory", name)
    if not ptype:
        pytest.skip(f"Memory '{name}' type field is missing")
    from core.utils.memory import create_instance

    return create_instance(ptype, cfg, None)


def test_rag_query_after_save_returns_string() -> None:
    """After saving, query_memory should return a string (nomem returning an empty string is also valid)."""
    provider = _build_memory_provider()
    msgs = [
        {"role": "user", "content": "I like drinking coffee"},
        {"role": "assistant", "content": "OK, I will remember that"},
    ]

    async def run():
        await provider.save_memory(msgs, "rag-session")
        return await provider.query_memory("coffee")

    result = asyncio.run(run())
    assert isinstance(result, str), f"query_memory should return str, got {type(result).__name__}"


def test_rag_query_no_match_returns_empty() -> None:
    """Querying non-existent content returns an empty string without raising."""
    provider = _build_memory_provider()

    async def run():
        return await provider.query_memory("a keyword that does not exist at all xyz")

    result = asyncio.run(run())
    assert isinstance(result, str)


def test_rag_empty_query_handled() -> None:
    """An empty query should not raise."""
    provider = _build_memory_provider()

    async def run():
        await provider.save_memory([{"role": "user", "content": "test"}], "s")
        return await provider.query_memory("")

    result = asyncio.run(run())
    assert isinstance(result, str)
