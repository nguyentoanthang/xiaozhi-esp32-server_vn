# Setup, test and measurement guide (minimal server)

Three parts, meant to be followed in order:

1. [Setup, configure and run](#part-1-setup-configure-and-run)
2. [Test checklist](#part-2-test-checklist) (what to tick before you trust it)
3. [Measurement checklist](#part-3-measurement-checklist-phase-6) (phase 6: resource use before/after)

Nothing in this guide has been run against a real device, a live OpenRouter key or Docker yet: that is exactly what
part 2 is for. Where a step says "expected", it is what the code is designed to do, not something already observed.

Conventions: commands are run from `main/xiaozhi-server` unless stated. SQL is shown for the `sqlite3` CLI; on Windows
without it, use [DB Browser for SQLite](https://sqlitebrowser.org/).

---

## Part 1: Setup, configure and run

### 1.1 What you need

| Item | Why |
|---|---|
| OpenRouter API key | The seeded LLM **and** speech-to-text both use it |
| Python 3.10+ (or Docker) | Python 3.12 is what the tests were run on here; CI uses 3.10 |
| `ffmpeg` and `libopus` | Opus encode/decode (history audio, TTS). Windows: install ffmpeg and make sure `opus.dll` can be found (conda: `conda install libopus ffmpeg`) |
| A phone/PC on the same LAN as the device | The device talks to the server over the LAN |
| An xiaozhi ESP32 device with firmware pointed at your OTA URL (part 1.7) | Optional until step 2.4; steps before that need no device |

### 1.2 Install (from source)

```powershell
cd main\xiaozhi-server
conda activate xiaozhi-esp32-server
pip install -r requirements.txt
```

`requirements.txt` still contains the heavy local-model packages (torch/funasr for the optional FunASR). If you only use
OpenRouter STT you can leave them installed (they are only imported when FunASR is selected), but they dominate image/environment size.

The `xiaozhi-esp32-server` Conda environment supplies the native Opus library on Windows. Do not invoke a stale
`.venv\Scripts\python.exe`; use `python` only after activating the Conda environment. `requirements.txt` includes the
pytest tools used by the first checklist command.

### 1.3 First start (database is created and seeded for you)

```powershell
python app.py
```

Expected in the log (`tmp/server.log`, also on the console):

- `No default agent in ...; seeding the database with defaults` then `Seeded: setting=..., model_config=8, agent=1`
- `OTA endpoint is http://<ip>:8003/xiaozhi/ota/`
- `Websocket address is ws://<ip>:8000/xiaozhi/v1/`

The file is `data/xiaozhi.db`. To start from scratch at any time: stop the server, delete `data/xiaozhi.db*`, start again.
Seed manually (does the same, idempotent): `python -m core.db.seed`.

> `data/.config.yaml` is **not needed**. Only create it to override `db.path`, `log`, or `server.ip/port/http_port/auth_key`.

### 1.4 Put in your OpenRouter key (required before any voice works)

Edit `main/xiaozhi-server/.env` (the `.env` beside `app.py`) and enter your key:

```dotenv
OPENROUTER_API_KEY=sk-or-v1-your-key-here
```

For a fresh checkout, copy `.env.example` to `.env` first. Git ignores `.env`.
The server loads this file automatically, independent of the working directory. The same key is used for
OpenRouter LLM and ASR, including per-device agents and the memory LLM. An existing `OPENROUTER_API_KEY`
environment variable takes priority over the file, even if that variable is empty.

Restart the server after changing the key: shared providers are built at startup. A missing or empty key
causes OpenRouter calls to fail. The key is injected into runtime configuration and is never written to SQLite;
any old OpenRouter `api_key` values in the database are ignored. Model names stay in the database (section 1.5).

### 1.5 The three things you will want to change on day one

**a) The speech-to-text model id.** The seed uses `openai/whisper-large-v3` as a *placeholder*.
The local server database now uses `elevenlabs/scribe-v2`, verified by a live transcription on
2026-10-18. To set this model in another database:

```sql
UPDATE model_config SET config_json = json_set(config_json,'$.model_name','elevenlabs/scribe-v2') WHERE id='ASR_OpenRouter';
-- optional: a language hint, e.g. 'vi' (empty = auto-detect)
UPDATE model_config SET config_json = json_set(config_json,'$.language','vi') WHERE id='ASR_OpenRouter';
```

**b) The LLM model** (seed: `openai/gpt-4o-mini`):

The local configuration now uses `deepseek/deepseek-v4.1-flash-1017`, restricted to `relace`
with provider and model fallbacks disabled. One short streaming request passed on 2026-10-18
(9 input tokens, 2 output tokens, reported cost USD 0.00000165). Full speech conversation
remains unverified. The earlier free Gemma model returned HTTP 429.

```sql
UPDATE model_config SET config_json = json_set(config_json,
  '$.model_name','deepseek/deepseek-v4.1-flash-1017',
  '$.provider_order',json('["relace"]'), '$.provider_only',json('["relace"]'),
  '$.allow_fallbacks',json('false'), '$.fallback_models',json('[]')) WHERE id='LLM_OpenRouter';
```

**c) Voice and persona.** The seeded TTS voice is Chinese (`zh-CN-XiaoxiaoNeural`) and the seeded prompt is the upstream
"Taiwanese Gen-Z girl" persona. For Vietnamese use, on the default agent:

```sql
UPDATE agent SET tts_voice = 'vi-VN-HoaiMyNeural' WHERE is_default = 1;       -- or vi-VN-NamMinhNeural
UPDATE agent SET system_prompt = 'You are a friendly voice assistant. Answer briefly in the language the user speaks.'
 WHERE is_default = 1;
```

(`agent.tts_voice` is passed to EdgeTTS as the voice for that agent; test item 2.3 confirms it really changes the voice.)

Agent and device edits apply to the **next connection** (disconnect/reconnect the device). Model rows (VAD/ASR/LLM) and `server.*`
are read at startup: **restart** the server after changing them.

### 1.6 Settings reference (table `setting`; values are JSON)

Strings need their own quotes: `UPDATE setting SET value = '"text"' WHERE key = '...'`; booleans/numbers do not (`'true'`, `'7'`).

| Key | Default | Meaning |
|---|---|---|
| `server.websocket` | placeholder with `your_ip` | URL the OTA reply gives devices. While it contains `your_` the server auto-detects the LAN IP. Set it explicitly behind Docker or a domain: `'"ws://192.168.1.25:8000/xiaozhi/v1/"'` |
| `server.http_base_url` | not set | Base URL for firmware download links (only if you serve `.bin` from `data/bin`) |
| `server.timezone_offset` | `7` | Hours from UTC reported to the device |
| `server.auth.enabled` | `false` | WebSocket token auth (off on a trusted LAN) |
| `device.auto_register` | `true` | Unknown MAC is added to the default agent. `false` = unknown devices are refused (close code 1008) |
| `tools.server_plugins_enabled` | `false` | `false` = no server plugin (weather, news, music, ...) reaches the LLM |
| `guardrails.enabled` | `true` | Master switch for masking names/phones/emails/cards in **user** text |
| `guardrails.mask_email` / `mask_phone` / `mask_card` / `mask_name` | `true` | Per-type switches |
| `guardrails.restore_in_reply` | `false` | `true` puts the real values back in the reply before TTS |
| `exit_commands` | `exit, quit, goodbye` | Spoken words that end the conversation |
| `close_connection_no_voice_time` | from `config.yaml` | Seconds of silence before the server ends the conversation |
| `end_prompt.enable` / `end_prompt.prompt` | from `config.yaml` | Short goodbye the LLM says when the conversation ends |
| `device_max_output_size` | `0` | Max characters spoken per device per day (0 = unlimited) |

Models (`model_config`): ids are `VAD_SileroVAD`, `ASR_OpenRouter` (enabled), `ASR_FunASR` (disabled), `LLM_OpenRouter`,
`TTS_EdgeTTS`, `Memory_mem_local_short`, `Memory_nomem`, `Intent_function_call`. A disabled row cannot be selected by an agent.

Agent columns: `id, name, is_default, system_prompt, language, vad_id, asr_id, llm_id, tts_id, mem_id, intent_id, tts_voice,
tts_params_json, history_mode (0 off / 1 text / 2 text+audio), plugins_json, mcp_endpoint, context_providers_json`.

Other tables you edit by hand: `device` (`mac` in **lower case**, `agent_id`, `alias`), `replacement_word` (`source`, `target`,
global when `agent_id` is NULL), `guardrail_name` (`name`, `enabled`).

### 1.7 Point the device at the server

1. Find the PC's LAN IP (`ipconfig`). The OTA URL is `http://<LAN IP>:8003/xiaozhi/ota/`.
2. Open that URL in a browser: it must say the OTA interface is running and show the WebSocket URL devices will receive.
3. Set the OTA URL in the device firmware (see [firmware-setting.md](./firmware-setting.md) / [firmware-build.md](./firmware-build.md)).
4. Windows: allow inbound TCP 8000 and 8003 in the firewall for the private network.
5. If the WebSocket URL in step 2 shows the wrong address, set `server.websocket` (1.6) and reload the page.

### 1.8 Add an agent / assign a device

```sql
INSERT INTO agent(id, name, system_prompt, vad_id, asr_id, llm_id, tts_id, mem_id, intent_id, history_mode)
VALUES ('kids', 'Kids helper', 'You are a friendly helper for children.',
        'VAD_SileroVAD', 'ASR_OpenRouter', 'LLM_OpenRouter', 'TTS_EdgeTTS', 'Memory_nomem', 'Intent_function_call', 2);

UPDATE device SET agent_id = 'kids' WHERE mac = 'aa:bb:cc:dd:ee:ff';       -- takes effect on the next connection
```

A device row appears by itself the first time the device connects (auto-register). List them: `SELECT * FROM device;`.

### 1.9 Run with Docker (after the source run works)

```powershell
cd main\xiaozhi-server
docker compose up -d --build
docker logs -f xiaozhi-esp32-server
```

- One service, one volume `./data` (holds `xiaozhi.db`). An empty `./data` is fine (auto-seed).
- Do step 1.4 against `./data/xiaozhi.db` on the host, then `docker compose restart`.
- Inside Docker the auto-detected IP is the container's. **Set `server.websocket`** (1.6) to `ws://<host LAN IP>:8000/xiaozhi/v1/`.
- The image has never been built in this repo's history: if the build fails, that is a finding to fix, not user error.
- Logs: `docker logs`, plus `tmp/server.log` inside the container.

### 1.10 Everyday commands

```sql
-- latest conversations
SELECT s.started_at, s.device_mac, s.agent_id, s.title FROM chat_session s ORDER BY s.started_at DESC LIMIT 10;
-- one conversation
SELECT chat_type, content, audio_id FROM chat_message WHERE session_id = '<id>' ORDER BY id;     -- 1 user, 2 agent, 3 tool
-- usage and cost
SELECT * FROM usage_by_device ORDER BY day DESC;
SELECT * FROM usage_by_agent  ORDER BY day DESC;
-- a device's memory
SELECT device_mac, summary, updated_at FROM memory;
```

Back up = copy `data/xiaozhi.db` while the server is stopped (WAL mode also creates `-wal`/`-shm` files; copy all three or stop first).

---

## Part 2: Test checklist

Tick each box. Stop at the first failure and look at `tmp/server.log` before going on. "Evidence" is what to check.

Latest run: [2026-10-18 testing progress](./testing-progress-2026-10-18.md). The live provider and WebSocket
checks used isolated databases under `main/xiaozhi-server/tmp/`. WebSocket checks used a scripted client;
physical ESP32 behavior, screen output, and audible speech are still unverified.
The later [device-free checklist report](./headless-checklist-test-2026-10-18.md) records actual server,
browser, storage, memory, guardrail, usage, protocol, and robustness checks. Physical-device items below
remain separate; failed software checks also remain unchecked.

English is the default testing language. The user subsequently requested three Vietnamese
conversation samples for listening review; those results are recorded separately in the
[Vietnamese conversation report](./vietnamese-conversation-test-2026-10-18.md).
Test-only language overrides do not change the configured production voice or ASR language.

### 2.0 Offline (no key, no device)

- [x] `python -m pytest tests -q --continue-on-collection-errors`: no failures; review skipped tests.
      Latest run after upgrading Edge TTS to 7.3.0: **280 passed, 15 skipped**, including all four TTS tests.
      English voice supplied via `PYTEST_CONFIG_FILE=tmp/english-pytest-config.yaml`; a fresh `--basetemp`
      directory avoided an inaccessible old Windows Temp directory. The TTS synthesis test uses the network even
      in mock mode. Skips: 10 paid live OpenRouter cases, 3 placeholder-key LLM cases, 2 configuration-dependent
      module checks. One harmless pytest cache permission warning; evidence: `tmp/pytest-edge730-results.txt`.
- [x] Delete `data/xiaozhi.db*`, run `python -m core.db.seed`, run it again: second run prints `Rows added: setting=0, model_config=0, agent=0`.
- [x] `sqlite3 data/xiaozhi.db "PRAGMA user_version; SELECT count(*) FROM model_config;"` -> `1` and `8`.
- [x] Configuration/database pytest checks pass, including `.env` key loading, environment override precedence, and startup/per-device configuration without saving secrets to SQLite.
      Earlier focused run: 104 passed; six secret-loading cases are in `tests/core/db/test_provider_secrets.py`. This does not imply the entire suite passes.

### 2.1 Startup

- [x] Fresh `data/` (no db): `python app.py` starts without error and logs the seeding lines.
- [x] Start again: **no** seeding lines (the DB already has a default agent).
- [x] Open `http://<LAN IP>:8003/xiaozhi/ota/` in a browser: message says it is running and shows the WebSocket URL.
- [x] Delete a non-default seed row (e.g. a `setting`), restart: it is **not** re-created (auto-seed only when no default agent).
- [ ] Docker only: `docker compose up -d --build` builds; the container stays up (`docker ps`); same OTA page works via the host IP.

### 2.2 First device connection

- [ ] Power the device, it fetches OTA and connects. Evidence: `SELECT mac, agent_id, last_connected_at FROM device;` shows the device, lower-case MAC, agent `default`.
- [x] Scripted real WebSocket client receives `hello` with a session ID; an uppercase MAC registers in lowercase with agent `default` and `last_connected_at` populated.
      Verified against actual `app.py` using an isolated database; `tmp/configured_websocket_results.json`. Physical device boot remains unchecked above.
- [x] Set `device.auto_register` to `false`, delete the device row, reconnect: the device is refused and no row is created. Set it back to `true`.
      Verified 2026-10-18 using a real WebSocket client and a database copy; received `device_refused`, connection closed, no device row remained. Restored `true` in the copy.
- [x] Log shows no `NoDefaultAgent`, no traceback on connect.
      Verified for both accepted and refused WebSocket connections; evidence: `tmp/configured_websocket_server.log`.

### 2.3 Conversation (needs the key from 1.4)

- [ ] Say a simple sentence ("what is two plus two"): you hear a spoken answer; the device screen shows what you said.
- [ ] Log shows an ASR line with your text (this is the **OpenRouter STT** path), an LLM call, a TTS line. Note the time from end of speech to first sound: ______ s (compare with FunASR in 2.8).
- [ ] Wrong key (temporarily blank `OPENROUTER_API_KEY` in `.env`, ensure no environment override, and restart): the conversation does not crash; the device gets the system error reply; the log shows the OpenRouter error; the server keeps running. Restore the key and restart afterward.
      Failed for the actual speech path: missing ASR key produced no system/error reply within 50 seconds,
      although the server stayed alive. Recognized-text input did receive the LLM error reply. Tested with
      an empty environment override in a child process, leaving the real `.env` unchanged.
- [ ] Test agent's `tts_voice` changed to an English voice (for example `en-US-JennyNeural`) and device reconnected: the voice changes. If not, record it as a bug.
- [ ] Say "goodbye" (also try "exit", "quit"): the conversation ends and the end prompt is spoken if `end_prompt.enable` is on.
      All three commands closed the scripted connection, but explicit goodbye produced zero audio packets
      with `end_prompt.enable=true`; closing prompt requirement failed. The silence-triggered prompt did work.
- [x] Stay silent for `close_connection_no_voice_time` seconds: the server ends the conversation.
      Real Opus silence packets, test-only timeout 2 seconds: closed with end prompt disabled; with it enabled,
      server spoke the configured English goodbye and closed. Evidence: headless protocol and edge-case reports.
- [ ] Interrupt the device mid-reply: speech stops, a new question is answered.
- [x] Scripted client interrupts an active audio reply: receives TTS `stop`, then a new question gets correct reply audio.
      Verified abort/new-question protocol; physical speaker playback remains unverified.
- [x] Real WebSocket audio input produces STT/LLM/TTS activity and reply audio; browser shows the recognized text and reply.
      First baseline `listen.stop` to first outgoing audio packet: 5.719 seconds. This is packet timing, not
      end-of-speech to first physical sound. Browser screenshot and logs are linked in the device-free report.
- [x] Reconnect a scripted client after changing the test agent's English voice: actual Edge TTS requests use the new voice and return audio.
      Captured provider boundary switched from `en-US-JennyNeural` to `en-US-GuyNeural`; no listener judgement claimed.
- [x] With a missing LLM key, recognized-text input receives a system error reply/audio and the OTA endpoint stays HTTP 200.
      This passing text path does not cover the failed ASR-key error-reply path above.

#### Provider workflow checks (no physical device)

These use the real server provider classes and APIs with isolated usage databases. They do not
exercise microphone capture, VAD/Opus transport, `ConnectionHandler`, history, or memory.
Generated reply audio is decoded and checked for a non-silent signal; listener/device playback is unverified.

- [x] Scribe accepts 16 kHz mono 16-bit PCM and transcribes a known English recording correctly.
      2026-10-18: the 4.9-second recording "What is two plus two? Answer in one short English sentence."
      was transcribed exactly using `elevenlabs/scribe-v2`, with test-only `language=en`.
- [x] DeepSeek streaming works with Relace-only routing and provider/model fallbacks disabled.
      Minimal check returned `OK` with 9 input / 2 output tokens; reported cost USD 0.00000165.
- [x] Send the actual English ASR transcript directly to the LLM as its user message; verify the answer.
      `deepseek/deepseek-v4.1-flash-1017` through `relace` answered "Two plus two equals four."
      One ASR call and one LLM call; 32-token output cap, reasoning disabled, no retries/fallbacks.
      Combined duration 3,047 ms; LLM used 17 input / 7 output tokens. Evidence: `tmp/english_asr_to_llm_results.json`.
- [x] Invalid ASR key returns empty text without raising to the caller and adds no usage row.
      Earlier real Scribe HTTP 401 check; `tmp/configured_provider_results.json`.
- [x] Invalid LLM model/key produces HTTP 400/401 respectively, with exactly one error usage event per request.
      Earlier live L6 acceptance check passed; `tmp/configured_openrouter_errors.json`.
- [x] English Edge TTS produces valid reply audio through the server's `TTSProvider` using installed `edge_tts==7.3.0`.
      Actual LLM reply "Two plus two equals four." became a 15,696-byte MP3, decoded to 2,616 ms,
      24 kHz mono, RMS 3,394; voice `en-US-JennyNeural`. This supersedes the earlier 7.2.8 HTTP 403 failure.
- [x] English audio -> Scribe -> actual transcript -> DeepSeek/Relace -> actual answer -> Edge TTS completes without mocks.
      One ASR call and one LLM call (17 input / 7 output tokens, 32-token cap); elapsed 3,579 ms to saved/decoded audio.
      Reported ASR/LLM cost USD 0.000154772222222195. Evidence: `tmp/english_asr_llm_tts_results.json`;
      audio: `tmp/english-asr-llm-tts-reply.mp3`. Physical-device speech and time to first audible sound remain unchecked.
- [x] Upgrade only Edge TTS to 7.3.0 in `xiaozhi-esp32-server`, pin that version in `requirements.txt`, and verify dependency compatibility.
      Installed the checksum-verified wheel with `--no-deps`; `pip check` returned `No broken requirements found` before and after.
- [x] Run three Vietnamese two-turn provider conversations: ASR transcript -> LLM with previous turns -> Vietnamese reply TTS.
      Arithmetic, geography, and name context produced six correct written replies and six valid final audio files.
      Two TTS calls initially returned no audio and succeeded on retry; this does not establish uninterrupted reliability.
      [Transcripts and recordings](./vietnamese-conversation-test-2026-10-18.md). Total reported paid cost USD 0.000648833333333229.
- [ ] User confirms Vietnamese pronunciation and reply audio quality after listening to the three recordings.

### 2.4 History, audio, titles

- [x] After a conversation ends: `SELECT * FROM chat_session ORDER BY started_at DESC LIMIT 1;` has `ended_at`, a `title` and a `summary`.
- [x] `chat_message` has user (type 1) and agent (type 2) rows in the right order.
- [x] `SELECT m.chat_type, a.format, a.sample_rate, length(a.data) FROM chat_message m JOIN chat_audio a ON a.id=m.audio_id WHERE m.session_id='<id>';` has rows for both sides, `format = opus-frames`, non-zero length.
      Real speech session against a database copy; stored user/assistant clips also unpacked and decoded as
      non-silent audio. Temporary WAV exports and metadata: `tmp/headless-audit.json`.
- [x] `UPDATE agent SET history_mode = 1 ...`, reconnect, talk: new messages have **no** `audio_id` and no new `chat_audio` rows. `history_mode = 0`: nothing is stored. Set back to `2`.
      Verified both modes through real WebSocket conversations; restored mode 2 in the test database.

Known gap: there is no product UI for stored-audio playback. The test audit decoded the clips to temporary WAVs;
the stored container is length-prefixed Opus packets, see `core/db/chat_history.py`.

### 2.5 Memory (per device)

- [x] Tell the assistant a fact ("my dog is called Rex"), end the conversation. `SELECT * FROM memory;` has a row for **that device's MAC** with a JSON summary.
- [x] Reconnect, ask "what is my dog called": the answer uses the memory.
- [x] `UPDATE agent SET mem_id = 'Memory_nomem' ...`, reconnect, say something new, end: the `memory` row for that device does not change. Set back to `Memory_mem_local_short`.
- [x] Two clients on the same agent keep **different** memory rows.
      Two scripted MACs independently retained Rex/Luna; nomem left the existing row unchanged. Memory modes
      were exercised only in copied databases; the main database was not changed.

### 2.6 Guardrails

Setup: `INSERT INTO guardrail_name(name) VALUES ('John Smith');`, reconnect.

- [ ] Say "my phone number is 0912 345 678": `SELECT content FROM chat_message ... ORDER BY id DESC` shows `[PHONE_1]`, not the number; the device screen still shows what you said.
      Failed with real English speech: ASR returned the digits as words, which were stored/logged unmasked.
      Numeric recognized-text injection did mask successfully; the actual speech requirement stays unchecked.
- [x] Say an email address: stored as `[EMAIL_1]`.
      Real English audio recognized `john.smith@example.com`; stored text had `[EMAIL_1]` and INFO log contained no raw email.
- [ ] Say a valid test card number (`4111 1111 1111 1111`): stored as `[CARD_1]`. Say a 16-digit number that fails the Luhn check (`1234 5678 9012 3456`): **not** masked.
      Real speech returned card digits as words and did not mask them. Numeric recognized-text injection
      passed both valid/invalid-card cases, but the speech path remains unchecked.
- [x] Say "John Smith": stored as `[NAME_1]`. A name that is not in the table is not masked.
      Real audio masked John Smith and preserved Alice Johnson; actual subtitle showed the original text.
- [ ] Say the same phone number twice in one conversation: both become `[PHONE_1]`; a different number becomes `[PHONE_2]`.
      Numeric recognized-text path passed; speech-to-number-words gap prevents marking the full speech case.
- [ ] `grep` the log for the raw number/email/card: **no hits** (`Select-String -Path tmp\server.log -Pattern "0912"` on Windows).
      Spoken number words appeared in normal INFO logs. A digit-only grep misses this failure; item remains unchecked.
- [ ] The LLM does not repeat the number (it never received it). Check the `memory` summary too.
      Recognized numeric-text input and its memory summary stayed masked; number-word ASR output still reaches
      downstream processing, so the overall speech privacy claim remains unchecked.
- [x] `UPDATE setting SET value='false' WHERE key='guardrails.enabled';` + reconnect: recognized text is stored unmasked (switch really works). Set back to `true`.
      Guardrail settings reload per connection; verified disabled/enabled transitions in an isolated database.
- [ ] Optional: `guardrails.restore_in_reply` = `true` + restart: when the LLM repeats a placeholder, the spoken reply contains the real value.
      Failed at the actual TTS boundary: trailing `[PHONE_1]` became `[PHONE_1` during reply cleanup, so restoration could not match it.
- [x] Recognized numeric text masks phone/email/card/name, keeps repeated placeholder numbering stable, and preserves the original subtitle.
      Real WebSocket `listen.detect` path; this component check does not remove the spoken-number failures above.
- [x] With masking enabled, a recognized-text conversation's persisted JSON memory contains placeholders and no raw test phone/email/name.

Known limit: only user text is masked; outgoing LLM/TTS content is not independently screened. Stored audio contains original speech.

### 2.7 Usage and cost

- [x] After a conversation: `SELECT kind, purpose, requested_model, served_model, prompt_tokens, completion_tokens, cost, device_mac, agent_id FROM ai_usage ORDER BY id DESC LIMIT 20;`
      shows `chat`, `title` and `memory` LLM rows and one `stt` row per utterance, all with the right `device_mac` and `agent_id`.
      Verified all four purposes in one real audio session with memory enabled; see the complete-usage evidence in the device-free report.
- [x] `cost` is filled for OpenRouter rows (if NULL everywhere, OpenRouter did not return it for that call; note it).
      All four successful purpose rows in that session had non-null provider-reported costs; no dashboard reconciliation is claimed.
- [x] Provider-level English ASR-to-LLM test records exactly one `stt` and one `llm`/`chat` row with matching session, device, and agent; both costs are populated.
      `tmp/english_asr_to_llm.db`: STT `audio_seconds=4.9`, cost USD 0.000149722222222195;
      LLM cost USD 0.00000505; total USD 0.000154772222222195. Title/memory/conversation usage remains unchecked above.
- [x] `stt` rows have `audio_seconds` set. A deliberately failed STT call (wrong key) writes **no** row.
      Verified 2026-10-18 against real Scribe calls in `tmp/configured_provider_tests.db`: successful 10-second calls had `audio_seconds=10`; HTTP 401 calls returned empty text and added no usage row.
- [x] Move the device to another agent (`UPDATE device SET agent_id='kids' ...`), reconnect, talk. Old rows keep the old `agent_id`; new rows get `kids`.
      `SELECT * FROM usage_by_agent;` and `usage_by_device` match your manual count.
      Scripted MAC reassigned between real sessions; old attribution persisted. Audit compared the moved
      client's known row count/cost and kids-agent totals to both SQL views.
- [ ] Total cost for a known set of questions matches the OpenRouter dashboard to within rounding.
- [x] Main database integrity check returns `ok`; OpenRouter key fields in SQLite are empty; earlier inspected server/live-test logs contain no occurrence of the actual key.
      This is scoped to the inspected logs, not a blanket assertion about all files; see the progress report.

### 2.8 STT comparison (the decision you said you would make later)

Do the same 10 sentences with each and record:

| | OpenRouter STT | FunASR (local) |
|---|---|---|
| Switch | default | `UPDATE model_config SET enabled=1 WHERE id='ASR_FunASR'; UPDATE model_config SET enabled=0 WHERE id='ASR_OpenRouter'; UPDATE agent SET asr_id='ASR_FunASR' WHERE is_default=1;` + download `models/SenseVoiceSmall/model.pt` + restart |
| Accuracy (x/10 correct) | 10/10, ignoring punctuation/case | Blocked: missing `model.pt` |
| End of speech -> first physical sound (s) | Not measured at a speaker | Not measured |
| `listen.stop` -> first outgoing audio packet, median (s) | 3.2495 (scripted WebSocket proxy) | Not measured |
| Server RAM idle / observed peak during turns | 121.47 / 146.02 MiB RSS | Not measured |
| Cost for the 10 sentences | USD 0.00070950 STT; USD 0.00126772 including chat/title | n/a |

Single English synthetic-audio run, ten real WebSocket turns, 40-token chat output limit. Every reply
contained audio. Input text, transcripts, methods and evidence are in the device-free report. These are
not physical playback measurements or repeated benchmarks. FunASR is installed, but its required model
file is absent; no additional package/model installation was performed.

### 2.9 Optional features

- [x] **Replacement words:** `INSERT INTO replacement_word(source,target) VALUES ('AI','ay eye');` reconnect, make the assistant say "AI": the TTS input uses the target. The displayed/stored text is unchanged.
      Captured actual Edge provider input `ay eye`; client and history retained `AI`, with streamed audio returned. Listening quality is unverified.
- [x] **MCP endpoint:** set `UPDATE agent SET mcp_endpoint='<your endpoint url>' WHERE id='default';`, reconnect: the log shows the endpoint connecting and its tools being listed (see [mcp-endpoint-enable.md](./mcp-endpoint-enable.md)).
      Local WebSocket fixture completed initialize/tools-list, exposed `headless_echo`, and server reported ready. External endpoint credentials/services were not tested.
- [ ] **Device tools:** a tool the firmware reports (e.g. volume/screen) works by voice.
- [x] **Simulated device tools:** spoken "set speaker volume to twenty five percent" dispatches the advertised MCP volume tool with `volume=25`, receives a simulated acknowledgement and returns reply audio.
      Protocol behavior is verified; physical speaker volume remains unchecked above.
- [x] **Plugins stay off:** with `tools.server_plugins_enabled=false`, "what is the weather" must **not** call a weather plugin (no `get_weather` call in the log).
      Turning it on is an explicit step (see [weather-integration.md](./weather-integration.md)).
      Actual setting false and execution log showed no weather/music call; answer stated it could not check the weather. See corrected audit assertion.
- [x] **Firmware OTA:** a `.bin` in `data/bin` is offered to a device with the matching model/version; `server.http_base_url` is used in the link.
      HTTP test used a temporary non-flashable fixture, verified offer/version gating and exact downloaded bytes, then removed the fixture. No flashing attempted.

### 2.10 Robustness

- [x] Two scripted clients talking at the same time: no `database is locked` in the log, both get answers.
      Real concurrent sessions answered two-plus-two and three-plus-three with audio.
- [x] Kill the server in the middle of a conversation, start it again: DB opens normally, previous rows intact.
      Abrupt process termination, restart, integrity check and reconnect verified in a copied database; this was not a graceful Ctrl+C test.
- [x] Leave it running for an hour idle then talk: still works (idle STT client, WebSocket ping).
      Same client/server and ASR instance, 3,600.4 seconds idle with successful pings; final speech produced
      "Four — two plus two is four" and 51 audio packets, first outgoing audio after 4.39 seconds.
      Copied database and test-only no-voice timeout 4,000 seconds prevented the normal planned disconnect.
      Evidence: `tmp/headless-idle-1792313329/idle-results.json`. Temporary server stopped afterward.
- [ ] Disconnect the network cable of the PC for 30 s then restore: the device reconnects.
- [x] Isolated client transport outage for 30 seconds, followed by reconnect and a successful audio answer.
      PC network adapter/cable was not changed; the physical network-interruption case remains unchecked.

### 2.11 Test without a device

`main/digital-human` is a browser client for the same WebSocket protocol: `cd main/digital-human; python start.py`, open the page,
point it at `ws://<LAN IP>:8000/xiaozhi/v1/`. It is a way to run 2.1-2.7 before the firmware is ready (see its README).

- [x] Browser client renders, connects through OTA, shows conversation text, and receives reply audio with a fake microphone.
      Real headless Edge, isolated profile, local static hosting and copied-database server; 234 received audio frames,
      successful Scribe rows, no JavaScript exceptions. Screenshot: `tmp/headless-browser-1792313923/browser.png`.
- [ ] Desktop microphone/speaker and the optional local wake-word runtime work interactively. Fake media devices were used; `start.py` wake-word service was not exercised.

---

## Part 3: Measurement checklist (phase 6)

Goal: record, in numbers, how much smaller the server is. Fill the tables, then copy them into section 8 of
[minimal-server-design.md](./minimal-server-design.md) (the "done when" of phase 6).

### 3.1 Rules for a fair comparison

- Same machine, same Docker Desktop resource limits, nothing else heavy running. Note the machine: CPU ______ / RAM ______ / OS ______ / Docker version ______.
- Same script of conversation for both runs (use the 10 sentences from 2.8) and the same device or the same digital-human client.
- Measure **idle** (no connection), **one conversation** (one connected device, talking), and **peak** (during a reply).
- Take each number from at least 3 samples and write the median. Docker Desktop on Windows adds its own VM memory (`vmmem`): record that too (Task Manager), because it is what you actually pay.
- Allow 2-3 minutes after start before measuring "idle" (JVM/MySQL warm-up and model load settle).

### 3.2 "Before": the full stack (original project)

The branch `feature/openrouter-llm-provider` still has the full stack (Java API, MySQL, Redis, web). Use a separate worktree so this branch is untouched:

```powershell
git worktree add ..\xiaozhi-full feature/openrouter-llm-provider
cd ..\xiaozhi-full\main\xiaozhi-server
# follow that branch's docs/Deployment_all.md  (docker-compose_all.yml)
```

Record which ASR that run used (the old default local FunASR is the heavy one; if you also ran it with an API ASR, record both rows).

### 3.3 "After": the minimal server

```powershell
cd main\xiaozhi-server
docker compose up -d --build
```

Run once with `ASR_OpenRouter` (default) and, if you want the second row, once with `ASR_FunASR` (2.8 switch).

### 3.4 What to capture

Per container, sampled while the scenario runs:

```powershell
# one snapshot
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.PIDs}}"

# a sample every 5 s into a CSV file (Ctrl+C to stop)
while ($true) { docker stats --no-stream --format "{{.Name}},{{.CPUPerc}},{{.MemUsage}}" | ForEach-Object { "$(Get-Date -Format s),$_" | Add-Content stats.csv }; Start-Sleep 5 }
```

Bash equivalent: `while true; do docker stats --no-stream --format "$(date +%T),{{.Name}},{{.CPUPerc}},{{.MemUsage}}" >> stats.csv; sleep 5; done`.

Also record:

- [ ] Image size: `docker images` (the minimal image vs the full stack's images, summed).
- [ ] Containers/processes: `docker ps` count (full stack: ~5 services; minimal: 1).
- [ ] Idle disk: size of `data/` and of MySQL's volume; after the 10-sentence script, size of `data/xiaozhi.db` (shows the cost of storing audio: bytes per minute of conversation = (size after - size before) / minutes).
- [ ] Startup time: `docker compose up` to the OTA page answering ______ s (full stack: to the web console login page).
- [ ] Windows: `vmmem` / WSL2 memory in Task Manager.
- [ ] Python process on its own (source run): Task Manager "Details" -> `python.exe` memory, or `(Get-Process python).WorkingSet64 / 1MB`.

### 3.5 Results tables (fill in)

Memory (MiB) / CPU (%):

| Scenario | Full stack, total | Full stack, biggest container | Minimal, ASR=OpenRouter | Minimal, ASR=FunASR |
|---|---|---|---|---|
| Idle: memory | | | | |
| Idle: CPU | | | | |
| One conversation: memory (median) | | | | |
| One conversation: CPU (median / peak) | | | | |
| Docker VM `vmmem` | | | | |

Other:

| Metric | Full stack | Minimal |
|---|---|---|
| Containers | | 1 |
| Image size total | | |
| Time to ready (s) | | |
| End of speech -> first sound (s) | | |
| DB growth per minute of conversation | n/a | |

### 3.6 Reading the result

- Memory target: the original recommendation was 4 cores / 8 GB. State plainly whether the minimal server fits comfortably in, say, 1 GB / 1 core with ASR=OpenRouter. If the image still ships torch/funasr, say so: it is the first thing to trim if size matters
  (it is not used by OpenRouter STT, and removing it is a possible phase 7).
- If the CPU peak is during **Opus encode/decode** or **VAD**, that is the floor for any single-process version; if it is during something else, that is a finding.
- Add one line to the design doc per row you changed your mind about.

### 3.7 Done when

- [ ] Both columns filled for idle and one conversation.
- [ ] Tables pasted into `docs/minimal-server-design.md` section 8 (phase 6), with machine details and date.
- [ ] Any bug found during part 2 is listed with its log excerpt.
