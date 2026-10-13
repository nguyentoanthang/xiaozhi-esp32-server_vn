"""Live acceptance tests (L1-L10 of docs/openrouter-llm-provider-plan.md, section 8.2) for the
OpenRouter LLM provider. These tests call the REAL OpenRouter API and cost a few cents at most
(every prompt is tiny and max_tokens is capped; the largest items are L8 with max_tokens=300 that is
aborted after 3 chunks, and L9 with a ~1.3k token system prompt sent twice).

They are skipped (never failed, never any network traffic) unless BOTH hold:
  1. RUN_LIVE_API_TESTS=1
  2. an OpenRouter key is available: env OPENROUTER_API_KEY, or (fallback) an entry
     with ``type: openrouter`` and a non-placeholder ``api_key`` under ``LLM:`` in
     data/.config.yaml (or the file named by PYTEST_CONFIG_FILE).

How to run (PowerShell, from main/xiaozhi-server, venv active)::

    $env:RUN_LIVE_API_TESTS = "1"
    $env:OPENROUTER_API_KEY = "sk-or-v1-..."
    pytest tests/core/providers/test_openrouter_live.py -s -q --noconftest -p no:cacheprovider

Why ``--noconftest``: tests/conftest.py, in RUN_LIVE_API_TESTS=1 mode, aborts the whole session
(sys.exit 2) if data/.config.yaml is a full-mode config (manager-api url + secret) and
(sys.exit 3) unless ASR/LLM/TTS/Memory/VAD are all configured with real keys. Without
RUN_LIVE_API_TESTS=1 it replaces httpx.Client with a fake that always raises ConnectError, which
would break the SDK. This module only needs the real httpx, so it gates itself and does not need
conftest. (It also works with the conftest if you do satisfy its live-mode requirements.)

Select one test: ``-k L3`` (ids are test_L1_..., test_L2_..., ... test_L10_...; use ``-k L10`` for
the record_routing gate, ``-k "L1_"`` to avoid also matching L10).

Note: ``record_routing`` is OFF by default in the provider. L1-L9 run with it off except where a test
sets it explicitly (L4 compares both, L10 turns it on). L10 tells you whether it is safe to enable.

Environment variables (all optional except the key)::

    OPENROUTER_API_KEY        key (never written to the results file or printed)
    OPENROUTER_MODEL          default openai/gpt-4o-mini
    OPENROUTER_TOOL_MODEL     model for L3 (default: OPENROUTER_MODEL)
    OPENROUTER_FALLBACK_MODELS  comma list used by L7 (default openai/gpt-4.1-mini; override if unavailable)
    OPENROUTER_BASE_URL       default https://openrouter.ai/api/v1
    OPENROUTER_EXTRA_CONFIG   JSON object merged into every provider config, e.g. '{"data_collection":"deny"}'
    OPENROUTER_L4_RUNS        runs per variant in L4 (default 3)
    OPENROUTER_LIVE_RESULTS   results JSON path (default main/xiaozhi-server/tmp/openrouter_live_results.json,
                              the tmp/ folder is git-ignored)

Every test records a structured finding; ONE JSON file is written at session end and a short table
is printed. The JSON holds no API key and no prompt text. The tests assert only things that must hold
by design (record emitted once, aborted flag, errors surface ...); numbers such as TTFT or cost
are recorded, not asserted.
"""
from __future__ import annotations

import json
import os
import sys
import time
import uuid
from pathlib import Path
from types import SimpleNamespace

import pytest

ROOT = Path(__file__).resolve().parents[3]  # main/xiaozhi-server
DEFAULT_MODEL = "openai/gpt-4o-mini"
DEFAULT_FALLBACK = "openai/gpt-4.1-mini"
INVALID_MODEL = "openrouter-live-test/this-model-does-not-exist"
# Deliberately invalid key (L6). Built at runtime so no key-shaped literal is committed
# (GitHub push protection flags sk-or-v1-<64 chars> even when it is all zeros).
FAKE_KEY = "-".join(["sk", "or", "v1", "0" * 64])
RESULTS_ENV = "OPENROUTER_LIVE_RESULTS"
MAX_TEXT = 300

pytestmark = pytest.mark.filterwarnings("ignore")


# ------------------------------------------------------------------ gating / key lookup
def _looks_placeholder(value) -> bool:
    text = str(value or "").strip().lower()
    return (not text or text == "none" or "你" in text or "placeholder" in text
            or "your_api_key" in text or text.startswith("xxx") or text.startswith("sk-xxx"))


