"""Per-call usage records and sinks for the OpenRouter provider.

Every LLM call builds its own local UsageRecord and emits it exactly once.
Sinks are plain callables; the default sink writes one INFO log line.
Prompt and response text are never part of a record.
"""

import json
import threading
import time
import uuid
from dataclasses import asdict, dataclass, field
from typing import Any, Callable, Dict, List, Optional

from config.logger import setup_logging

TAG = __name__
logger = setup_logging()

USAGE_LOG_TAG = "llm_usage"

CALL_KIND_CHAT = "chat"
CALL_KIND_CHAT_FUNCTIONS = "chat_functions"
CALL_KIND_NO_STREAM = "no_stream"


@dataclass
class UsageRecord:
    record_id: str = field(default_factory=lambda: uuid.uuid4().hex)
    started_at: float = field(default_factory=time.time)
    ttft_ms: Optional[int] = None
    duration_ms: Optional[int] = None
    call_kind: str = CALL_KIND_CHAT

    # attribution keys
    session_id: str = ""
    device_id: Optional[str] = None

    requested_model: Optional[str] = None
    served_model: Optional[str] = None
    generation_id: Optional[str] = None

    # from openrouter_metadata when record_routing is enabled
    selected_provider: Optional[str] = None
    attempts: Optional[int] = None
    generation_time_ms: Optional[int] = None

    prompt_tokens: Optional[int] = None
    completion_tokens: Optional[int] = None
    total_tokens: Optional[int] = None
    cached_tokens: Optional[int] = None
    cache_write_tokens: Optional[int] = None
    reasoning_tokens: Optional[int] = None

    cost: Optional[float] = None
    upstream_inference_cost: Optional[float] = None
    is_byok: Optional[bool] = None

    finish_reason: Optional[str] = None
    tool_call_count: int = 0
    aborted: bool = False

    error_type: Optional[str] = None
    error_status: Optional[int] = None
    error_message: Optional[str] = None

    routing: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


UsageSink = Callable[[UsageRecord], None]

_sinks: List[UsageSink] = []
_sinks_lock = threading.Lock()


def register_usage_sink(sink: UsageSink) -> None:
    """Add a sink called with every finished UsageRecord (idempotent)."""
    with _sinks_lock:
        if sink not in _sinks:
            _sinks.append(sink)


def unregister_usage_sink(sink: UsageSink) -> None:
    with _sinks_lock:
        if sink in _sinks:
            _sinks.remove(sink)


def log_usage_sink(record: UsageRecord) -> None:
    """Default sink: one INFO line, JSON payload, no prompt/response text."""
    payload = {
        k: v for k, v in record.to_dict().items() if v is not None and v != {}
    }
    logger.bind(tag=TAG).info(
        f"{USAGE_LOG_TAG} {json.dumps(payload, ensure_ascii=False, default=str)}"
    )


# The log sink is always present; extra sinks are added with register_usage_sink
register_usage_sink(log_usage_sink)


def emit_usage(record: UsageRecord) -> None:
    """Pass the record to every sink. A failing sink never affects the others or the caller."""
    with _sinks_lock:
        sinks = list(_sinks)
    for sink in sinks:
        try:
            sink(record)
        except Exception as e:
            logger.bind(tag=TAG).warning(f"usage sink failed: {type(e).__name__}: {e}")
