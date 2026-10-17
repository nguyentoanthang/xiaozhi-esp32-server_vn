"""Work done when a connection ends: close the chat_session row and write its title and summary.

Runs in a worker thread (it calls the LLM synchronously). Failures are logged and never raised.
"""

import json
from typing import Any, List, Optional, Tuple

from core.db import get_database
from core.db.chat_history import mark_session_ended, set_session_title
from core.utils.llm_call import call_llm_no_stream

TAG = __name__

MAX_TRANSCRIPT_CHARS = 6000
MAX_TITLE_CHARS = 80

TITLE_PROMPT = (
    "You name chat sessions. Read the conversation between a user and a voice assistant and reply with "
    'a JSON object only, no other text: {"title": "...", "summary": "..."}. '
    "title: at most 8 words, no quotes or trailing punctuation. "
    "summary: one or two short sentences about what was discussed. "
    "Write both in the language the user spoke."
)


def conversation_text(messages: List[Any]) -> str:
    """User/assistant turns as 'User: ...' / 'Assistant: ...' lines (tool and temporary messages skipped)."""
    lines: List[str] = []
    for msg in messages:
        if getattr(msg, "is_temporary", False) or msg.role not in ("user", "assistant") or not msg.content:
            continue
        content = msg.content
        stripped = content.strip()
        if stripped.startswith("{") and stripped.endswith("}"):
            try:
                data = json.loads(stripped)
                if isinstance(data, dict) and isinstance(data.get("content"), str):
                    content = data["content"]
            except (json.JSONDecodeError, ValueError):
                pass
        lines.append(f"{'User' if msg.role == 'user' else 'Assistant'}: {content}")
    return "\n".join(lines)


def parse_title_reply(reply: str) -> Tuple[Optional[str], Optional[str]]:
    """(title, summary) from the LLM reply. Falls back to the first line as title when it is not JSON."""
    reply = (reply or "").strip()
    if not reply:
        return None, None
    start, end = reply.find("{"), reply.rfind("}")
    if start != -1 and end > start:
        try:
            data = json.loads(reply[start:end + 1])
            if isinstance(data, dict):
                title = str(data.get("title") or "").strip() or None
                summary = str(data.get("summary") or "").strip() or None
                return (title[:MAX_TITLE_CHARS] if title else None), summary
        except (json.JSONDecodeError, ValueError):
            pass
    first = reply.splitlines()[0].strip().strip('"\'`')
    return (first[:MAX_TITLE_CHARS] or None), None


def finish_chat_session(conn: Any, messages: Optional[List[Any]] = None) -> None:
    """Mark the session ended, then ask the LLM for a title and summary and store them.

    Does nothing when chat history is off for this agent (no chat_session row exists then).
    """
    logger = conn.logger.bind(tag=TAG)
    try:
        if not getattr(conn, "db_enabled", True) or getattr(conn, "chat_history_conf", 0) == 0:
            return
        db = get_database()
        mark_session_ended(db, conn.session_id)

        transcript = conversation_text(messages if messages is not None else conn.dialogue.dialogue)
        if "User:" not in transcript or getattr(conn, "llm", None) is None:
            return
        reply = call_llm_no_stream(
            conn.llm, "title", TITLE_PROMPT, transcript[-MAX_TRANSCRIPT_CHARS:],
            max_tokens=200, temperature=0.2,
        )
        title, summary = parse_title_reply(reply)
        if title or summary:
            set_session_title(db, conn.session_id, title, summary)
            logger.info(f"Session {conn.session_id} titled: {title}")
    except Exception as e:
        logger.error(f"Failed to write the session title: {e}")