def _resolve_key():
    """(key, source) or (None, reason). Env first, then data/.config.yaml LLM entry of type openrouter."""
    key = os.environ.get("OPENROUTER_API_KEY", "").strip()
    if key:
        return key, "env OPENROUTER_API_KEY"
    path = Path(os.environ["PYTEST_CONFIG_FILE"]) if os.environ.get("PYTEST_CONFIG_FILE") \
        else ROOT / "data" / ".config.yaml"
    try:
        import yaml

        cfg = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    except Exception:
        return None, f"OPENROUTER_API_KEY not set and {path} not readable"
    for name, entry in (cfg.get("LLM") or {}).items():
        if (isinstance(entry, dict) and str(entry.get("type", "")).lower() == "openrouter"
                and not _looks_placeholder(entry.get("api_key"))):
            return str(entry["api_key"]).strip(), f"{path.name} LLM.{name}"
    return None, f"OPENROUTER_API_KEY not set and no usable 'type: openrouter' LLM entry in {path}"


def _bootstrap():
    """Make the provider importable without data/.config.yaml and without touching manager-api.

    The provider modules call setup_logging() at import time, which needs a config with a `log`
    section. When tests/conftest.py is not active we seed the config cache with a minimal one
    (logs go to tmp/openrouter_live.log + console), so a full-mode data/.config.yaml is never read.
    """
    if str(ROOT) not in sys.path:
        sys.path.insert(0, str(ROOT))
    try:
        import opuslib_next  # noqa: F401
    except Exception:
        # Same stub as tests/conftest.py: the import chain needs the module, this test never decodes audio
        import types

        stub = types.ModuleType("opuslib_next")
        stub.Encoder = type("Encoder", (), {"__init__": lambda *a, **kw: None})
        stub.Decoder = type("Decoder", (), {"__init__": lambda *a, **kw: None})
        stub.APPLICATION_AUDIO = 0
        stub.OpusError = type("OpusError", (Exception,), {})
        stub.constants = types.SimpleNamespace()
        sys.modules["opuslib_next"] = stub
        for sub in ("api", "exceptions"):
            sys.modules[f"opuslib_next.{sub}"] = types.ModuleType(f"opuslib_next.{sub}")
    import config.config_loader as config_loader
    import config.settings as settings
    from core.utils.cache.config import CacheType
    from core.utils.cache.manager import cache_manager

    conftest_active = getattr(config_loader.load_config, "__name__", "") == "_load_config_patched"
    if not conftest_active and cache_manager.get(CacheType.CONFIG, "main_config") is None:
        cache_manager.set(CacheType.CONFIG, "main_config", {
            "log": {"log_level": "INFO", "log_dir": str(ROOT / "tmp"),
                    "log_file": "openrouter_live.log", "data_dir": str(ROOT / "tmp")},
        })
    settings.config_file_valid = True  # skip check_config_file() (needs data/.config.yaml)

    import openrouter
    from openrouter import errors
    from core.providers.llm.openrouter import openrouter as orp
    from core.providers.llm.openrouter import usage as usage_mod

    try:
        from importlib.metadata import version

        sdk_version = version("openrouter")
    except Exception:
        sdk_version = "unknown"
    return SimpleNamespace(openrouter=openrouter, errors=errors, orp=orp, usage=usage_mod,
                           sdk_version=sdk_version)


_ENV_CACHE: dict = {}


def _live_env():
    """Evaluate the gate once; returns SimpleNamespace or calls pytest.skip(reason)."""
    if "skip" in _ENV_CACHE:
        pytest.skip(_ENV_CACHE["skip"])
    if "env" in _ENV_CACHE:
        return _ENV_CACHE["env"]

    def _skip(reason):
        _ENV_CACHE["skip"] = reason
        pytest.skip(reason)

    if os.environ.get("RUN_LIVE_API_TESTS") != "1":
        _skip("live OpenRouter tests need RUN_LIVE_API_TESTS=1 (no network is used otherwise)")
    key, source = _resolve_key()
    if not key:
        _skip(f"no OpenRouter key: {source}")
    try:
        mods = _bootstrap()
    except Exception as e:  # noqa: BLE001 - report as skip with reason, never fail collection/run
        _skip(f"cannot import the provider stack: {type(e).__name__}: {e}")

    model = os.environ.get("OPENROUTER_MODEL", "").strip() or DEFAULT_MODEL
    extra = {}
    raw_extra = os.environ.get("OPENROUTER_EXTRA_CONFIG", "").strip()
    if raw_extra:
        try:
            extra = json.loads(raw_extra)
            assert isinstance(extra, dict)
        except Exception:
            _skip("OPENROUTER_EXTRA_CONFIG is not a JSON object")
    env = SimpleNamespace(
        key=key, key_source=source, mods=mods, model=model,
        tool_model=os.environ.get("OPENROUTER_TOOL_MODEL", "").strip() or model,
        fallbacks=os.environ.get("OPENROUTER_FALLBACK_MODELS", "").strip() or DEFAULT_FALLBACK,
        base_url=os.environ.get("OPENROUTER_BASE_URL", "").strip(),
        extra=extra,
        l4_runs=int(os.environ.get("OPENROUTER_L4_RUNS", "3") or 3),
    )
    _ENV_CACHE["env"] = env
    return env


