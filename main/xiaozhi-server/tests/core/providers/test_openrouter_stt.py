"""Offline tests for core/providers/asr/openrouter_stt.py (fake client, no network, no openrouter package).

The ASR base class is replaced by a tiny stand-in while the module is imported, because the real one
pulls in the whole connection stack (opus, pydub, ...). The base class wiring (attribution binding,
guardrail hook) is covered by tests/core/test_usage_flow.py and test_guardrail_and_history_flow.py.
"""
import asyncio
import base64
import importlib
import sys
import types
import wave
import io

import pytest

from core.db import Database, set_database
from core.db.usage import Attribution, bind_attribution

MODULE = "core.providers.asr.openrouter_stt"
BASE = "core.providers.asr.base"
PCM = b"\x01\x00" * 16000  # one second
ATTR = Attribution(device_mac="aa:bb:cc:00:00:09", agent_id="default", session_id="sess-1")


class _Base:
    """Stand-in for ASRProviderBase."""

    def __init__(self):
        pass

    def _pcm_to_wav(self, pcm):
        buf = io.BytesIO()
        with wave.open(buf, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(16000)
            w.writeframes(pcm)
        return buf.getvalue()


@pytest.fixture(scope="module")
def stt():
    saved = {name: sys.modules.get(name) for name in (BASE, MODULE)}
    stub = types.ModuleType(BASE)
    stub.ASRProviderBase = _Base
    sys.modules[BASE] = stub
    sys.modules.pop(MODULE, None)
    try:
        yield importlib.import_module(MODULE)
    finally:
        for name, mod in saved.items():
            if mod is None:
                sys.modules.pop(name, None)
            else:
                sys.modules[name] = mod


@pytest.fixture
def db(tmp_path):
    database = Database(str(tmp_path / "stt.db"))
    set_database(database)
    yield database
    set_database(None)
    database.close()


class OpenRouterError(Exception):
    """Shape of openrouter.errors.OpenRouterError: message, status_code, body."""

    def __init__(self, status_code, body="{}"):
        super().__init__(f"API error {status_code}")
        self.status_code, self.body = status_code, body


class ReadTimeout(Exception):
    """Stands in for httpx.ReadTimeout (no status_code)."""


class FakeClient:
    def __init__(self, *outcomes):
        self.stt = self
        self.outcomes = list(outcomes)
        self.calls = []

    async def create_transcription_async(self, **kwargs):
        self.calls.append(kwargs)
        outcome = self.outcomes.pop(0) if len(self.outcomes) > 1 else self.outcomes[0]
        if isinstance(outcome, Exception):
            raise outcome
        return outcome


def response(text="hello", **usage):
    return types.SimpleNamespace(text=text, usage=types.SimpleNamespace(**usage) if usage else None)


def provider(stt, client, tmp_path, **config):
    config = {"api_key": "k", "output_dir": str(tmp_path), **config}
    return stt.ASRProvider(config, True, client=client)


def run(p, pcm=PCM):
    artifacts = types.SimpleNamespace(pcm_bytes=pcm, file_path="/tmp/a.wav")
    with bind_attribution(ATTR):
        return asyncio.run(p.speech_to_text([pcm], "sess-1", artifacts))


def usage_rows(db):
    db.flush()
    return db.query_all("SELECT * FROM ai_usage ORDER BY id")


def test_success_sends_headerless_pcm_and_returns_stripped_text(stt, tmp_path, db):
    client = FakeClient(response("  xin chao \n", cost=0.0012, input_tokens=5, output_tokens=2, total_tokens=7, seconds=1.0))
    p = provider(stt, client, tmp_path, model_name="openai/whisper-large-v3", timeout_ms=9000)
    assert run(p) == ("xin chao", "/tmp/a.wav")
    (call,) = client.calls
    assert call["model"] == "openai/whisper-large-v3" and call["timeout_ms"] == 9000
    assert call["input_audio"]["format_"] == "pcm"
    assert base64.b64decode(call["input_audio"]["data"]) == PCM
    assert "language" not in call and call["session_id"] == "sess-1"
    assert call["user"] and "aa:bb" not in call["user"]
    assert p.interface_type.value == "NON_STREAM"


def test_language_is_sent_only_when_set(stt, tmp_path, db):
    client = FakeClient(response())
    run(provider(stt, client, tmp_path, language="vi"))
    run(provider(stt, client, tmp_path, language="auto"))
    assert client.calls[0]["language"] == "vi" and "language" not in client.calls[1]


def test_usage_row_has_cost_tokens_seconds_and_attribution(stt, tmp_path, db):
    client = FakeClient(response("hi", cost=0.0012, input_tokens=5, output_tokens=2, total_tokens=7, seconds=1.5))
    run(provider(stt, client, tmp_path, model_name="m/x"))
    (row,) = usage_rows(db)
    assert (row["kind"], row["purpose"], row["requested_model"]) == ("stt", "stt", "m/x")
    assert (row["session_id"], row["device_mac"], row["agent_id"]) == ("sess-1", "aa:bb:cc:00:00:09", "default")
    assert (row["prompt_tokens"], row["completion_tokens"], row["total_tokens"]) == (5, 2, 7)
    assert row["cost"] == pytest.approx(0.0012) and row["audio_seconds"] == 1.5
    assert row["served_model"] is None and row["provider"] is None and row["generation_id"] is None


def test_missing_usage_falls_back_to_pcm_length_and_null_cost(stt, tmp_path, db):
    run(provider(stt, FakeClient(response("hi")), tmp_path))
    (row,) = usage_rows(db)
    assert row["audio_seconds"] == pytest.approx(len(PCM) / 32000)
    assert row["cost"] is None and row["total_tokens"] is None


def test_empty_text_is_a_normal_empty_transcript(stt, tmp_path, db):
    assert run(provider(stt, FakeClient(response("")), tmp_path))[0] == ""
    assert run(provider(stt, FakeClient(types.SimpleNamespace(text=None, usage=None)), tmp_path))[0] == ""


def test_no_audio_means_no_request(stt, tmp_path, db):
    client = FakeClient(response())
    p = provider(stt, client, tmp_path)
    assert asyncio.run(p.speech_to_text([], "s", None)) == ("", None)
    assert run(p, pcm=b"")[0] == ""
    assert client.calls == []


@pytest.mark.parametrize("error", [
    OpenRouterError(401), OpenRouterError(402), OpenRouterError(429), OpenRouterError(503),
    ReadTimeout("timed out"), ConnectionError("network down"), ValueError("bad response"),
])
def test_errors_give_an_empty_transcript_and_no_row(stt, tmp_path, db, error):
    client = FakeClient(error)
    assert run(provider(stt, client, tmp_path)) == ("", None)
    assert len(client.calls) == 1  # only a rejected audio format is retried
    assert usage_rows(db) == []


def test_rejected_pcm_falls_back_to_wav_and_remembers_it(stt, tmp_path, db):
    client = FakeClient(OpenRouterError(400), response("ok"))
    p = provider(stt, client, tmp_path)
    assert run(p)[0] == "ok"
    first, second = client.calls
    assert first["input_audio"]["format_"] == "pcm"
    wav = base64.b64decode(second["input_audio"]["data"])
    assert second["input_audio"]["format_"] == "wav" and wav[:4] == b"RIFF" and wav.endswith(PCM)
    client.outcomes = [response("again")]
    assert run(p)[0] == "again"
    assert client.calls[2]["input_audio"]["format_"] == "wav"  # no second failed attempt
    assert len(usage_rows(db)) == 2


def test_fallback_can_be_disabled_and_other_statuses_do_not_trigger_it(stt, tmp_path, db):
    client = FakeClient(OpenRouterError(400))
    assert run(provider(stt, client, tmp_path, format_fallback=""))[0] == ""
    assert len(client.calls) == 1
    client = FakeClient(OpenRouterError(401))
    assert run(provider(stt, client, tmp_path))[0] == ""
    assert len(client.calls) == 1


def test_fallback_that_fails_too_gives_an_empty_transcript(stt, tmp_path, db):
    client = FakeClient(OpenRouterError(400), OpenRouterError(422))
    assert run(provider(stt, client, tmp_path)) == ("", None)
    assert len(client.calls) == 2


def test_configured_wav_format_is_sent_as_wav(stt, tmp_path, db):
    client = FakeClient(response())
    run(provider(stt, client, tmp_path, audio_format="wav"))
    assert client.calls[0]["input_audio"]["format_"] == "wav"


def test_config_defaults(stt, tmp_path):
    p = stt.ASRProvider({"output_dir": str(tmp_path)}, True, client=FakeClient(response()))
    assert (p.model_name, p.audio_format, p.timeout_ms, p.language) == ("openai/whisper-large-v3", "pcm", 15000, None)
    assert p.base_url == "https://openrouter.ai/api/v1"
    p = stt.ASRProvider({"output_dir": str(tmp_path), "timeout_ms": "bad"}, True, client=FakeClient(response()))
    assert p.timeout_ms == 15000


def test_missing_openrouter_package_is_a_logged_failure_not_a_crash(stt, tmp_path, db, monkeypatch):
    monkeypatch.setitem(sys.modules, "openrouter", None)  # makes `import openrouter` raise ImportError
    monkeypatch.delitem(sys.modules, "openrouter.utils", raising=False)
    p = stt.ASRProvider({"api_key": "k", "output_dir": str(tmp_path)}, True)  # constructing never imports it
    assert run(p) == ("", None)
    assert usage_rows(db) == []


def test_real_client_is_created_once_with_timeout_and_bounded_retries(stt, tmp_path, db, monkeypatch):
    created = []

    class SdkClient:
        def __init__(self, **kwargs):
            created.append(kwargs)
            self.stt = self
            self.closed = False

        async def create_transcription_async(self, **kwargs):
            return response("sdk")

        async def __aexit__(self, *exc):
            self.closed = True

    class RetryConfig:
        def __init__(self, strategy, backoff, retry_connection_errors):
            self.strategy, self.backoff, self.retry_connection_errors = strategy, backoff, retry_connection_errors

    class BackoffStrategy:
        def __init__(self, initial, maximum, exponent, max_elapsed):
            self.max_elapsed = max_elapsed

    sdk = types.ModuleType("openrouter")
    sdk.OpenRouter = SdkClient
    sdk_utils = types.ModuleType("openrouter.utils")
    sdk_utils.RetryConfig, sdk_utils.BackoffStrategy = RetryConfig, BackoffStrategy
    monkeypatch.setitem(sys.modules, "openrouter", sdk)
    monkeypatch.setitem(sys.modules, "openrouter.utils", sdk_utils)

    p = stt.ASRProvider({"api_key": "secret", "output_dir": str(tmp_path), "timeout_ms": 8000,
                         "base_url": "https://example.test/api/v1", "app_title": "xiaozhi"}, True)
    assert run(p)[0] == "sdk" and run(p)[0] == "sdk"
    (kwargs,) = created  # one long-lived client for the provider instance
    assert (kwargs["api_key"], kwargs["server_url"], kwargs["timeout_ms"]) == ("secret", "https://example.test/api/v1", 8000)
    assert kwargs["x_open_router_title"] == "xiaozhi"
    retry = kwargs["retry_config"]
    assert retry.strategy == "backoff" and retry.backoff.max_elapsed == 3000  # not the SDK's one hour

    client = p._client
    asyncio.run(p.close())
    assert client.closed and p._client is None

    created.clear()
    p = stt.ASRProvider({"api_key": "k", "output_dir": str(tmp_path), "retry_max_elapsed_ms": 0}, True)
    run(p)
    assert created[0]["retry_config"].strategy == "none"
