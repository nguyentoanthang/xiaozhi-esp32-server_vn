import copy
import hashlib
import threading
import time
from types import SimpleNamespace

from openrouter import OpenRouter
from openrouter.types import UNSET
from openrouter.utils import BackoffStrategy, RetryConfig

from config.logger import setup_logging
from core.providers.llm.base import LLMProviderBase
from core.providers.llm.openrouter import routing
from core.providers.llm.openrouter.usage import (
    CALL_KIND_CHAT,
    CALL_KIND_CHAT_FUNCTIONS,
    UsageRecord,
    emit_usage,
)
from core.utils.util import check_model_key

TAG = __name__
logger = setup_logging()

# The SDK default retries 5xx and connection errors for up to an hour; a voice
# turn must fail fast instead, so retries are always disabled.
RETRY_NONE = RetryConfig("none", BackoffStrategy(0, 0, 1.0, 0), False)

MAX_SESSION_ID_LENGTH = 256
MAX_LOGGED_BODY = 500

# One SDK client per (api_key, base_url, timeout_ms), shared by all provider instances
# so a new connection does not pay a fresh TLS handshake. Never used in a `with` block
# (the SDK's __exit__ closes the underlying http client).
_clients = {}
_clients_lock = threading.Lock()


def _create_client(api_key, base_url, timeout_ms):
    return OpenRouter(
        api_key=api_key,
        server_url=base_url,
        timeout_ms=timeout_ms,
        retry_config=RETRY_NONE,
    )


def _get_client(api_key, base_url, timeout_ms):
    key = (api_key, base_url, timeout_ms)
    with _clients_lock:
        client = _clients.get(key)
        if client is None:
            client = _create_client(api_key, base_url, timeout_ms)
            _clients[key] = client
        return client


def _clean(value):
    """None for None/UNSET (SDK optional fields), else the value."""
    if value is None or value is UNSET:
        return None
    return value


def _short(text, limit=MAX_LOGGED_BODY):
    text = "" if text is None else str(text)
    return text if len(text) <= limit else text[:limit] + "..."


def _strip_think(content, is_active):
    """Drop <think>...</think> blocks; returns (visible_text, still_active).

    Same idea as the openai provider, but text before an opening tag in the same
    chunk is kept. Tags split across chunks are not handled (same as openai).
    """
    visible = ""
    rest = content
    while rest:
        if is_active:
            start = rest.find("<think>")
            if start < 0:
                visible += rest
                break
            visible += rest[:start]
            rest = rest[start + len("<think>"):]
            is_active = False
        else:
            end = rest.find("</think>")
            if end < 0:
                break
            rest = rest[end + len("</think>"):]
            is_active = True
    return visible, is_active