# ------------------------------------------------------------------ results collection
RESULTS: dict = {"meta": {}, "tests": {}}


def _plain(value):
    """Scalars only; SDK UNSET sentinels and objects become None (JSON safe)."""
    return value if isinstance(value, (int, float, str, bool, type(None))) else None


def _is_set(value):
    """True for a real value (not None and not the SDK's Unset sentinel)."""
    return value is not None and type(value).__name__ != "Unset"


def _trim(text, limit=MAX_TEXT):
    text = "" if text is None else str(text)
    return text if len(text) <= limit else text[:limit] + "..."


def exc_view(e):
    """JSON-safe description of an exception (type, HTTP status, trimmed message/body)."""
    if e is None:
        return None
    return {
        "type": type(e).__name__,
        "module": type(e).__module__,
        "status_code": _plain(getattr(e, "status_code", None)),
        "message": _trim(e),
        "body": _trim(getattr(e, "body", None)),
    }


_REC_FIELDS = (
    "call_kind", "ttft_ms", "duration_ms", "requested_model", "served_model", "generation_id",
    "selected_provider", "attempts", "generation_time_ms", "prompt_tokens", "completion_tokens",
    "total_tokens", "cached_tokens", "cache_write_tokens", "reasoning_tokens", "cost",
    "upstream_inference_cost", "is_byok", "finish_reason", "tool_call_count", "aborted",
    "error_type", "error_status", "error_message", "routing",
)


def rec_view(rec):
    """Compact JSON-safe view of a UsageRecord (no prompt/response text exists in it)."""
    if rec is None:
        return None
    data = rec.to_dict()
    view = {k: data.get(k) for k in _REC_FIELDS if data.get(k) not in (None, {}, [])}
    if "error_message" in view:
        view["error_message"] = _trim(view["error_message"])
    return view


class Finding:
    """Per-test structured observation, merged into RESULTS['tests'][test_id]."""

    def __init__(self, test_id):
        self.test_id = test_id
        self.data = {"status": "unknown", "summary": "", "observations": {}}
        RESULTS["tests"][test_id] = self.data

    def set(self, **fields):
        self.data["observations"].update(fields)

    def summary(self, text):
        self.data["summary"] = _trim(text, 200)

    def skip(self, reason):
        self.data["status"] = "skipped"
        self.data["summary"] = _trim(reason, 200)
        pytest.skip(reason)


def _write_results(key):
    if not RESULTS["tests"]:
        return None
    path = Path(os.environ.get(RESULTS_ENV) or ROOT / "tmp" / "openrouter_live_results.json")
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(RESULTS, indent=2, ensure_ascii=False, default=str)
    if key:
        text = text.replace(key, "<redacted>")
    path.write_text(text, encoding="utf-8")
    return path


def _summary_lines():
    lines = [f"{'test':<26}{'status':<10}summary", "-" * 100]
    for test_id, data in sorted(RESULTS["tests"].items()):
        lines.append(f"{test_id:<26}{data.get('status', '?'):<10}{data.get('summary', '')}")
    return lines


@pytest.fixture(scope="session", autouse=True)
def _results_writer(request):
    yield
    env = _ENV_CACHE.get("env")
    if not env or not RESULTS["tests"]:
        return
    path = _write_results(env.key)
    lines = _summary_lines() + ([f"results JSON: {path}"] if path else [])
    reporter = request.config.pluginmanager.get_plugin("terminalreporter")
    if reporter is not None:
        reporter.write_sep("=", "OpenRouter live summary")
        for line in lines:
            reporter.write_line(line)
    else:
        print("\n".join(lines))


@pytest.fixture(autouse=True)
def live():
    """Gate: every test is SKIPPED with a clear reason unless live mode + key are available."""
    return _live_env()


class Collector:
    """Usage sink capturing every UsageRecord emitted during a test."""

    def __init__(self):
        self.records = []

    def __call__(self, record):
        self.records.append(record)


class Harness:
    def __init__(self, env, collector, finding):
        self.env, self.col, self.finding = env, collector, finding
        self.model, self.key = env.model, env.key

    def provider(self, api_key=None, **overrides):
        """Build the public provider with a small, cheap default config."""
        cfg = {"type": "openrouter", "model_name": self.env.model, "api_key": api_key or self.env.key,
               "max_tokens": 64, "temperature": 0, "timeout": 60}
        if self.env.base_url:
            cfg["base_url"] = self.env.base_url
        cfg.update(self.env.extra)
        cfg.update(overrides)
        return self.env.mods.orp.LLMProvider(cfg)

    def call(self, provider, dialogue, session_id="", functions=None, **kwargs):
        """Run one call to completion; never raises. Returns an Outcome-like namespace."""
        before = len(self.col.records)
        items, text, exc = [], "", None
        started = time.monotonic()
        try:
            if functions is None:
                for part in provider.response(session_id, dialogue, **kwargs):
                    text += part
                    items.append(part)
            else:
                for content, tool_calls in provider.response_with_functions(
                        session_id, dialogue, functions=functions, **kwargs):
                    if content:
                        text += content
                    items.append((content, tool_calls))
        except Exception as e:  # noqa: BLE001 - recorded, tests decide what to assert
            exc = e
        return SimpleNamespace(text=text, items=items, exc=exc, records=self.col.records[before:],
                               elapsed_ms=int((time.monotonic() - started) * 1000))


