"""ai_usage recorder: one row per LLM / STT call, written through the single DB writer thread.

Attribution (device, agent, session) is copied into the row at call time, so history survives a
later re-assignment of the device to another agent. Standard library only (like the rest of core/db).

Two ways to attribute a call:
- explicit: pass an `Attribution` (call_llm_no_stream(..., attribution=...), conn.usage_attribution());
- ambient: `bind_attribution()` sets a contextvar that `current_attribution()` returns. It follows
  asyncio tasks and asyncio.to_thread; a thread started by hand must bind it itself.

LLM providers report usage by calling `emit_usage()` of core/providers/llm/openrouter/usage.py (only the
OpenRouter provider does today). A bridge sink, registered by `install_llm_usage_sink()`, hands those
records to the `UsageScope` that is active in the same context. A call whose provider reports nothing
still gets a row, with NULL tokens and cost, so the number of calls stays right.

A failure here (no database, closed writer, bad record) is logged and never reaches the conversation.
"""

import contextlib
import contextvars
import time
import uuid
from dataclasses import dataclass
from typing import Any, Iterator, Optional

from core.db.database import Database, _log, get_database, utcnow_iso

KIND_LLM = "llm"
KIND_STT = "stt"
KIND_TTS = "tts"

INSERT_SQL = (
    "INSERT OR IGNORE INTO ai_usage(record_id, created_at, kind, session_id, device_mac, agent_id, purpose, "
    "call_kind, requested_model, served_model, provider, generation_id, prompt_tokens, completion_tokens, "
    "total_tokens, cached_tokens, cost, upstream_cost, is_byok, audio_seconds, ttft_ms, duration_ms) "
    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
)


@dataclass(frozen=True)
class Attribution:
    device_mac: Optional[str] = None
    agent_id: Optional[str] = None
    session_id: Optional[str] = None


_attribution: contextvars.ContextVar = contextvars.ContextVar("usage_attribution", default=None)
_scope: contextvars.ContextVar = contextvars.ContextVar("usage_scope", default=None)


def attribution_from_conn(conn: Any) -> Attribution:
    """Attribution of a ConnectionHandler (duck-typed): lower-case MAC, agent, current chat session."""
    config = getattr(conn, "config", None)
    default_agent = config.get("default_agent_id") if isinstance(config, dict) else None
    mac = (getattr(conn, "device_id", None) or "").strip().lower()
    return Attribution(
        device_mac=mac or None,
        agent_id=getattr(conn, "agent_id", None) or default_agent or None,
        session_id=getattr(conn, "session_id", None) or None,
    )


def current_attribution() -> Optional[Attribution]:
    return _attribution.get()


@contextlib.contextmanager
def bind_attribution(attribution: Optional[Attribution]) -> Iterator[None]:
    """Make `attribution` the ambient one for the current context (task / thread) inside the block."""
    token = _attribution.set(attribution)
    try:
        yield
    finally:
        _attribution.reset(token)


def _to_float(value: Any) -> Optional[float]:
    try:
        return None if value is None else float(value)
    except (TypeError, ValueError):
        return None


def _to_int(value: Any) -> Optional[int]:
    try:
        return None if value is None or isinstance(value, bool) else int(value)
    except (TypeError, ValueError):
        return None


def record_usage(
    *,
    kind: str = KIND_LLM,
    purpose: Optional[str] = None,
    attribution: Optional[Attribution] = None,
    call_kind: Optional[str] = None,
    requested_model: Optional[str] = None,
    served_model: Optional[str] = None,
    provider: Optional[str] = None,
    generation_id: Optional[str] = None,
    prompt_tokens: Optional[int] = None,
    completion_tokens: Optional[int] = None,
    total_tokens: Optional[int] = None,
    cached_tokens: Optional[int] = None,
    cost: Optional[float] = None,
    upstream_cost: Optional[float] = None,
    is_byok: Optional[bool] = None,
    audio_seconds: Optional[float] = None,
    ttft_ms: Optional[int] = None,
    duration_ms: Optional[int] = None,
    record_id: Optional[str] = None,
    db: Optional[Database] = None,
) -> bool:
    """Queue one ai_usage row on the writer thread (never blocks, never raises). True when queued.

    `attribution` defaults to the ambient one. `cost` is stored only when the provider reported it.
    """
    try:
        attr = attribution or current_attribution() or Attribution()
        db = db or get_database()
        db.write(
            INSERT_SQL,
            (
                record_id or uuid.uuid4().hex, utcnow_iso(), kind, attr.session_id, attr.device_mac,
                attr.agent_id, purpose, call_kind, requested_model, served_model, provider, generation_id,
                _to_int(prompt_tokens), _to_int(completion_tokens), _to_int(total_tokens),
                _to_int(cached_tokens), _to_float(cost), _to_float(upstream_cost),
                None if is_byok is None else int(bool(is_byok)), _to_float(audio_seconds),
                _to_int(ttft_ms), _to_int(duration_ms),
            ),
        )  # the Future is dropped on purpose: the writer logs a failed insert
        return True
    except Exception as e:
        _log("error", f"Usage row not recorded: {e!r}")
        return False


