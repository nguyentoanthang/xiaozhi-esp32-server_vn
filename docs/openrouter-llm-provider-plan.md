# OpenRouter LLM Provider — Implementation Plan

Status: **provider and live tests are implemented; offline tests pass (45); live tests (section 13) are pending the user's OpenRouter key and have never been run against the real API.**
Scope: add one new LLM provider (`type: openrouter`) built on the official `openrouter` Python SDK, with
provider-routing options and per-call token/cost usage capture. Existing providers are not modified.

Legend: **[V]** verified by reading the source in this repo / SDK, **[R]** reported by a research session and
not re-read, **[I]** inference, **[T]** must be confirmed by a live call.

---

## 1. Decisions (from the user)

| Topic | Decision |
|---|---|
| Usage storage | Phase 1 only **captures, exposes and logs** usage. Storage/dashboard is a **future feature** (section 12). |
| Mode | **Full mode** (config comes from Java `manager-api`), so the console, DB and Java checks are in scope. |
| Routing | **Fixed model + provider routing** (sort/order/only/ignore/fallbacks/...). Auto-router is out of scope. |
| Interruption | Provider closes its HTTP stream cleanly when the generator is closed/aborted. |
| Dependency | Add `openrouter` to `main/xiaozhi-server/requirements.txt`. |
| API key | Stored like other providers' keys (`config_json` in `ai_model_config` / YAML). |
| Attribution goal | Usage must be attributable **per device** and **per agent** later. |

Non-goals: STT/TTS, embeddings, Responses API, credits, key management, auto-router/pareto plugins, storing usage.

---

## 2. Facts the design relies on

### 2.1 Repo contract (`main/xiaozhi-server`)

- `LLMProviderBase` [V] (`core/providers/llm/base.py`): abstract `response(session_id, dialogue)`;
  `response_no_stream(system_prompt, user_prompt, **kwargs)` joins `self.response("", dialogue, **kwargs)` so
  **`response` must accept `**kwargs` (e.g. `max_tokens`, `temperature`) and yield `str` only**;
  `response_with_functions(session_id, dialogue, functions=None)` defaults to `(token, None)`.
- Provider loading [R]: `core/utils/llm.py:create_instance` imports
  `core.providers.llm.<type>.<type>` and instantiates `LLMProvider(config)`. No registry to edit.
  So `type: openrouter` needs `core/providers/llm/openrouter/openrouter.py` with `class LLMProvider`.
- `chat()` consumption [V] (`core/connection.py:1129-1173`): function mode iterates `content, tools_call = response`;
  non-function mode expects `str`. `client_abort` is checked once per yielded item and then `break`s.
  Exceptions during iteration are caught by `chat()` (logged and an error is spoken) [R].
- `_merge_tool_calls` [V] (`connection.py:1826-1852`) reads `tool_call.index` (optional), `.id`, `.function.name`,
  `.function.arguments` (concatenated). So tool-call fragments must be objects with those attributes
  (use `types.SimpleNamespace`, as the Gemini provider does).
- Instances [R]: in full mode every connection builds its **own** provider instance from the config returned by Java
  (`connection.py:858-863`, `934-952`); in YAML-only mode one global instance is shared. Intent LLM and memory LLM
  call `response_no_stream` (non-streaming, `session_id=""`).
- Identity available on the connection [R]: `session_id` (uuid, also passed to `response*`), `device_id` (MAC from
  header `device-id`), `sentence_id`. **No `agent_id` exists on the Python side**; Java resolves device -> agent from
  `macAddress`. The existing chat-history report already carries `{macAddress, sessionId}`.
- Full-mode config path [R]: `ConfigServiceImpl.getAgentModels` returns `LLM = {<ai_model_config.id>: config_json}`;
  `config_json.type` selects the Python module; the provider form fields come from `ai_model_provider.fields`.

### 2.2 SDK facts (`openrouter` 1.3.43, Python >= 3.10) — from `openrouter/python-sdk-main`

- Sync streaming: `with client.chat.send(..., stream=True) as stream: for chunk in stream:` → `EventStream[ChatStreamChunk]`
  [R]; closing the stream closes the httpx response; the generator closes it in `finally` [V `eventstreaming.py:241`].
- `ChatStreamChunk` [V]: `choices` (required list), `id`, `model`, `created`, optional `error`, `usage`,
  `openrouter_metadata`. `delta.content` / `reasoning` use an `UNSET` sentinel → test with truthiness, never `is not None`.
- `ChatStreamToolCall` [R]: only `index` required; `id`, `function.name`, `function.arguments` optional strings.
- `ChatUsage` [V]: `prompt_tokens`, `completion_tokens`, `total_tokens` required; optional `cost`, `cost_details`
  (`upstream_inference_prompt_cost`, `upstream_inference_completions_cost`, `upstream_inference_cost`),
  `is_byok`, `prompt_tokens_details.{cached_tokens,cache_write_tokens}`, `completion_tokens_details.reasoning_tokens`.
- `stream_options.include_usage` is **deprecated; "Full usage details are always included"** [V]. Do not send it.
- Retries [V `chat.py:849-859`]: default is backoff retry on 5xx **and connection errors up to 1 hour**. Must be disabled.
- Timeout [V `basesdk.py:226-236`]: `timeout_ms=None` → httpx default. Set it explicitly.
- Errors [R]: `errors.OpenRouterError` base (`status_code`, `body`); typed 400/401/402/403/404/408/413/422/429/5xx;
  mid-stream failure arrives either as `chunk.error` or, if the chunk lacks required fields, as
  `errors.ResponseValidationError` raised from `next(stream)` with the raw payload in `.body`. Network errors are raw `httpx` exceptions.
- Routing request fields [V/R]: `provider={sort: "price"|"throughput"|"latency", order, only, ignore, allow_fallbacks,
  require_parameters, data_collection: "allow"|"deny", zdr, max_price, preferred_max_latency, preferred_min_throughput,
  quantizations}`, `models=[...]`, `session_id` (sticky routing / cache), `user`, `reasoning_effort`
  (`max|xhigh|high|medium|low|minimal|none`), `x_open_router_metadata="enabled"` (returns selected provider, attempts, `generation_time`).
  `sort` is ignored if `order` is set and disables load balancing.
- Unknown keys in message/tool dicts are silently dropped (pydantic default) [I]. Plain dicts are accepted for messages and tools.

---

## 3. Files

### 3.1 New files

```
main/xiaozhi-server/core/providers/llm/openrouter/openrouter.py   # class LLMProvider
main/xiaozhi-server/core/providers/llm/openrouter/routing.py       # config -> SDK kwargs (pure functions)
main/xiaozhi-server/core/providers/llm/openrouter/usage.py         # UsageRecord, sinks, log sink
main/xiaozhi-server/tests/core/providers/test_openrouter_llm.py    # offline tests with a fake stream
main/manager-api/src/main/resources/db/changelog/<ts>.sql          # provider row + model config seed
docs/openrouter-llm-provider-plan.md                               # this file
```