@pytest.fixture
def h(request, live):
    """Per-test harness: usage collector registered as sink, finding, status bookkeeping."""
    test_id = request.node.name.split("_", 2)[1]  # test_L3_tool_call -> L3
    finding = Finding(test_id)
    collector = Collector()
    live.mods.usage.register_usage_sink(collector)
    failed_before = request.session.testsfailed
    RESULTS["meta"] = {
        "started_at": RESULTS["meta"].get("started_at") or time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "python": sys.version.split()[0], "openrouter_sdk": live.mods.sdk_version,
        "model": live.model, "tool_model": live.tool_model, "fallback_models": live.fallbacks,
        "base_url": live.base_url or "default", "key_source": live.key_source,
        "extra_config_keys": sorted(live.extra),
    }
    yield Harness(live, collector, finding)
    live.mods.usage.unregister_usage_sink(collector)
    if finding.data["status"] == "unknown":
        failed = request.session.testsfailed > failed_before
        finding.data["status"] = "failed" if failed else "passed"


# ------------------------------------------------------------------ L1 - which chunk carries usage
class SpyStream:
    """Thin recording wrapper around the SDK EventStream (same iterate/close surface the provider uses)."""

    def __init__(self, inner, log, t0):
        self._inner, self._it, self._log, self._t0 = inner, iter(inner), log, t0

    def __iter__(self):
        return self

    def __next__(self):
        chunk = next(self._it)
        choices = getattr(chunk, "choices", None) or []
        first = choices[0] if choices else None
        delta = getattr(first, "delta", None)
        content = getattr(delta, "content", None)
        finish = getattr(first, "finish_reason", None)
        self._log.append({
            "i": len(self._log),
            "t_ms": int((time.monotonic() - self._t0) * 1000),
            "n_choices": len(choices),
            "content_len": len(content) if isinstance(content, str) else 0,
            "finish_reason": str(finish) if _is_set(finish) else None,
            "has_usage": _is_set(getattr(chunk, "usage", None)),
            "has_metadata": _is_set(getattr(chunk, "openrouter_metadata", None)),
            "has_error": _is_set(getattr(chunk, "error", None)),
        })
        return chunk

    def close(self):
        close = getattr(self._inner, "close", None)
        if close:
            close()


def test_L1_usage_chunk_position(h, monkeypatch):
    provider = h.provider()
    log = []
    chat = provider.client.chat
    real_send = chat.send

    def spying_send(**kwargs):
        return SpyStream(real_send(**kwargs), log, time.monotonic())

    monkeypatch.setattr(chat, "send", spying_send)
    out = h.call(provider, [{"role": "user", "content": "Say hello in five words."}], "live-L1")

    usage_chunks = [c for c in log if c["has_usage"]]
    finish_idx = [c["i"] for c in log if c["finish_reason"]]
    obs = {
        "n_chunks": len(log),
        "usage_chunk_indexes": [c["i"] for c in usage_chunks],
        "usage_chunk_choices_empty": [c["n_choices"] == 0 for c in usage_chunks],
        "usage_chunk_is_last": bool(usage_chunks) and usage_chunks[-1]["i"] == len(log) - 1,
        "finish_reason_chunk_indexes": finish_idx,
        "usage_after_finish_reason": bool(usage_chunks and finish_idx and usage_chunks[0]["i"] > finish_idx[0]),
        "metadata_chunk_indexes": [c["i"] for c in log if c["has_metadata"]],
        "error_chunk_indexes": [c["i"] for c in log if c["has_error"]],
        "chunks": log,
        "exception": exc_view(out.exc),
        "record": rec_view(out.records[0]) if out.records else None,
    }
    h.finding.set(**obs)
    h.finding.summary(
        f"{len(log)} chunks; usage at {obs['usage_chunk_indexes']} choices_empty={obs['usage_chunk_choices_empty']}"
        f" last={obs['usage_chunk_is_last']}")
    assert out.exc is None, f"call failed: {exc_view(out.exc)}"
    assert len(out.records) == 1, "exactly one UsageRecord expected"
    assert out.records[0].total_tokens is not None, "no usage captured; see findings L1 chunk layout"


