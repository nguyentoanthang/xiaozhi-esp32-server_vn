"""Single entry point for the server's own non-streaming LLM calls (memory summary, session title).

Every such call states its `purpose`. Phase 4 attaches usage accounting (ai_usage) here, so the
callers do not change. The streaming chat path (ConnectionHandler.chat) is not routed through this
helper yet; "chat" is accepted so it can be added without touching the signature.
"""

from typing import Any

PURPOSES = ("chat", "memory", "title")


def call_llm_no_stream(llm: Any, purpose: str, system_prompt: str, user_prompt: str, **kwargs) -> str:
    """Blocking, non-streaming LLM call. Run it from a worker thread, never from the event loop."""
    if purpose not in PURPOSES:
        raise ValueError(f"Unknown LLM call purpose: {purpose!r}")
    return llm.response_no_stream(system_prompt, user_prompt, **kwargs)
