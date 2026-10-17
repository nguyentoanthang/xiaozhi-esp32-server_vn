import os
import time
import base64
import hashlib

from config.logger import setup_logging
from typing import Optional, Tuple, List
from core.db.usage import KIND_STT, current_attribution, record_usage
from core.providers.asr.base import ASRProviderBase
from core.providers.asr.dto.dto import InterfaceType

TAG = __name__
logger = setup_logging()

DEFAULT_BASE_URL = "https://openrouter.ai/api/v1"
DEFAULT_MODEL = "openai/whisper-large-v3"
DEFAULT_TIMEOUT_MS = 15000
# 16 kHz mono s16le
PCM_BYTES_PER_SECOND = 32000
# Status codes that mean "this model / provider does not accept the audio format"
FORMAT_REJECTED_STATUS = (400, 415, 422)
MAX_LOGGED_BODY = 300


def _short(text, limit=MAX_LOGGED_BODY):
    text = "" if text is None else str(text)
    return text if len(text) <= limit else text[:limit] + "..."


def _to_int(value, default):
    try:
        number = int(float(value))
    except (TypeError, ValueError):
        return default
    return number if number >= 0 else default


class ASRProvider(ASRProviderBase):
    """OpenRouter speech-to-text (POST /audio/transcriptions), non-streaming.

    The whole utterance is sent when the voice stops. Every failure is logged and gives an empty
    transcript, so the conversation just goes on. The `openrouter` package is imported on first use
    (a missing package is one logged error per transcription, not an import error at startup).

    Config: api_key, model_name, language ("" = auto-detect), audio_format ("pcm" or "wav"),
    format_fallback (format to retry with when the first one is rejected, "" = never), timeout_ms,
    retry_max_elapsed_ms (0 = no retry), base_url, http_referer, app_title.
    """

    def __init__(self, config: dict, delete_audio_file: bool, client=None):
        super().__init__()
        self.interface_type = InterfaceType.NON_STREAM
        self.api_key = config.get("api_key") or ""
        self.model_name = config.get("model_name") or DEFAULT_MODEL
        self.base_url = config.get("base_url") or DEFAULT_BASE_URL
        language = str(config.get("language") or "").strip()
        self.language = None if language.lower() in ("", "auto") else language
        self.audio_format = str(config.get("audio_format") or "pcm").strip().lower()
        fallback = config.get("format_fallback", "wav")
        self.format_fallback = str(fallback or "").strip().lower() or None
        self.timeout_ms = _to_int(config.get("timeout_ms"), DEFAULT_TIMEOUT_MS) or DEFAULT_TIMEOUT_MS
        self.retry_max_elapsed_ms = _to_int(config.get("retry_max_elapsed_ms"), 3000)
        self.http_referer = config.get("http_referer") or None
        self.app_title = config.get("app_title") or None
        self.output_dir = config.get("output_dir") or "tmp/"
        self.delete_audio_file = delete_audio_file
        os.makedirs(self.output_dir, exist_ok=True)

        # One long-lived client per provider instance, created on first use (or injected, for tests)
        self._client = client
        self._owns_client = client is None
        self._retries = None
        if not self.api_key:
            logger.bind(tag=TAG).error("OpenRouter STT api_key is empty")

    # ------------------------------------------------------------------ client

    def _ensure_client(self):
        if self._client is not None:
            return self._client
        from openrouter import OpenRouter  # lazy: the package may be missing
        from openrouter.utils import BackoffStrategy, RetryConfig

        # The SDK default retries 5xx and connection errors for up to an hour: far too long for a
        # voice turn. Use a short bounded backoff (or none).
        if self.retry_max_elapsed_ms > 0:
            self._retries = RetryConfig("backoff", BackoffStrategy(300, 1000, 1.5, self.retry_max_elapsed_ms), True)
        else:
            self._retries = RetryConfig("none", BackoffStrategy(0, 0, 1.0, 0), False)
        kwargs = {}
        if self.http_referer:
            kwargs["http_referer"] = self.http_referer
        if self.app_title:
            kwargs["x_open_router_title"] = self.app_title
        self._client = OpenRouter(
            api_key=self.api_key,
            server_url=self.base_url,
            timeout_ms=self.timeout_ms,
            retry_config=self._retries,
            **kwargs,
        )
        return self._client

    async def close(self):
        client, self._client = self._client, None
        if client is not None and self._owns_client:
            try:
                await client.__aexit__(None, None, None)
            except Exception as e:
                logger.bind(tag=TAG).warning(f"Closing the OpenRouter STT client failed: {e}")

    # ----------------------------------------------------------------- request

    async def _transcribe(self, client, audio_bytes: bytes, audio_format: str, session_id, user):
        request = {
            "input_audio": {"data": base64.b64encode(audio_bytes).decode("ascii"), "format_": audio_format},
            "model": self.model_name,
            "timeout_ms": self.timeout_ms,
        }
        if self._retries is not None:
            request["retries"] = self._retries
        if self.language:
            request["language"] = self.language
        if session_id:
            request["session_id"] = str(session_id)[:256]
        if user:
            request["user"] = user
        return await client.stt.create_transcription_async(**request)

    async def speech_to_text(
        self, opus_data: List[bytes], session_id: str, artifacts=None
    ) -> Tuple[Optional[str], Optional[str]]:
        if artifacts is None or not artifacts.pcm_bytes:
            return "", None
        pcm = artifacts.pcm_bytes
        attribution = current_attribution()
        # Stable pseudonym of the device, the raw MAC is never sent upstream
        user = (
            hashlib.sha256(attribution.device_mac.encode()).hexdigest()[:16]
            if attribution and attribution.device_mac
            else None
        )
        started = time.monotonic()
        try:
            client = self._ensure_client()
            audio_format = self.audio_format
            try:
                response = await self._transcribe(client, self._encode(pcm, audio_format), audio_format, session_id, user)
            except Exception as e:
                status = getattr(e, "status_code", None)
                if not (self.format_fallback and audio_format != self.format_fallback and status in FORMAT_REJECTED_STATUS):
                    raise
                logger.bind(tag=TAG).warning(
                    f"OpenRouter STT rejected format {audio_format!r} (status {status}), retrying with {self.format_fallback!r}"
                )
                audio_format = self.format_fallback
                response = await self._transcribe(client, self._encode(pcm, audio_format), audio_format, session_id, user)
                self.audio_format = audio_format  # keep what works, so later turns skip the failed attempt
        except Exception as e:
            self._log_failure(e)
            return "", None

        text = (getattr(response, "text", None) or "").strip()
        duration_ms = int((time.monotonic() - started) * 1000)
        logger.bind(tag=TAG).debug(f"Speech recognition took: {duration_ms / 1000:.3f}s | result: {text}")
        self._record_usage(response, len(pcm), duration_ms, attribution)
        return text, artifacts.file_path

    def _encode(self, pcm: bytes, audio_format: str) -> bytes:
        """pcm is sent as is (headerless s16le mono 16 kHz); anything else is sent as a WAV file."""
        return pcm if audio_format == "pcm" else self._pcm_to_wav(pcm)

    @staticmethod
    def _log_failure(e: Exception):
        status = getattr(e, "status_code", None)
        body = getattr(e, "body", None)
        detail = f" status={status}" if status is not None else ""
        if body:
            detail += f" body={_short(body)}"
        logger.bind(tag=TAG).error(f"OpenRouter STT failed: {type(e).__name__}{detail}: {_short(e)}")

    def _record_usage(self, response, pcm_len: int, duration_ms: int, attribution):
        """One ai_usage row (kind stt). The STT response has no generation id, served model or provider."""
        usage = getattr(response, "usage", None)
        seconds = getattr(usage, "seconds", None)
        record_usage(
            kind=KIND_STT,
            purpose="stt",
            attribution=attribution,
            requested_model=self.model_name,
            prompt_tokens=getattr(usage, "input_tokens", None),
            completion_tokens=getattr(usage, "output_tokens", None),
            total_tokens=getattr(usage, "total_tokens", None),
            cost=getattr(usage, "cost", None),
            audio_seconds=seconds if seconds is not None else pcm_len / PCM_BYTES_PER_SECOND,
            duration_ms=duration_ms,
        )