# ------------------------------------------------------------------ L2 - stream cost vs generation record
def test_L2_cost_vs_generation(h):
    provider = h.provider()
    out = h.call(provider, [{"role": "user", "content": "Name one primary colour."}], "live-L2")
    assert out.exc is None, f"call failed: {exc_view(out.exc)}"
    assert len(out.records) == 1
    rec = out.records[0]
    obs = {"record": rec_view(rec), "stream_cost": rec.cost}
    if not rec.generation_id:
        h.finding.set(**obs)
        h.finding.skip("no generation_id captured, cannot call get_generation")

    # Availability lag of /generation is undocumented -> retry with backoff
    delays = [1, 2, 3, 5, 8, 10]
    waited, tries, errors_seen, data = 0.0, 0, [], None
    for delay in [0] + delays:
        time.sleep(delay)
        waited += delay
        tries += 1
        try:
            resp = provider.client.generations.get_generation(
                id=rec.generation_id, retries=h.env.mods.orp.RETRY_NONE, timeout_ms=15000)
            data = resp.data
            break
        except Exception as e:  # noqa: BLE001
            errors_seen.append(f"{type(e).__name__}:{_plain(getattr(e, 'status_code', None))}")
    obs.update(get_generation_tries=tries, get_generation_waited_s=waited, get_generation_errors=errors_seen)
    if data is None:
        h.finding.set(**obs, generation_available=False)
        h.finding.summary(f"generation not available after {tries} tries ({waited}s): {errors_seen[-1:]}")
        h.finding.skip("get_generation never returned data within backoff budget (recorded)")

    total_cost = _plain(getattr(data, "total_cost", None))
    gen = {name: _plain(getattr(data, name, None)) for name in (
        "total_cost", "upstream_inference_cost", "usage", "cache_discount", "tokens_prompt",
        "tokens_completion", "native_tokens_prompt", "native_tokens_completion",
        "native_tokens_cached", "provider_name", "model", "latency", "generation_time",
        "streamed", "is_byok", "finish_reason")}
    delta = (rec.cost - total_cost) if (rec.cost is not None and total_cost is not None) else None
    obs.update(generation_available=True, generation=gen, delta_stream_minus_generation=delta,
               tokens_match=(gen["tokens_prompt"] == rec.prompt_tokens
                             and gen["tokens_completion"] == rec.completion_tokens),
               provider_match=(gen["provider_name"] == rec.selected_provider))
    h.finding.set(**obs)
    h.finding.summary(f"stream_cost={rec.cost} generation_total_cost={total_cost} delta={delta}")
    if delta is not None:  # None on either side is a recorded unknown, not a failure
        assert abs(delta) <= 1e-4 + 0.1 * abs(total_cost), f"cost mismatch beyond loose tolerance: {delta}"


# ------------------------------------------------------------------ L3 - tool calls
TOOLS = [{
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "Get the current weather for a city.",
        "parameters": {"type": "object",
                       "properties": {"city": {"type": "string", "description": "City name"}},
                       "required": ["city"]},
    },
}]


def _merge_impl():
    """Real ConnectionHandler._merge_tool_calls if importable, else a verbatim copy.

    The method never uses `self`, so it is called unbound with None as self.
    """
    try:
        from core.connection import ConnectionHandler

        return (lambda lst, calls: ConnectionHandler._merge_tool_calls(None, lst, calls)), "ConnectionHandler"
    except Exception as e:  # noqa: BLE001 - heavy import chain; fall back to a copy
        def merge(tool_calls_list, tools_call):
            # COPY of core/connection.py ConnectionHandler._merge_tool_calls (keep in sync)
            for tool_call in tools_call:
                tool_index = getattr(tool_call, "index", None)
                if tool_index is None:
                    if tool_call.function.name:
                        tool_index = len(tool_calls_list)
                    else:
                        tool_index = len(tool_calls_list) - 1 if tool_calls_list else 0
                if tool_index >= len(tool_calls_list):
                    tool_calls_list.append({"id": "", "name": "", "arguments": ""})
                if tool_call.id:
                    tool_calls_list[tool_index]["id"] = tool_call.id
                if tool_call.function.name:
                    tool_calls_list[tool_index]["name"] = tool_call.function.name
                if tool_call.function.arguments:
                    tool_calls_list[tool_index]["arguments"] += tool_call.function.arguments

        return merge, f"copy (import failed: {type(e).__name__})"


