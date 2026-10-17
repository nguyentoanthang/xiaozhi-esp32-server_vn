"""Single entry point for the server's own non-streaming LLM calls (memory summary, session title, intent).

Every such call states its `purpose` and writes one ai_usage row (core/db/usage.py), attributed to the
device / agent / chat session given by `attribution` or, when omitted, to the ambient one
(`bind_attribution`). The streaming chat path is wrapped separately in ConnectionHandler.chat with the
same recorder.
"""

from typing import Any, Optional

from core.db.usage import Attribution, UsageScope

PURPOSES = ("chat", "memory", "title", "intent")


def call_llm_no_stream(
    llm: Any,
    purpose: str,
    system_prompt: str,
    user_prompt: str,
    attribution: Optional[Attribution] = None,
    **kwargs,
) -> str:
    """Blocking, non-streaming LLM call. Run it from a worker thread, never from the event loop.

    A usage row is written even when the call fails (the exception is re-raised unchanged).
    """
    if purpose not in PURPOSES:
        raise ValueError(f"Unknown LLM call purpose: {purpose!r}")
    scope = UsageScope(purpose, attribution, call_kind="no_stream", llm=llm)
    try:
        with scope.active():
            return llm.response_no_stream(system_prompt, user_prompt, **kwargs)
    finally:
        scope.finish()