Check for `__init__.py` convention in sibling provider folders and follow it. `<ts>` must sort after the current
latest changelog (`202609172100`, [R]) — e.g. `202610131200`.

### 3.2 Existing files to edit (minimal, no behaviour change for other providers)

| # | File | Edit | Why |
|---|---|---|---|
| E1 | `main/xiaozhi-server/requirements.txt` | add `openrouter==1.3.43` | dependency (pin style is `==`) |
| E2 | `main/manager-api/src/main/resources/db/changelog/db.changelog-master.yaml` | append a changeSet for the new `<ts>.sql` | register provider |
| E3 | `AgentServiceImpl.java:583`, `AgentSnapshotServiceImpl.java:584` | allow `"openrouter"` next to `openai`/`ollama` | otherwise `Intent_function_call` is rejected for this LLM type [V grep] |
| E4 | `ModelConfigServiceImpl.java:328` | allow `"openrouter"` as a referenced LLM type | otherwise intent_llm/mem_local_short cannot reference it [V grep] |
| E5 | `main/manager-web/src/views/roleConfig.vue:1512,1526-1527` | allow `openrouter` in the function-call gate | console would hide the function-call option [V grep] |
| E6 | `main/xiaozhi-server/core/connection.py` (after `self.llm = modules["llm"]`, ~l.952) | guarded 3-line hook: `if hasattr(self.llm, "bind_connection"): self.llm.bind_connection(device_id=self.device_id)` | attribute usage to a device; other providers unaffected |
| E7 | `config.yaml` (LLM section) | add a **commented** example entry | docs for YAML mode |
| E8 | `README.md` provider table (optional) | one line | docs |

E3–E5 are required for function calling (the agentic loop) to work with this provider in full mode.
If you prefer not to touch Java/Vue, the fallback is `type: openai` + OpenRouter `base_url` (no routing options, no usage capture).

---

## 4. Provider design (`openrouter.py`)

### 4.1 Config keys (form fields; all strings/numbers/booleans — the console supports only these types)

| Key | Type | Default | Maps to |
|---|---|---|---|
| `api_key` | string | – | `OpenRouter(api_key=)` |
| `model_name` | string | – | `model` |
| `base_url` | string | `https://openrouter.ai/api/v1` | `server_url` |
| `temperature`, `top_p`, `frequency_penalty` | number | unset | same names |
| `max_tokens` | number | unset | `max_completion_tokens` |
| `timeout` | number (s) | 30 | `timeout_ms` |
| `reasoning_effort` | string | unset (not sent) | `reasoning_effort`; try `low`/`minimal`/`none` per model **[T]** |
| `fallback_models` | string (comma list) | unset | `models=[...]` |
| `provider_sort` | string | unset | `provider.sort` = `price`/`throughput`/`latency` |
| `provider_order`, `provider_only`, `provider_ignore` | string (comma list) | unset | `provider.order/only/ignore` |
| `allow_fallbacks` | boolean | unset (server default true) | `provider.allow_fallbacks` |
| `require_parameters` | boolean | `true` | `provider.require_parameters` (tools need capable providers) |
| `data_collection` | string | unset | `provider.data_collection` (`allow`/`deny`) |
| `zdr` | boolean | unset | `provider.zdr` |
| `preferred_max_latency` | number (s) | unset | `provider.preferred_max_latency` |
| `preferred_min_throughput` | number (tok/s) | unset | `provider.preferred_min_throughput` |
| `record_routing` | boolean | `false` | `x_open_router_metadata="enabled"` (selected provider, attempts, generation_time). **Off by default**: the SDK requires several `openrouter_metadata` fields, so a response missing one fails the whole stream. Turn on only after live test L10 passes (section 15.7). **[T] latency impact** |
| `app_referer`, `app_title`, `app_categories` | string | unset | attribution headers |

Rules: a missing/empty/invalid value means "do not send" (same tolerance as `openai.py`). Console values may arrive as strings,
so numbers/booleans are parsed defensively. `routing.py` is pure (`build_request_kwargs(cfg) -> dict`) so it can be unit-tested
without the SDK. If `provider_order` is set, `provider_sort` is dropped and a warning is logged.

### 4.2 Client lifecycle