def test_L3_tool_call_roundtrip(h):
    provider = h.provider(model_name=h.env.tool_model, max_tokens=128)
    system = {"role": "system", "content": "You are a voice assistant. Always call the provided tool "
                                           "to answer weather questions; never guess the weather."}
    user = {"role": "user", "content": "What is the weather in Hanoi right now?"}
    out = h.call(provider, [system, user], "live-L3", functions=TOOLS)
    assert out.exc is None, f"call failed: {exc_view(out.exc)}"
    assert len(out.records) == 1

    fragments = [f for _, calls in out.items if calls for f in calls]
    shape = [{"index": f.index, "has_id": bool(f.id), "name": f.function.name,
              "args_len": len(f.function.arguments or "")} for f in fragments]
    merge, impl = _merge_impl()
    merged = []
    for _, calls in out.items:
        if calls:
            merge(merged, calls)
    obs = {"tool_model": h.env.tool_model, "merge_impl": impl, "fragment_count": len(fragments),
           "fragment_shape": shape, "id_only_in_first_fragment": bool(shape) and not any(
               s["has_id"] for s in shape[1:]),
           "merged_calls": [{"name": m["name"], "has_id": bool(m["id"]), "args_len": len(m["arguments"])}
                            for m in merged],
           "text_before_tool_call_len": len(out.text), "record_turn1": rec_view(out.records[0])}
    h.finding.set(**obs)
    assert merged, "model did not call the tool (see fragment shape); try OPENROUTER_TOOL_MODEL"
    call = merged[0]
    assert call["name"] == "get_weather"
    args = json.loads(call["arguments"])  # raises if fragments were not rebuilt into valid JSON
    assert isinstance(args, dict) and "city" in args
    obs["merged_arguments_keys"] = sorted(args)

    # Second turn, same shape that core/connection.py writes into the dialogue
    call_id = call["id"] or "call_live_1"
    assistant = {"role": "assistant", "tool_calls": [{
        "id": call_id, "type": "function", "index": 0,
        "function": {"name": call["name"], "arguments": call["arguments"]}}]}
    tool_msg = {"role": "tool", "tool_call_id": call_id,
                "content": json.dumps({"city": args["city"], "temp_c": 31, "condition": "sunny"})}
    out2 = h.call(provider, [system, user, assistant, tool_msg], "live-L3", functions=TOOLS)
    obs.update(turn2_exception=exc_view(out2.exc), turn2_text_len=len(out2.text),
               turn2_tool_calls_again=any(c for _, c in out2.items if c),
               record_turn2=rec_view(out2.records[0]) if out2.records else None)
    h.finding.set(**obs)
    h.finding.summary(f"{len(fragments)} fragments, merged={[m['name'] for m in merged]}, "
                      f"args ok, turn2 text_len={len(out2.text)}")
    assert out2.exc is None, f"second turn failed: {exc_view(out2.exc)}"
    assert out2.text.strip(), "no final text answer after tool result"
    assert len(out2.records) == 1