def _llm_type(llm: Any) -> Optional[str]:
    """Provider type from the module path (core.providers.llm.<type>.<file>); None for anything else."""
    parts = type(llm).__module__.split(".") if llm is not None else []
    return parts[3] if len(parts) > 3 and parts[:3] == ["core", "providers", "llm"] else None


class UsageScope:
    """Collects the usage reported while one LLM call runs, then writes ONE row in `finish()`.

    Use `active()` around every step of the call (providers emit their record inside it), or wrap a
    generator with `track_stream()`. `finish()` is idempotent.
    """

    def __init__(
        self,
        purpose: str,
        attribution: Optional[Attribution] = None,
        *,
        call_kind: Optional[str] = None,
        llm: Any = None,
        provider: Optional[str] = None,
        db: Optional[Database] = None,
    ):
        self.purpose = purpose
        self.attribution = attribution or current_attribution() or Attribution()
        self.call_kind = call_kind
        self.requested_model = getattr(llm, "model_name", None)
        self.provider = provider or _llm_type(llm)  # used when the provider does not report one
        self.db = db
        install_llm_usage_sink()
        self.record: Any = None  # last record emitted by the provider
        self._started = time.monotonic()
        self._finished = False

    @contextlib.contextmanager
    def active(self) -> Iterator["UsageScope"]:
        token = _scope.set(self)
        try:
            yield self
        finally:
            _scope.reset(token)

    def absorb(self, record: Any) -> None:
        self.record = record

    def finish(self) -> bool:
        if self._finished:
            return False
        self._finished = True
        r = self.record
        duration = getattr(r, "duration_ms", None)
        return record_usage(
            kind=KIND_LLM,
            purpose=self.purpose,
            attribution=self.attribution,
            call_kind=getattr(r, "call_kind", None) or self.call_kind,
            requested_model=getattr(r, "requested_model", None) or self.requested_model,
            served_model=getattr(r, "served_model", None),
            provider=getattr(r, "selected_provider", None) or self.provider,
            generation_id=getattr(r, "generation_id", None),
            prompt_tokens=getattr(r, "prompt_tokens", None),
            completion_tokens=getattr(r, "completion_tokens", None),
            total_tokens=getattr(r, "total_tokens", None),
            cached_tokens=getattr(r, "cached_tokens", None),
            cost=getattr(r, "cost", None),
            upstream_cost=getattr(r, "upstream_inference_cost", None),
            is_byok=getattr(r, "is_byok", None),
            ttft_ms=getattr(r, "ttft_ms", None),
            duration_ms=duration if duration is not None else int((time.monotonic() - self._started) * 1000),
            db=self.db,
        )


def track_stream(stream: Any, scope: UsageScope) -> Iterator[Any]:
    """Iterate `stream` (a provider generator) with `scope` active; write the row when it ends.

    The inner generator is closed here, so its own `finally` (which emits the provider's record) runs
    inside the scope even when the consumer stops early. Everything yielded is passed through.
    """
    iterator = iter(stream)
    try:
        while True:
            with scope.active():
                try:
                    item = next(iterator)
                except StopIteration:
                    return
            yield item
    finally:
        with scope.active():
            close = getattr(iterator, "close", None)
            if close:
                try:
                    close()
                except Exception as e:
                    _log("warning", f"closing the LLM stream failed: {e!r}")
        scope.finish()


def _bridge_sink(record: Any) -> None:
    """Sink for the OpenRouter provider's emit_usage(): hand the record to the active scope."""
    scope = _scope.get()
    if scope is not None:
        scope.absorb(record)


_sink_installed = False


def install_llm_usage_sink() -> bool:
    """Register the bridge sink with the OpenRouter usage module (once; False if it cannot be imported)."""
    global _sink_installed
    if _sink_installed:
        return True
    try:
        from core.providers.llm.openrouter.usage import register_usage_sink

        register_usage_sink(_bridge_sink)
        _sink_installed = True
    except Exception as e:
        _log("warning", f"LLM usage sink not installed: {e!r}")
    return _sink_installed