class LLMProvider(LLMProviderBase):
    def __init__(self, config):
        self.model_name = config.get("model_name")
        self.api_key = config.get("api_key") or ""
        self.base_url = routing.parse_base_url(config)
        self.timeout_ms = routing.parse_timeout_ms(config)
        self.sampling_defaults = routing.build_sampling_defaults(config)
        self.request_defaults = routing.build_request_kwargs(config)
        self.routing_snapshot = routing.routing_snapshot(self.request_defaults)

        # Set later by bind_connection()
        self.device_id = None
        self.user_id = None

        model_key_msg = check_model_key("LLM", self.api_key)
        if model_key_msg:
            logger.bind(tag=TAG).error(model_key_msg)
        if not self.api_key:
            logger.bind(tag=TAG).error("OpenRouter api_key is empty")

        self.client = _get_client(self.api_key, self.base_url, self.timeout_ms)
        logger.bind(tag=TAG).debug(
            f"OpenRouter provider init: model={self.model_name}, "
            f"routing={self.routing_snapshot}, sampling={self.sampling_defaults}"
        )

    def bind_connection(self, device_id=None, **_kwargs):
        """Label this instance's calls with the device (called once per connection)."""
        self.device_id = device_id or None
        if self.device_id:
            # Stable pseudonym, the raw MAC is never sent upstream
            self.user_id = hashlib.sha256(str(self.device_id).encode()).hexdigest()[:16]
        else:
            self.user_id = None

    @staticmethod
    def normalize_dialogue(dialogue):
        """Copy messages, filling in missing content (the input list is not modified)."""
        messages = []
        for msg in dialogue:
            msg = dict(msg)
            if "role" in msg and "content" not in msg:
                msg["content"] = ""
            messages.append(msg)
        return messages

    def _build_request(self, session_id, dialogue, functions, kwargs):
        request = copy.deepcopy(self.request_defaults)
        request.update(self.sampling_defaults)

        # Per-call overrides (response_no_stream passes max_tokens / temperature)
        for key in ("temperature", "top_p", "frequency_penalty"):
            value = routing.parse_float(kwargs.get(key))
            if value is not None:
                request[key] = value
        max_tokens = routing.parse_int(kwargs.get("max_tokens"))
        if max_tokens is not None and max_tokens > 0:
            request["max_completion_tokens"] = max_tokens

        request["model"] = self.model_name
        request["messages"] = self.normalize_dialogue(dialogue)
        request["stream"] = True
        request["retries"] = RETRY_NONE
        request["timeout_ms"] = self.timeout_ms
        if session_id:
            # Sticky routing and prompt cache grouping
            request["session_id"] = str(session_id)[:MAX_SESSION_ID_LENGTH]
        if self.user_id:
            request["user"] = self.user_id
        if functions:
            request["tools"] = functions
            request["tool_choice"] = "auto"
        return request

    @staticmethod
    def _absorb_chunk(record, chunk):
        """Copy ids, usage and routing metadata of a chunk into the record.

        Usage is read independently of `choices`: it may arrive in a chunk with none.
        """
        chunk_id = _clean(getattr(chunk, "id", None))
        if chunk_id and not record.generation_id:
            record.generation_id = chunk_id
        model = _clean(getattr(chunk, "model", None))
        if model:
            record.served_model = model

        usage = _clean(getattr(chunk, "usage", None))
        if usage:
            record.prompt_tokens = _clean(getattr(usage, "prompt_tokens", None))
            record.completion_tokens = _clean(getattr(usage, "completion_tokens", None))
            record.total_tokens = _clean(getattr(usage, "total_tokens", None))
            record.cost = _clean(getattr(usage, "cost", None))
            record.is_byok = _clean(getattr(usage, "is_byok", None))
            cost_details = _clean(getattr(usage, "cost_details", None))
            if cost_details:
                record.upstream_inference_cost = _clean(
                    getattr(cost_details, "upstream_inference_cost", None)
                )
            prompt_details = _clean(getattr(usage, "prompt_tokens_details", None))
            if prompt_details:
                record.cached_tokens = _clean(getattr(prompt_details, "cached_tokens", None))
                record.cache_write_tokens = _clean(
                    getattr(prompt_details, "cache_write_tokens", None)
                )
            completion_details = _clean(getattr(usage, "completion_tokens_details", None))
            if completion_details:
                record.reasoning_tokens = _clean(
                    getattr(completion_details, "reasoning_tokens", None)
                )

        metadata = _clean(getattr(chunk, "openrouter_metadata", None))
        if metadata:
            record.attempts = _clean(getattr(metadata, "attempt", None))
            record.generation_time_ms = _clean(getattr(metadata, "generation_time", None))
            provider = None
            endpoints = _clean(getattr(metadata, "endpoints", None))
            for endpoint in _clean(getattr(endpoints, "available", None)) or []:
                if _clean(getattr(endpoint, "selected", None)):
                    provider = _clean(getattr(endpoint, "provider", None))
                    break
            if not provider:
                attempts = _clean(getattr(metadata, "attempts", None)) or []
                if attempts:
                    provider = _clean(getattr(attempts[-1], "provider", None))
            if provider:
                record.selected_provider = provider

    @staticmethod
    def _record_error(record, error_type, status=None, message=None):
        if record.error_type is None:
            record.error_type = error_type
            record.error_status = status
            record.error_message = _short(message)

    def _stream(self, call_kind, session_id, dialogue, functions, kwargs):
        """Shared streaming core.

        Yields `str` for CALL_KIND_CHAT, `(content|None, tool_calls|None)` for
        CALL_KIND_CHAT_FUNCTIONS. The usage record is local to this call and emitted
        exactly once in `finally` (normal end, error, or the generator being closed).
        """
        with_tools = call_kind == CALL_KIND_CHAT_FUNCTIONS
        record = UsageRecord(
            call_kind=call_kind,
            session_id=session_id or "",
            device_id=self.device_id,
            requested_model=self.model_name,
            routing=dict(self.routing_snapshot),
        )
        started = time.monotonic()
        stream = None
        tool_indexes = set()
        is_active = True  # False while inside <think>...</think>
        try:
            request = self._build_request(session_id, dialogue, functions, kwargs)
            stream = self.client.chat.send(**request)

            for chunk in stream:
                self._absorb_chunk(record, chunk)

                error = _clean(getattr(chunk, "error", None))
                if error:
                    code = _clean(getattr(error, "code", None))
                    message = _clean(getattr(error, "message", None))
                    error_meta = _clean(getattr(error, "metadata", None))
                    error_type = _clean(getattr(error_meta, "error_type", None))
                    self._record_error(record, str(error_type or "stream_error"), code, message)
                    logger.bind(tag=TAG).error(
                        f"OpenRouter stream error: code={code}, type={error_type}, "
                        f"message={_short(message)}"
                    )
                    raise RuntimeError(f"OpenRouter stream error {code}: {_short(message)}")

                choices = _clean(getattr(chunk, "choices", None))
                if not choices:
                    continue
                choice = choices[0]

                finish_reason = _clean(getattr(choice, "finish_reason", None))
                if finish_reason:
                    record.finish_reason = str(finish_reason)
                    if record.finish_reason == "error":
                        self._record_error(record, "finish_reason_error")
                        logger.bind(tag=TAG).error("OpenRouter finish_reason=error")
                        raise RuntimeError("OpenRouter finished with finish_reason=error")

                delta = _clean(getattr(choice, "delta", None))
                if not delta:
                    continue

                content = getattr(delta, "content", None)
                if not content or not isinstance(content, str):
                    content = None
                else:
                    content, is_active = _strip_think(content, is_active)
                    if not content:
                        content = None

                fragments = None
                if with_tools:
                    raw_calls = _clean(getattr(delta, "tool_calls", None))
                    if raw_calls:
                        fragments = []
                        for raw in raw_calls:
                            function = _clean(getattr(raw, "function", None))
                            index = _clean(getattr(raw, "index", None))
                            if index is None:
                                index = 0
                            tool_indexes.add(index)
                            fragments.append(
                                SimpleNamespace(
                                    index=index,
                                    id=_clean(getattr(raw, "id", None)) or None,
                                    type="function",
                                    function=SimpleNamespace(
                                        name=_clean(getattr(function, "name", None)) or None,
                                        arguments=_clean(getattr(function, "arguments", None))
                                        or "",
                                    ),
                                )
                            )
                        record.tool_call_count = len(tool_indexes)

                if content is None and not fragments:
                    continue
                if record.ttft_ms is None:
                    record.ttft_ms = int((time.monotonic() - started) * 1000)
                if with_tools:
                    yield content, fragments
                else:
                    yield content
        except GeneratorExit:
            # Consumer stopped early (e.g. the user interrupted the reply)
            record.aborted = True
            raise
        except Exception as e:
            self._handle_exception(record, e)
            raise
        finally:
            try:
                close = getattr(stream, "close", None)
                if close:
                    close()
            except Exception as e:
                logger.bind(tag=TAG).warning(f"closing OpenRouter stream failed: {e}")
            finally:
                record.duration_ms = int((time.monotonic() - started) * 1000)
                emit_usage(record)

    def _handle_exception(self, record, e):
        """Record (and log) a failure; the caller re-raises it unchanged."""
        if record.error_type is not None:
            return  # already recorded and logged (stream error chunk)
        status = getattr(e, "status_code", None)
        if type(e).__name__ == "ResponseValidationError":
            logger.bind(tag=TAG).error(
                f"OpenRouter response validation failed: {_short(getattr(e, 'body', None))}"
            )
        else:
            logger.bind(tag=TAG).error(
                f"OpenRouter request failed: {type(e).__name__} status={status}: {_short(e)}"
            )
        self._record_error(record, type(e).__name__, status, str(e))

    def response(self, session_id, dialogue, **kwargs):
        yield from self._stream(CALL_KIND_CHAT, session_id, dialogue, None, kwargs)

    def response_with_functions(self, session_id, dialogue, functions=None, **kwargs):
        yield from self._stream(
            CALL_KIND_CHAT_FUNCTIONS, session_id, dialogue, functions, kwargs
        )