# ------------------------------------------------------------------ L4 - TTFT by routing variant
def test_L4_ttft_routing_variants(h):
    prompt = [{"role": "user", "content": "Xin chào! Hãy chào lại tôi bằng một câu tiếng Việt ngắn."}]
    variants = [
        ("default-no_meta", {"record_routing": False}),
        ("routing_meta", {"record_routing": True}),
        ("sort=latency", {"provider_sort": "latency"}),
        ("sort=throughput", {"provider_sort": "throughput"}),
    ]
    runs = max(1, h.env.l4_runs)
    # Warm-up: pays DNS/TLS once for the shared client so variants are comparable
    warm = h.call(h.provider(max_tokens=16), prompt, "live-L4-warm")
    table = {"warmup": rec_view(warm.records[0]) if warm.records else {"exception": exc_view(warm.exc)}}
    rows, produced = [], 0
    for name, cfg in variants:
        provider = h.provider(max_tokens=32, **cfg)
        samples = []
        for n in range(runs):
            out = h.call(provider, prompt, f"live-L4-{name}-{n}")
            rec = out.records[0] if out.records else None
            produced += 1 if rec else 0
            samples.append({"run": n, "exception": exc_view(out.exc), "record": rec_view(rec),
                            "ttft_ms": rec.ttft_ms if rec else None,
                            "duration_ms": rec.duration_ms if rec else None,
                            "selected_provider": rec.selected_provider if rec else None,
                            "served_model": rec.served_model if rec else None})
        ttfts = [s["ttft_ms"] for s in samples if s["ttft_ms"] is not None]
        rows.append({"variant": name, "median_ttft_ms": sorted(ttfts)[len(ttfts) // 2] if ttfts else None,
                     "min_ttft_ms": min(ttfts) if ttfts else None, "max_ttft_ms": max(ttfts) if ttfts else None,
                     "providers": sorted({s["selected_provider"] for s in samples if s["selected_provider"]}),
                     "samples": samples})
    table["variants"] = rows
    h.finding.set(runs_per_variant=runs, **table)
    lines = [f"{'variant':<24}{'median':>8}{'min':>8}{'max':>8}  providers"]
    for r in rows:
        lines.append(f"{r['variant']:<24}{str(r['median_ttft_ms']):>8}{str(r['min_ttft_ms']):>8}"
                     f"{str(r['max_ttft_ms']):>8}  {','.join(r['providers']) or '-'}")
    print("\nL4 TTFT (ms)\n" + "\n".join(lines))
    h.finding.summary("; ".join(f"{r['variant']}={r['median_ttft_ms']}ms" for r in rows))
    assert produced == runs * len(variants), "every L4 run must emit a UsageRecord"


# ------------------------------------------------------------------ L5 - reasoning_effort values
def test_L5_reasoning_effort_values(h):
    results, accepted = {}, []
    for value in ("none", "minimal", "low"):
        out = h.call(h.provider(max_tokens=32, reasoning_effort=value),
                     [{"role": "user", "content": "Reply with the single word: ok"}], f"live-L5-{value}")
        rec = out.records[0] if out.records else None
        ok = out.exc is None and rec is not None and rec.error_type is None
        if ok:
            accepted.append(value)
        results[value] = {"accepted": ok, "exception": exc_view(out.exc), "record": rec_view(rec),
                          "text_len": len(out.text)}
    h.finding.set(model=h.env.model, accepted=accepted,
                  rejected=[v for v in results if v not in accepted], by_value=results)
    h.finding.summary(f"accepted={accepted} rejected={[v for v in results if v not in accepted]}")
    if not accepted:
        h.finding.skip(f"model {h.env.model} accepted none of none/minimal/low (details recorded)")


# ------------------------------------------------------------------ L6 - error surfaces
def test_L6_invalid_model_and_key(h):
    prompt = [{"role": "user", "content": "hi"}]
    cases = {
        "invalid_model": h.provider(model_name=INVALID_MODEL, max_tokens=8),
        "invalid_key": h.provider(api_key=FAKE_KEY, max_tokens=8),
    }
    obs = {}
    for name, provider in cases.items():
        out = h.call(provider, prompt, f"live-L6-{name}")
        rec = out.records[0] if out.records else None
        obs[name] = {"raised": out.exc is not None, "exception": exc_view(out.exc),
                     "is_openrouter_error": isinstance(out.exc, h.env.mods.errors.OpenRouterError),
                     "records_emitted": len(out.records), "record": rec_view(rec)}
    h.finding.set(forced_429="not attempted by design", **obs)
    h.finding.summary("; ".join(
        f"{k}: {v['exception']['type'] if v['exception'] else 'no exception'} "
        f"status={v['record'].get('error_status') if v['record'] else None}" for k, v in obs.items()))
    for name, o in obs.items():
        assert o["raised"], f"{name}: provider did not raise"
        assert o["records_emitted"] == 1, f"{name}: expected exactly one UsageRecord"
        assert o["record"] and o["record"].get("error_type"), f"{name}: record has no error_type"


# ------------------------------------------------------------------ L7 - fallback_models
def test_L7_fallback_models(h):
    prompt = [{"role": "user", "content": "Reply with the single word: ok"}]
    fallbacks = h.env.fallbacks
    variants = {
        "valid_primary+valid_fallback": dict(model_name=h.env.model, fallback_models=fallbacks),
        "invalid_primary+valid_fallback": dict(model_name=INVALID_MODEL, fallback_models=fallbacks),
        "valid_primary+fallback+sort=latency": dict(model_name=h.env.model, fallback_models=fallbacks,
                                                    provider_sort="latency"),
    }
    obs = {}
    for name, cfg in variants.items():
        out = h.call(h.provider(max_tokens=16, **cfg), prompt, f"live-L7-{name}")
        rec = out.records[0] if out.records else None
        obs[name] = {"outcome": "ok" if out.exc is None else "error", "exception": exc_view(out.exc),
                     "text_len": len(out.text), "record": rec_view(rec),
                     "served_model": rec.served_model if rec else None,
                     "selected_provider": rec.selected_provider if rec else None,
                     "served_by_fallback": bool(rec and rec.served_model
                                                and cfg["model_name"] != rec.served_model
                                                and rec.served_model in fallbacks)}
    h.finding.set(fallback_models=fallbacks, **obs)
    h.finding.summary("; ".join(f"{k.split('+')[0]}: {v['outcome']} served={v['served_model']}"
                                for k, v in obs.items()))
    for name in obs:
        assert obs[name]["record"] is not None, f"{name}: no UsageRecord emitted"


# ------------------------------------------------------------------ L8 - abort mid-stream
def test_L8_abort_mid_stream(h):
    provider = h.provider(max_tokens=300)
    prompt = [{"role": "user", "content": "Count from 1 to 200, separated by commas, nothing else."}]
    gen = provider.response("live-L8", prompt)
    taken, start_exc = [], None
    started = time.monotonic()
    try:
        for _ in range(3):
            taken.append(next(gen))
    except StopIteration:
        pass
    except Exception as e:  # noqa: BLE001
        start_exc = e
    first_ms = int((time.monotonic() - started) * 1000)
    t0 = time.monotonic()
    gen.close()
    close_ms = int((time.monotonic() - t0) * 1000)

    obs = {"chunks_taken": len(taken), "time_to_3_chunks_ms": first_ms, "close_ms": close_ms,
           "start_exception": exc_view(start_exc), "records_emitted": len(h.col.records),
           "record": rec_view(h.col.records[0]) if h.col.records else None}
    # The client must still work afterwards
    after = h.call(provider, [{"role": "user", "content": "Reply with the single word: ok"}],
                   "live-L8-after", max_tokens=8)
    obs.update(after_exception=exc_view(after.exc), after_text_len=len(after.text),
               after_record=rec_view(after.records[0]) if after.records else None)
    h.finding.set(**obs)
    h.finding.summary(f"close_ms={close_ms} aborted={obs['record'] and obs['record'].get('aborted')} "
                      f"after_ok={after.exc is None and bool(after.text)}")

    assert start_exc is None, f"stream failed before 3 chunks: {exc_view(start_exc)}"
    assert len(taken) == 3, "generation ended before 3 chunks; cannot test abort"
    assert obs["records_emitted"] == 1, "abort must emit exactly one UsageRecord"
    assert h.col.records[0].aborted is True
    assert close_ms < 3000, f"close() took {close_ms} ms"
    assert after.exc is None and after.text.strip(), "client unusable after abort"
    assert len(after.records) == 1 and after.records[0].aborted is False


# ------------------------------------------------------------------ L9 - session_id / user / caching
def test_L9_session_user_and_cache(h):
    paragraph = ("The assistant must answer politely, briefly and in the language of the user. "
                 "It speaks through a small voice device, so it avoids lists, markdown and emoji. ")
    system = {"role": "system", "content": "You are a friendly voice assistant. " + paragraph * 40}
    provider = h.provider(max_tokens=24)
    provider.bind_connection(device_id="live-test-device")  # exercises the `user` parameter
    session_id = f"live-L9-{uuid.uuid4().hex[:8]}"
    outs = []
    for question in ("What is two plus two?", "What is three plus three?"):
        outs.append(h.call(provider, [system, {"role": "user", "content": question}], session_id))
        time.sleep(1.0)
    recs = [o.records[0] if o.records else None for o in outs]
    obs = {"session_id_sent": True, "user_sent": provider.user_id is not None,
           "system_prompt_chars": len(system["content"]),
           "calls": [{"exception": exc_view(o.exc), "text_len": len(o.text), "record": rec_view(r)}
                     for o, r in zip(outs, recs)],
           "cached_tokens_call1": recs[0].cached_tokens if recs[0] else None,
           "cached_tokens_call2": recs[1].cached_tokens if recs[1] else None,
           "prompt_tokens_call2": recs[1].prompt_tokens if recs[1] else None}
    h.finding.set(**obs)
    h.finding.summary(f"cached_tokens call1={obs['cached_tokens_call1']} call2={obs['cached_tokens_call2']} "
                      f"(prompt_tokens={obs['prompt_tokens_call2']})")
    for o in outs:
        assert o.exc is None, f"call failed with session_id/user: {exc_view(o.exc)}"
        assert o.text.strip() and len(o.records) == 1 and o.records[0].error_type is None


# ------------------------------------------------------------------ L10 - gate for record_routing=true
def test_L10_record_routing_metadata(h):
    """Decides whether `record_routing` can be switched on (it is off by default).

    With record_routing the provider asks for `openrouter_metadata`; the SDK model requires several
    fields, so a response that omits one would raise ResponseValidationError and fail the stream.
    safe_to_enable is True only if a call with it on completes, parses the metadata and names the
    selected provider.
    """
    provider = h.provider(record_routing=True)
    sent = provider.request_defaults.get("x_open_router_metadata")
    out = h.call(provider, [{"role": "user", "content": "Say hello in five words."}], "live-L10")
    rec = out.records[0] if out.records else None
    validation_error = out.exc is not None and type(out.exc).__name__ == "ResponseValidationError"
    obs = {
        "metadata_requested": sent,
        "exception": exc_view(out.exc),
        "validation_error": validation_error,
        "record": rec_view(rec),
        "selected_provider": rec.selected_provider if rec else None,
        "attempts": rec.attempts if rec else None,
        "generation_time_ms": rec.generation_time_ms if rec else None,
    }
    obs["safe_to_enable"] = bool(out.exc is None and rec is not None and rec.selected_provider)
    h.finding.set(**obs)
    h.finding.summary(f"safe_to_enable={obs['safe_to_enable']} provider={obs['selected_provider']} "
                      f"generation_time_ms={obs['generation_time_ms']} validation_error={validation_error}")
    assert sent == "enabled", "record_routing=True did not request metadata"
    assert out.exc is None, f"call with record_routing failed: {exc_view(out.exc)}"
    assert len(out.records) == 1 and rec.total_tokens is not None