- Build **one shared `OpenRouter` client per `(api_key, base_url, timeout)`** in a module-level dict guarded by a lock, never inside
  a `with` block (the SDK's `__exit__` nulls the client). Reason: in full mode each connection creates its own provider instance, and
  a per-instance client would pay a fresh TLS handshake on the first turn of every connection. **[I]**
- Retries off: `RetryConfig("none", BackoffStrategy(0, 0, 1.0, 0), False)` from `openrouter.utils`.
- Explicit `timeout_ms`. The value applies per HTTP phase, including read gaps during streaming [I].

### 4.3 `response(session_id, dialogue, **kwargs)` → yields `str`

1. Normalize dialogue like `openai.py` (missing `content` → `""`); pass dicts through (`role`, `content`, `tool_calls`, `tool_call_id`).
2. Merge per-call `kwargs` (`temperature`, `max_tokens`, `top_p`) over instance defaults.
3. Call `chat.send(stream=True, ...)` with: model, messages, routing kwargs, `session_id=session_id` when non-empty
   (sticky routing/cache), `user=<hash of device_id>` when bound.
4. Iterate; for each chunk: record usage/model/id/error, then `if chunk.choices and delta.content: yield delta.content`.
5. Strip `<think>...</think>` like the OpenAI provider does (copy the logic, do not import from it).
6. `finally`: close the stream, finalise and emit the `UsageRecord`.

### 4.4 `response_with_functions(session_id, dialogue, functions=None, **kwargs)` → yields `(content|None, tool_calls|None)`

- Same as above plus `tools=functions`, `tool_choice="auto"`. `functions` are already OpenAI-format dicts [R].
- For each delta tool call yield `SimpleNamespace(index, id, type="function", function=SimpleNamespace(name, arguments))` with
  `None` for absent parts; always set `index`. Never assume `choices[0]` exists, never assume `id/name` appear after the first fragment.
- Treat `arguments` of `None`/`""` as empty.
- Note: `chat()` evaluates `"content" in response` on the yielded tuple (l.1161); a token exactly equal to the string `content`
  would raise inside `chat()`. This is an existing quirk affecting all providers, not fixed here.

### 4.5 Error handling

- `chunk.error` set → log, record `error=(code, message, error_type)`, stop iterating, raise `RuntimeError` so `chat()`'s handler speaks the error.
- `ResponseValidationError` → log `e.body` (truncated), record, re-raise.
- `OpenRouterError` (401/402/429/5xx) and `httpx` errors → record `status_code`/type, re-raise (same propagation contract as `openai.py`).
- `finish_reason == "error"` on a choice → same as `chunk.error`.
- Never log the API key or full prompts at INFO.

### 4.6 Abort / interruption

- `chat()` stops with `break` but does **not** call `.close()` on the generator [R], so the stream stays open until the generator is
  garbage collected (when `chat()` returns). The provider guarantees cleanup in `finally` / `GeneratorExit`.
- Optional follow-up (not in this plan unless approved): `llm_responses.close()` after the loop in `chat()` to close immediately.
- An aborted call records `aborted=True`; tokens/cost stay `None` because the usage chunk was never received (see 5.3).

---

## 5. Usage and cost capture (`usage.py`)

### 5.1 Why per-call records

`chat()` can run on worker threads (`max_workers=5`) and intent/memory calls run via `asyncio.to_thread` [R], and in YAML mode
the instance is shared. A single "last usage" attribute would be overwritten. Instead each call creates a **local** `UsageRecord`
inside the generator and emits it exactly once in `finally`.

### 5.2 `UsageRecord` (dataclass)

```
record_id, started_at, ttft_ms, duration_ms, call_kind          # chat | chat_functions | no_stream
session_id, device_id                                           # attribution keys
requested_model, served_model (chunk.model), generation_id (chunk.id)
selected_provider, attempts, generation_time_ms                 # from openrouter_metadata when record_routing=true
prompt_tokens, completion_tokens, total_tokens
cached_tokens, cache_write_tokens, reasoning_tokens
cost, upstream_inference_cost, is_byok                          # None if not reported
finish_reason, tool_call_count, aborted
error_type, error_status, error_message
routing                                                         # snapshot: sort/order/only/ignore/fallback_models/...
```

### 5.3 Capture rules

- `usage` may come in any chunk, including one with empty `choices` **[T]**. Read `chunk.usage` independently of `choices`.
- The first chunk gives `id` (store as `generation_id`) and `model`; set `ttft_ms` on the first non-empty content or tool-call delta.
- If the stream is aborted or fails before usage arrives, tokens/cost remain `None` and `generation_id` is kept so a later job can
  reconcile with `generations.get_generation(id)` (retry with backoff; lag is undocumented) — **future**, not built now.

### 5.4 Attribution (per device / per agent)

- **Primary key `session_id`**: already passed to `response*` on every chat call and already reported to Java with `macAddress`
  in the chat-history report. Java can therefore join `usage.session_id → chat history (macAddress) → device → agent`.
- **`device_id`** (MAC): set through the guarded `bind_connection(device_id=...)` hook (E6). With the per-connection instance in full mode
  this labels every call, including intent/memory calls that have `session_id=""`.
- **`agent_id`**: not known to the Python server and **not added here**. Resolve in Java from MAC, or later add the agent id to the
  `/config/agent-models` response. Marked as future work.
- Limitation: a shared (YAML-mode) instance cannot be bound to one device; there `session_id` is the only key and no-stream calls are anonymous.

### 5.5 Sinks (Phase 1 = log only)

- `usage.py` keeps a small sink registry: `register_usage_sink(callable)`; each finished record is passed to every sink; sink errors are swallowed and logged.
- Default sink: one INFO line per call with tag `llm_usage`, JSON payload, no prompt/response text:
  `llm_usage {"session_id": "...", "device_id": "...", "model": "...", "provider": "...", "prompt_tokens": 120, "completion_tokens": 40, "cost": 0.00012, "ttft_ms": 410, ...}`
- Future sinks (not built): queue to Java via `manage_api_client`, local SQLite, metrics endpoint.

---

## 6. Full-mode plumbing

### 6.1 Liquibase SQL (`<ts>.sql`, new file; mimic `202504082211.sql` and `202504112044.sql`) [R]

1. `INSERT` into `ai_model_provider`: `id='SYSTEM_LLM_openrouter'`, `model_type='LLM'`, `provider_code='openrouter'`,
   `name='OpenRouter'`, `fields` = JSON array of `{key,label,type}` for the keys in 4.1 (types `string|number|boolean`; English labels),
   `sort`, creator/updater/dates like siblings.
2. `INSERT` into `ai_model_config`: `id='LLM_OpenRouterLLM'`, `model_type='LLM'`, `model_code='OpenRouterLLM'`, `model_name='OpenRouter'`,
   `is_default=0`, `is_enabled=1`, `config_json` with `{"type":"openrouter","base_url":"https://openrouter.ai/api/v1","model_name":"openai/gpt-4o-mini","api_key":"your_api_key", ...}`.
   Use an English placeholder key (the repo's `check_model_key` flags placeholders containing `你`). Pick `sort` after reading the current max.
3. `UPDATE ai_model_config SET doc_link=..., remark=...` as in `202602051017.sql:37`.
4. Append the changeSet to `db.changelog-master.yaml` (author: your choice, file name = id).

### 6.2 Type allow-lists (E3–E5): add `openrouter` beside `openai`/`ollama`.

---

## 7. Dependency check (E1)

1. Add `openrouter==1.3.43` to `requirements.txt`.
2. In a clean Python 3.10 venv: `pip install --dry-run -r requirements.txt` then `pip check`. The SDK requires
   `pydantic>=2.11.2,<2.13`, `httpx>=0.28.1` (repo pins `httpx==0.28.1` — compatible), `httpcore>=1.0.9`, `jsonpath-python>=1.0.6`.
   `pydantic` is not pinned by the repo, so a conflict (via `mcp==1.22.0`, `openai==2.8.1`, `powermem`) is possible but **unverified**.
3. If the resolver complains, report it before touching other pins.

---

## 8. Tests

### 8.1 Offline (no network, in CI-style runs)
- `routing.py`: each config key → expected SDK kwargs; comma-list parsing; empty/invalid values dropped; `order` beats `sort`.
- Provider with a **fake client/stream**: (a) text streaming, (b) tool-call fragments across chunks, with `id/name` only in the first,
  (c) usage in a trailing chunk with empty `choices`, (d) usage in the last content chunk, (e) `chunk.error`, (f) `ResponseValidationError`,
  (g) generator closed early → stream closed and `aborted=True` record emitted, (h) `response_no_stream` with `max_tokens`/`temperature` kwargs,
  (i) two interleaved calls produce two separate records.
- Check how `tests/conftest.py` shims the network so the new tests are not accidentally mocked or blocked; follow the `tests/` layout.

### 8.2 Live (gated by `RUN_LIVE_API_TESTS=1`, needs the user's key) — the acceptance gate
| # | Question | Pass condition |
|---|---|---|
| L1 | Which chunk carries `usage`; is `choices` empty there? | observed and documented; code handles it |
| L2 | Does `usage.cost` exist for streaming? equals `get_generation().total_cost` within rounding? | recorded; decides whether `get_generation` reconciliation is needed |
| L3 | Tool-call fragment shape for the chosen model | `_merge_tool_calls` rebuilds valid JSON arguments |
| L4 | TTFT: pinned model default vs `provider_sort=latency` vs `throughput`; with/without `record_routing` | numbers logged; choose defaults |
| L10 | Does a call with `record_routing=true` complete and parse `openrouter_metadata` (selected provider, generation time)? | `safe_to_enable` recorded; gate for switching `record_routing` on |
| L5 | Accepted `reasoning_effort` values for the chosen model | list recorded in remark |
| L6 | Behaviour with an invalid model/key, and a forced 429 | typed exception reaches `chat()` and is spoken |
| L7 | `fallback_models` + `provider` interaction | documented from observation |
| L8 | Abort mid-stream | stream closed, aborted record emitted, no hang |
| L9 | `session_id` and `user` params accepted; cached tokens rise on repeated turns | confirmed |

### 8.3 End-to-end (full mode)
Register the model in the console, bind it to an agent, enable function calling, talk from a device or the test page,
confirm: spoken answer, tool call executes (REQLLM loop), `llm_usage` lines appear with `device_id` and `session_id`.

---

## 9. Implementation order

1. Branch; create the venv; step 7 dependency dry-run.
2. `routing.py` + tests.
3. `usage.py` + tests.
4. `openrouter.py` (`response`, then `response_with_functions`, then `bind_connection`) + offline tests.
5. L1–L3 live probe → adjust capture code.
6. SQL + master yaml + Java/Vue allow-list edits + `connection.py` hook (E2–E6). Build `manager-api` and `manager-web`.
7. End-to-end test (8.3), then L4–L9.
8. Docs (E7, E8) and fill `remark`/`doc_link`.

---

## 10. Risks and open items

| Risk | Mitigation |
|---|---|
| Usage chunk placement unknown | Code tolerates both; L1 decides |
| Streaming `cost` may be absent for some models/BYOK | `None` allowed; `get_generation` reconcile (future) |
| `pydantic` pin conflict | dry-run before coding (7) |
| Hard-coded `openai`/`ollama` checks (E3–E5) | required edits; Java rebuild + console rebuild needed |
| Default SDK retry = up to 1 hour | explicitly disabled; offline test asserts it |
| `reasoning_effort="none"` unsupported by some models | field is optional; unset by default; L5 |
| `record_routing` metadata could fail SDK validation (required fields) or add latency/size | **off by default**; enable only after L10 passes; compare cost in L4 |
| Generator not closed by `chat()` on abort | `finally` cleanup; optional `close()` follow-up |
| Per-connection instances | shared client cache avoids repeated handshakes |
| SDK is auto-generated; fields may drift | pin version; adapter reads defensively with `getattr` |
| `openrouter/python-sdk-main/` is an untracked local copy at repo root | reference only; do not commit or import from it |
| Existing `"content" in response` quirk in `chat()` | not changed here |

---

## 11. Done criteria (phase 1)

- Provider selectable in the console, saved with routing fields, applied on the next connection.
- Streaming chat and tool-calling work through the existing agentic loop.
- Every LLM call (chat, function, intent, memory) emits exactly one `llm_usage` log record with tokens, cost when reported, served model/provider, TTFT, `session_id`, `device_id`.
- Interrupt leaves no open connection.
- Offline tests pass; L1–L3 and L8 pass live; remaining live results are written into the changelog `remark`.
- No existing provider file is modified.

---

## 12. Future features (not in this phase)

- Persist usage (Java table, API, console pages for per-device / per-agent / per-model cost and latency).
- Add `agent_id` to the `/config/agent-models` response or join in Java by MAC.
- Reconcile aborted/failed calls via `generations.get_generation(generation_id)`.
- Budget/limit handling, credits and key management (needs a separate management key).
- Auto-router/pareto plugins, model catalogue sync into the console.
- OpenRouter STT/TTS and the local Vietnamese STT/TTS work (separate effort).

---

## 13. Live test file — `tests/core/providers/test_openrouter_live.py`

Ten tests, one per row of section 8.2 (`test_L1_...` to `test_L10_...`). `record_routing` is **off by default** in the provider; L1-L9 run
with it off except where a test sets it (L4 compares both, **L10 turns it on and says whether it is safe to enable**). They use the public provider interface
(`LLMProvider(config).response / response_with_functions`, `register_usage_sink` to capture `UsageRecord`s). The SDK is used
directly only in L2 (`client.generations.get_generation`) and, as a read-only spy around `client.chat.send`, in L1.
**They have never been run against the real API**; they were only exercised against a local `httpx.MockTransport` harness
(see section 15.6 for what that does and does not prove).

### 13.1 Gating (every test SKIPS, never fails, never touches the network, unless both hold)

1. `RUN_LIVE_API_TESTS=1`
2. a key: env `OPENROUTER_API_KEY`, else (fallback) an LLM entry with `type: openrouter` and a non-placeholder `api_key` in
   `data/.config.yaml` (or the file named by `PYTEST_CONFIG_FILE`).

How `tests/conftest.py` interacts with this **[V, read from the file]**:

| conftest behaviour | Consequence |
|---|---|
| `RUN_LIVE_API_TESTS` unset: replaces `httpx.Client`/`AsyncClient` with fakes that raise `ConnectError` | The SDK cannot work, so the live tests skip before using it. |
| `RUN_LIVE_API_TESTS=1`: `sys.exit(2)` if `data/.config.yaml` has `manager-api.url` **and** `secret` (full mode) | A full-mode `.config.yaml` blocks the whole session. |
| `RUN_LIVE_API_TESTS=1`: `sys.exit(3)` unless ASR, LLM, TTS, Memory and VAD all have a selected provider with a non-placeholder secret | Very hard to satisfy for a one-LLM test. |

Therefore the documented way to run them is **`--noconftest`**: the live module does its own gating, does not need the conftest,
and when the conftest is absent it seeds a minimal logging config (`tmp/openrouter_live.log` + console) so it never reads a
full-mode `.config.yaml` and never calls manager-api. (It also works with the conftest if you do satisfy the two live-mode
requirements above.) Without `--noconftest` and without the flag, `pytest tests/core/providers -q` still shows the 10 live tests as skipped.

### 13.2 Environment variables

| Variable | Default | Used by |
|---|---|---|
| `OPENROUTER_API_KEY` | – (required) | all |
| `OPENROUTER_MODEL` | `openai/gpt-4o-mini` | all except L3 (if tool model set) and L6/L7 invalid cases |
| `OPENROUTER_TOOL_MODEL` | = `OPENROUTER_MODEL` | L3 |
| `OPENROUTER_FALLBACK_MODELS` | `openai/gpt-4.1-mini` (**not verified to exist; override it**) | L7 |
| `OPENROUTER_BASE_URL` | provider default `https://openrouter.ai/api/v1` | all |
| `OPENROUTER_EXTRA_CONFIG` | – | JSON object merged into every provider config, e.g. `{"data_collection":"deny","provider_only":"DeepInfra"}` |
| `OPENROUTER_L4_RUNS` | `3` | L4 runs per variant |
| `OPENROUTER_LIVE_RESULTS` | `main/xiaozhi-server/tmp/openrouter_live_results.json` | results file path |
| `RUN_LIVE_API_TESTS` | – (must be `1`) | gate |

### 13.3 Results JSON and summary

One file is written at session end (path above; the default `tmp/` folder is git-ignored **[V `git check-ignore`]**). Layout:

```
{ "meta":  { started_at, python, openrouter_sdk, model, tool_model, fallback_models, base_url, key_source, extra_config_keys },
  "tests": { "L1": { "status": passed|failed|skipped, "summary": "...", "observations": { ... } }, ... } }
```

It contains no API key (the key string is also replaced by `<redacted>` in the dumped text) and no prompt text; exception
messages are trimmed to 300 characters. A summary table is printed at the end of the pytest run. If a test fails, the JSON still
holds its observations, but the assertion text only appears in the terminal output, so send both.

### 13.4 How to read each result and what it decides

| Test | Look at (`observations.*`) | Pass condition (asserted) | Decision it feeds |
|---|---|---|---|
| **L1** | `usage_chunk_indexes`, `usage_chunk_choices_empty`, `usage_chunk_is_last`, `usage_after_finish_reason`, `metadata_chunk_indexes`, `chunks[]` (per chunk: n_choices, content_len, has_usage, has_metadata) | one `UsageRecord`, `total_tokens` not None | Plan 5.3: confirms usage is read independently of `choices`. If usage arrives in a chunk **with** choices, or twice, the capture code is still right but the doc/comment should say so. |
| **L2** | `stream_cost`, `generation.total_cost`, `delta_stream_minus_generation`, `generation_available`, `get_generation_tries`, `tokens_match`, `provider_match` | if both costs exist: loose tolerance (`1e-4 + 10 %`); `None` cost is recorded, not failed; unavailable generation after ~29 s of backoff = SKIP | Plan 5.3 / section 12: `cost` None or different from the generation record means the future `get_generation` reconciliation is needed; equal means streaming cost can be trusted. |
| **L3** | `fragment_shape`, `id_only_in_first_fragment`, `merged_calls`, `merge_impl` (`ConnectionHandler` = the real `_merge_tool_calls`, otherwise a copy), `turn2_*` | merged `get_weather` call, arguments parse as JSON with key `city`, second turn returns text | Plan 4.4 and 2.1: the fragment shape of the chosen model. Failing here blocks function-calling for that model (try `OPENROUTER_TOOL_MODEL`). The 2nd turn also sends the exact message shape `core/connection.py` writes (assistant `tool_calls` with an extra `index` key, then a `tool` message) — a 400 would show an SDK/API rejection of that shape. |
| **L4** | `variants[].median_ttft_ms/min/max`, `providers`, `warmup` | every run produced a record (nothing asserted about speed) | Plan 4.1 defaults and section 10: choose `provider_sort` default and whether `record_routing` stays on. Compare `routing_meta` with `default-no_meta` (cost of metadata) and `sort=latency` / `sort=throughput` with default. 3 runs is a small sample; raise `OPENROUTER_L4_RUNS` before deciding. |
| **L5** | `accepted`, `rejected`, `by_value.*.exception` | at least one accepted, else SKIP | Plan 4.1 / 10: write the accepted list into the changelog `remark`. A rejection with `require_parameters=true` may be a 404 "no endpoints" error rather than a 400. |
| **L6** | `invalid_model.exception`, `invalid_key.exception` (`type`, `status_code`), `record.error_type/error_status` | both raise, one record each, `error_type` set | Plan 4.5: the typed exception reaches the caller (`chat()` speaks it). A forced 429 is deliberately not tried. The invalid-key case does send a fake key to OpenRouter (harmless 401). |
| **L7** | per variant: `outcome`, `served_model`, `served_by_fallback`, `selected_provider`, `exception` | a record is emitted for each variant | Plan 4.1 `fallback_models` and 10: document whether an invalid primary is rescued by `models`, and what `requested_model` vs `served_model` look like in the `llm_usage` line. Note the provider sends both `model` and `models`. |
| **L8** | `close_ms`, `record.aborted`, `chunks_taken`, `after_*` | exactly one record, `aborted=True`, `close()` < 3 s, a following call works | Plan 4.6 and Done criteria: interrupt closes the stream with no hang. |
| **L9** | `session_id_sent`, `user_sent`, `cached_tokens_call1/2`, `prompt_tokens_call2` | both calls succeed with `session_id` and `user` | Plan 4.3 / 5.4: confirms the params are accepted. Cached tokens are recorded only (providers cache only above a minimum prompt size, so 0 is not a failure). |
| **L10** | `safe_to_enable`, `validation_error`, `exception`, `selected_provider`, `attempts`, `generation_time_ms`, `metadata_requested` | the call with `record_routing=true` completes, the request really asked for metadata (`enabled`), one record with tokens | Decides whether `record_routing` may be switched on (section 15.7). `safe_to_enable=true` only if the call succeeded **and** the selected provider was parsed. |

Facts in the harness I could not verify: the default fallback model slug, whether `get_generation` is available within ~29 s,
and the real shape of `openrouter_metadata` (the SDK model makes `requested`, `strategy`, `summary`, `is_byok`, `region` and
`endpoints` required — if the real API omits one, a `ResponseValidationError` will abort the stream; it would first show up
in L10 and in the `routing_meta` variant of L4). Because of that risk `record_routing` is off by default; see 15.7 for when to turn it on.

---

## 14. Running in FULL mode, step by step (Windows, from source, no docker)

Source for every step: `docs/Deployment_all.md` (section "方式二：本地源码运行全模块"), `main/manager-api/src/main/resources/application*.yml`,
`main/manager-web/vue.config.js`, `main/xiaozhi-server/config_from_api.yaml`.

### 14.1 Prerequisites

| Tool | Needed | Check (PowerShell) | Source |
|---|---|---|---|
| JDK | 21 | `java -version` | `pom.xml` `java.version` = 21; CI uses 21 |
| Maven | 3.8+ | `mvn -v` | `manager-api/README.md` |
| Node.js + npm | 20 is what CI uses (the repo declares no `engines`) | `node -v; npm -v` | `.github/workflows/test.yml`; minimum not verifiable |
| Python | 3.10 (docs create a conda env with 3.10; the SDK needs >= 3.10) | `python --version` | `Deployment_all.md`, plan section 2.2 |
| MySQL | 8.0+ (docs' docker example uses `mysql:latest`) | `mysql --version` | `manager-api/README.md` |
| Redis | 5.0+ | `redis-cli ping` (expects `PONG`) | `manager-api/README.md` |
| ffmpeg | on `PATH`; `app.py` calls `check_ffmpeg_installed()` and raises `ValueError` if missing | `ffmpeg -version` | `app.py`, `core/utils/util.py` |
| libopus | docs install it with conda (`conda install libopus`); how to provide it with plain pip on Windows is **not documented in the repo** | – | `Deployment_all.md` step 5 |
| ASR model | `models/SenseVoiceSmall/model.pt` for the default FunASR ASR | `Test-Path main\xiaozhi-server\models\SenseVoiceSmall\model.pt` | `Deployment_all.md` step 7 |

### 14.2 Database and Redis

Settings read from `application-dev.yml` (profile `dev` is active in `application.yml`):

| Item | Value |
|---|---|
| JDBC URL | `jdbc:mysql://127.0.0.1:3306/xiaozhi_esp32_server?...` |
| DB user / password | `root` / `123456` (edit `application-dev.yml` if yours differ) |
| Redis | `127.0.0.1:6379`, no password, database 0 |
| API port / context path | `8002` / `/xiaozhi` |

The app does not create the database; Liquibase only creates tables. Create it (command from the docs):

```powershell
mysql -u root -p -e "CREATE DATABASE xiaozhi_esp32_server CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

(The docs also show docker one-liners for MySQL and Redis if you do not have them installed.)

### 14.3 Start manager-api

```powershell
cd C:\MyWorking\Development\xiaozhi-esp32-server_vn\main\manager-api
mvn spring-boot:run          # or: mvn clean package -DskipTests ; java -jar target\xiaozhi-esp32-api.jar
```

`spring-boot-maven-plugin` is in the pom and `finalName` = `xiaozhi-esp32-api`; the docs themselves only describe running
`AdminApplication` from the IDE, so the two CLI forms above are **not covered by the repo docs** (not executed by me).
Success looks like `Started AdminApplication`, and the API docs open at `http://localhost:8002/xiaozhi/doc.html`.

On start Liquibase applies `db/changelog/db.changelog-master.yaml`; I found no explicit `spring.liquibase.*` property, so this is
the Spring Boot default location **[I]**. The new changeSet `202610131200` (author `thangnguyen`) runs `202610131200.sql`.
Verify in MySQL:

```sql
SELECT id, provider_code, name FROM ai_model_provider WHERE id = 'SYSTEM_LLM_openrouter';
SELECT id, model_name, is_enabled FROM ai_model_config WHERE id = 'LLM_OpenRouterLLM';
SELECT id, filename FROM DATABASECHANGELOG WHERE id = '202610131200';
```

Also on start the server secret is generated if it is empty or `"null"` (`SysParamsServiceImpl.initServerSecret`).

### 14.4 Start manager-web and create the admin

```powershell
cd C:\MyWorking\Development\xiaozhi-esp32-server_vn\main\manager-web
npm install
npm run serve                # dev server on http://127.0.0.1:8001 (vue.config.js), proxies /xiaozhi to http://127.0.0.1:8002
```

`npm run build` is the production build (not needed for this test). `VUE_APP_API_BASE_URL=/xiaozhi` is in `.env.development`; change
`vue.config.js` proxy target if manager-api is not on 8002. Because the dev server hot-reloads, the edited `roleConfig.vue`
(function-call gate) is picked up without a separate build.

Open `http://127.0.0.1:8001`, register: the form asks for username, password and a captcha (mobile registration is off by default:
`server.enable_mobile_register` = false). **The first registered user is the super administrator** (docs). Log in with it.

### 14.5 Console settings (super administrator)

Menu names: zh `参数管理` = en "Params Management"; zh `模型配置` = en "Models"; zh `大语言模型` = en "Large Language Model".

1. **Params Management** → copy the value of `server.secret` (generated automatically; it changes on every from-scratch deployment).
2. In the same page set (values from `Deployment_all.md`; use your PC's LAN IP):
   * `server.websocket` = `ws://<LAN-IP>:8000/xiaozhi/v1/`
   * `server.ota` = `http://<LAN-IP>:8002/xiaozhi/ota/`
   * Other relevant defaults seeded by SQL: `log.log_dir` = `tmp`, `log.log_file` = `server.log`, `log.log_level` = `INFO`.

### 14.6 Configure and start the Python server

```powershell
cd C:\MyWorking\Development\xiaozhi-esp32-server_vn\main\xiaozhi-server
python -m venv .venv ; .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt            # now includes openrouter==1.3.43
mkdir data -ErrorAction SilentlyContinue
Copy-Item config_from_api.yaml data\.config.yaml   # docs: if data\.config.yaml already exists, remove it first
```

Edit `data\.config.yaml` so it has the keys the code reads (`config_loader.py`: `custom_config["manager-api"]["url"]` and
`["secret"]`; `url` non-empty switches to full mode):

```yaml
manager-api:
  url: http://127.0.0.1:8002/xiaozhi
  secret: <the server.secret value from Params Management>
```

The copied file also contains a `server:` block (ip `0.0.0.0`, port `8000`, http_port `8003`, vision_explain) which stays local.
**Do not put `selected_module` into this file** in full mode (`check_config_file` raises). Then:

```powershell
python app.py
```

Expected: a line like `Server is running at ws://<ip>:8000/xiaozhi/v1/` (Deployment_all.md). conda is what the docs use; a plain venv is my
substitution (not covered by the docs).

### 14.7 Device or test page

* Real device: `docs/firmware-setting.md` / `docs/firmware-build.md` (point the OTA URL to `server.ota`), then bind the device to
  an agent in the console with the code the device speaks (binding flow: not re-verified here).
* Browser test page: `main/digital-human` — `pip install -r wakeword_runtime/requirements.txt`, then `python start.py` in that folder,
  open `http://127.0.0.1:8006/index.html` (README of that module). How the page is pointed at the Python server (OTA/ws address
  fields) was **not verified**; read `main/digital-human/README.md` and the page itself.

### 14.8 Select OpenRouter and talk

1. Menu **Models** (`模型配置`) → left tab **Large Language Model** (`大语言模型`) → find the row **OpenRouter** (seeded: id
   `LLM_OpenRouterLLM`, `model_code` `OpenRouterLLM`, enabled, not default, provider `SYSTEM_LLM_openrouter`, `provider_code` `openrouter`)
   → **Edit**.
2. Fields (keys from the seeded provider `fields`): `api_key` (replace the placeholder `your_api_key`), `model_name` (default
   `openai/gpt-4o-mini`), `base_url`, `temperature`, `max_tokens`, `top_p`, `frequency_penalty`, `timeout`, `reasoning_effort`,
   `fallback_models`, `provider_sort`, `provider_order`, `provider_only`, `provider_ignore`, `allow_fallbacks`, `require_parameters`,
   `data_collection`, `zdr`, `preferred_max_latency`, `preferred_min_throughput`, `record_routing`, `app_referer`, `app_title`,
   `app_categories`. Seeded config_json: `temperature 0.7`, `max_tokens 500`, `timeout 30`, `allow_fallbacks true`,
   `require_parameters true`, `zdr false`, `record_routing false`. Leave routing fields empty to not send them. Switch
   `record_routing` to `true` only after live test L10 passes (section 15.7).
3. Create or edit an agent (home → **Add agent**) → role config: **Main language model (LLM)** = OpenRouter; **Intent recognition (Intent)**
   = the function-calling option (`Intent_function_call`, "函数调用意图识别"). It is hidden unless the selected LLM `type` is
   `openai`, `ollama` or `openrouter` (`roleConfig.vue`, plan E5); save.
4. Reconnect the device / test page (the config is fetched per connection) and speak.
5. Look for usage lines. Full mode takes `log.*` from Params Management, so by default the file is **relative to the directory
   `app.py` was started from**: `main\xiaozhi-server\tmp\server.log` (rotation 10 MB), and the same text is printed to the console.

```powershell
Select-String -Path tmp\server.log -Pattern "llm_usage" | Select-Object -Last 10
```

Each line is `llm_usage {json}` with `session_id`, `device_id`, `requested_model`, `served_model`, `selected_provider`, token counts, `cost`, `ttft_ms`, ...
Intent/memory LLM calls have an empty `session_id` but carry the `device_id`.

### 14.9 Troubleshooting

| Symptom | Cause / action (based on code and docs) |
|---|---|
| manager-api fails at start with a Liquibase error about checksum | A changeSet file was edited after it was applied. Do not edit `202610131200.sql` once applied; add a new changeSet, or for a throw-away dev DB drop and recreate `xiaozhi_esp32_server` (general Liquibase behaviour, not repo-specific). |
| Duplicate key error from `202610131200.sql` | The SQL deletes `SYSTEM_LLM_openrouter` / `LLM_OpenRouterLLM` before inserting, so a duplicate means another row with the same id from a different source; inspect `ai_model_provider` / `ai_model_config`. |
| "OpenRouter" missing in the console | manager-api was not restarted after the pull, or the changeSet is not in `DATABASECHANGELOG` (14.3 queries); the row is `is_enabled=1`. Hard-refresh the browser. |
| Function-call intent option missing | Dev server not restarted / old build without the `openrouter` entry in `roleConfig.vue`; the check uses the LLM's `config_json.type`. |
| Java cannot connect to DB/Redis | credentials in `application-dev.yml` (14.2); database `xiaozhi_esp32_server` must exist. |
| `app.py`: "Failed to fetch server config from API" | manager-api not running, wrong `url`, or wrong `secret` (secret must equal the current `server.secret`; it changes after a from-scratch deployment). |
| 401 from OpenRouter in the log | wrong or still-placeholder `api_key` (the placeholder check in the code only flags values containing `你`, `your_api_key` is not caught). Error type appears as `UnauthorizedResponseError` / `error_status 401` in `llm_usage`. |
| Device cannot connect | `server.websocket` must be the LAN IP (not 127.0.0.1) and reachable from the device; Windows firewall for ports 8000, 8002, 8003. |
| Startup error about ffmpeg | `ffmpeg -version` must work in the same shell (`check_ffmpeg_installed`). |
| `opuslib_next` import/DLL error | libopus missing; the docs use `conda install libopus`; plain-pip route on Windows not documented. |
| `pytest` aborts with "FAIL: 检测到全模块部署" | conftest exit 2 because `data\.config.yaml` is in full mode; use `--noconftest` (section 15). |

### 14.10 Minimal mode (YAML only) for quick iteration

No Java/MySQL/Redis/console. Move any full-mode `data\.config.yaml` aside, then create `data\.config.yaml`:

```yaml
selected_module:
  LLM: OpenRouterLLM
LLM:
  OpenRouterLLM:
    type: openrouter
    model_name: openai/gpt-4o-mini
    api_key: <your key>
    timeout: 30
    # fallback_models: ... / provider_sort: latency / reasoning_effort: low   (optional, see config.yaml example)
```

`config.yaml` already has `Intent: function_call` selected and a commented OpenRouter example. Run `python app.py`; the usage lines go to
`tmp\server.log`. The live tests (section 15) do not need the console at all.

---

## 15. Running the live tests

### 15.1 Commands (PowerShell)

```powershell
cd C:\MyWorking\Development\xiaozhi-esp32-server_vn\main\xiaozhi-server
.\.venv\Scripts\Activate.ps1                      # the venv from 14.6 (needs: pip install -r requirements.txt, pytest)
$env:RUN_LIVE_API_TESTS = "1"
$env:OPENROUTER_API_KEY = "sk-or-v1-..."          # your key
# optional:
# $env:OPENROUTER_MODEL = "openai/gpt-4o-mini"
# $env:OPENROUTER_FALLBACK_MODELS = "<a second valid model slug>"
# $env:OPENROUTER_TOOL_MODEL = "<model that supports tools>"

pytest tests/core/providers/test_openrouter_live.py -s -q --noconftest -p no:cacheprovider
```

One test: `pytest tests/core/providers/test_openrouter_live.py -s -q --noconftest -p no:cacheprovider -k L3` (also `-k "L1_ or L2"`;
note `-k L1` would also select L10, so use `L1_` for L1 alone).
`pytest` itself is not in `requirements.txt` (CI installs `pytest pytest-asyncio freezegun`), so `pip install pytest` in the venv if needed.
When done: `Remove-Item Env:OPENROUTER_API_KEY, Env:RUN_LIVE_API_TESTS`.

If the key is missing or the flag is not `1`, all 10 tests show as `s` (skipped) with the reason in `-rs` output.

### 15.2 Cost

Roughly 30 short API calls: most use `max_tokens` 16-64; L3 128; L8 300 but aborted after 3 chunks; L9 sends a ~1.3k-token
system prompt twice. At `gpt-4o-mini`-class prices this is a very small amount; the actual price depends on the models you pick
(check the model page on openrouter.ai; not verifiable from the repo). A reasoning model can spend its output budget on thinking and return
empty text — pick a non-reasoning model for the default run.

### 15.3 Outputs

| What | Where |
|---|---|
| Results JSON | `main\xiaozhi-server\tmp\openrouter_live_results.json` (or `$env:OPENROUTER_LIVE_RESULTS`) |
| Table | printed at the end of the pytest run |
| `llm_usage` lines of the live run | `main\xiaozhi-server\tmp\openrouter_live.log` (console too) |
| `llm_usage` lines of the full-mode server | `main\xiaozhi-server\tmp\server.log` |

```powershell
Select-String -Path tmp\openrouter_live.log -Pattern "llm_usage" | ForEach-Object { $_.Line } | Set-Content tmp\llm_usage_live.txt
```

### 15.4 What to send back

1. `tmp\openrouter_live_results.json`
2. the pytest terminal output (assertion messages are only there)
3. `tmp\llm_usage_live.txt` and the `llm_usage` lines from the full-mode run (section 14.8)
4. the exact model slugs you used (`meta` in the JSON already has them)

Check before sending that no secret is inside (the tool redacts the key from the JSON; it never writes prompts).

### 15.5 Pass criteria (mirrors section 11 "Done criteria")

- [ ] Offline tests pass: `pytest tests/core/providers -q` (needs a git-ignored `data/.config.yaml`; `{}` is enough) — 47 passed at the time of writing, plus 10 skipped live tests.
- [ ] **L1** passes (one record, tokens captured) and the usage chunk layout is documented.
- [ ] **L2** result recorded (cost present or `None` noted).
- [ ] **L3** passes: tool arguments rebuilt into valid JSON, and a final text answer after the tool result.
- [ ] **L8** passes: `aborted=True`, one record, prompt close, next call works. ("Interrupt leaves no open connection".)
- [ ] **L10** result recorded (`safe_to_enable`); `record_routing` stays off unless it is `true` (section 15.7).
- [ ] L4, L5, L6, L7, L9 results written into the changelog `remark` / this plan (no pass/fail threshold).
- [ ] Full mode: OpenRouter selectable in the console, saved with routing fields, applied on the next connection.
- [ ] Full mode: streaming chat and a tool call work through the agentic loop.
- [ ] Full mode: every LLM call (chat, function, intent, memory) produces exactly one `llm_usage` line with tokens, cost when reported,
      served model/provider, TTFT, `session_id` and `device_id`.
- [ ] `git status` shows no modified existing provider file (only the listed E1–E8 edits).

### 15.6 What was and was not verified before handing over

* Verified offline: 47 tests pass; the 10 live tests are collected and skip with a clear reason (no flag / no key); the whole
  live file runs green against a scratch `httpx.MockTransport` that fakes `/chat/completions` (text, tool-call fragments, usage-only
  trailing chunk, 400/401/404 errors, 200-chunk stream) and `/generation` (two 404s, then data). That caught typos and a schema
  detail (`openrouter_metadata` required fields) and proves the test logic, the JSON writer and the redaction.
* Not verified: anything depending on the real API — real chunk layout, real cost values, model availability, the default fallback
  slug, `get_generation` lag, real abort behaviour of the HTTP stream (the mock closes instantly), and — most relevant to 15.7 —
  whether the real `openrouter_metadata` contains every field the SDK model requires.

### 15.7 `record_routing`: when to turn it on

**What it is.** With `record_routing: true` the provider sends `x_open_router_metadata="enabled"`, OpenRouter adds `openrouter_metadata`
to the response, and the `llm_usage` line gains `selected_provider`, `attempts` and `generation_time_ms` (which provider actually served
the call, how many tries, generation time). With it off, `llm_usage` still has tokens, cost, `served_model`, TTFT, `session_id` and
`device_id`; only those three fields are missing.

**Why it is off by default.** The SDK model for `openrouter_metadata` requires `requested`, `strategy`, `summary`, `is_byok`, `region`
and `endpoints`. If the real API omits any of them, the SDK raises `ResponseValidationError` on the first stream chunk and the whole
call fails, not just the metadata. That has not been observed (nothing has run against the real API); it is a risk of an unverified
response shape, so the switch is off until a live call proves it.

**When to turn it on** — in this order:

1. Run the live tests with `record_routing` off (the default) and get L1, L3 and L8 passing (section 15.5). Nothing else depends on it.
2. Run the gate test:
   ```powershell
   pytest tests/core/providers/test_openrouter_live.py -s -q --noconftest -p no:cacheprovider -k L10
   ```
3. Read the L10 entry in `tmp\openrouter_live_results.json` (and the summary line `L10 ... safe_to_enable=...`):

   | L10 result | Meaning | Action |
   |---|---|---|
   | `safe_to_enable: true` (test passed, `selected_provider` named, `generation_time_ms` usually set) | The real response parses and names the provider | Turn it on (below), then compare TTFT in L4: `routing_meta` vs `default-no_meta` (3 runs is small; raise `OPENROUTER_L4_RUNS`). Keep it on if the TTFT difference is within noise for you. |
   | test **failed**, `validation_error: true` | The real response is missing a field the SDK requires | Leave it **off**. Send me the JSON and the terminal output; the provider can be made tolerant (e.g. parse the metadata defensively) before enabling. |
   | test passed but `safe_to_enable: false` (`selected_provider` is `None`) | Response parses but contains no usable provider name | Optional: leave it off (you lose only the provider name and generation time), or send me the JSON to adjust the extraction. |
   | test **failed**, other `exception` (401/402/404/429/5xx) | Not a metadata problem (key, credit, model, rate limit) | Fix the cause and re-run L10. |
4. Optional, after L10 is green: in L4, check that the extra metadata does not slow the first token noticeably for your model/routing.

**How to turn it on** (pick the place you use; `true` / `false`):

| Where | How |
|---|---|
| Full mode (console) | Model config → LLM → OpenRouter → field **Record routing metadata (selected provider) in usage log** → `true` → save. Applied on the next device connection. |
| YAML / minimal mode | `LLM.OpenRouterLLM.record_routing: true` in `data/.config.yaml` (restart `python app.py`). |
| Live tests only | `$env:OPENROUTER_EXTRA_CONFIG = '{"record_routing": true}'` — but note L1–L9 already work with it off, and L4/L10 set it themselves. |

Do **not** edit `202610131200.sql` to change the seeded value after the backend has applied it: Liquibase stores a checksum and a changed
file stops the next start. The seeded value is `false`; change it in the console instead.

**How to check it works in full mode.** After the next conversation, the `llm_usage` line in `tmp\server.log` should contain
`"selected_provider": "<name>"` and `"generation_time_ms": <number>`:
```powershell
Select-String -Path tmp\server.log -Pattern "llm_usage" | Select-Object -Last 3
```

**How to turn it back off.** Set the field to `false` (or clear it) and reconnect the device. If a conversation suddenly produces
no answer after enabling it, check the log for `OpenRouter response validation failed` (the provider logs the raw body, trimmed to
500 characters) and switch it off first, then send me that log line.
