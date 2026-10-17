# Setup, test and measurement guide (minimal server)

Three parts, meant to be followed in order:

1. [Setup, configure and run](#part-1-setup-configure-and-run)
2. [Test checklist](#part-2-test-checklist) (what to tick before you trust it)
3. [Measurement checklist](#part-3-measurement-checklist-phase-6) (phase 6: resource use before/after)

Nothing in this guide has been run against a real device, a live OpenRouter key or Docker yet: that is exactly what
part 2 is for. Where a step says "expected", it is what the code is designed to do, not something already observed.

Conventions: commands are run from `main/xiaozhi-server` unless stated. SQL is shown for the `sqlite3` CLI; on Windows
without it, use [DB Browser for SQLite](https://sqlitebrowser.org/) or the Python form shown in 1.4.

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
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

`requirements.txt` still contains the heavy local-model packages (torch/funasr for the optional FunASR). If you only use
OpenRouter STT you can leave them installed (they are only imported when FunASR is selected), but they dominate image/venv size.

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

The seeded rows have `api_key: ""`. With an empty key every transcription logs an error and returns empty text.

Stop the server first (the shared VAD/ASR/LLM objects are built at startup), then:

```bash
sqlite3 data/xiaozhi.db "UPDATE model_config
  SET config_json = json_set(config_json, '$.api_key', 'sk-or-v1-...')
  WHERE id IN ('LLM_OpenRouter', 'ASR_OpenRouter');"
```

Without the `sqlite3` CLI (Windows), same thing in Python:

```powershell
python -I -c "import sqlite3; c=sqlite3.connect('data/xiaozhi.db'); c.execute(\"UPDATE model_config SET config_json=json_set(config_json,'$.api_key','sk-or-v1-...') WHERE id IN ('LLM_OpenRouter','ASR_OpenRouter')\"); c.commit()"
```

Check (do not paste the output anywhere public, it shows the key):

```sql
SELECT id, enabled, json_extract(config_json,'$.model_name') AS model,
       length(json_extract(config_json,'$.api_key')) AS key_len FROM model_config;
```

### 1.5 The three things you will want to change on day one

**a) The speech-to-text model id.** The seed uses `openai/whisper-large-v3` as a *placeholder*. I could not confirm that is a
valid OpenRouter STT model id. Look at OpenRouter's model list for an audio-input/STT model and set it:

```sql
UPDATE model_config SET config_json = json_set(config_json,'$.model_name','<id from OpenRouter>') WHERE id='ASR_OpenRouter';
-- optional: a language hint, e.g. 'vi' (empty = auto-detect)
UPDATE model_config SET config_json = json_set(config_json,'$.language','vi') WHERE id='ASR_OpenRouter';
```

**b) The LLM model** (seed: `openai/gpt-4o-mini`):

```sql
UPDATE model_config SET config_json = json_set(config_json,'$.model_name','<model id>') WHERE id='LLM_OpenRouter';
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

### 2.0 Offline (no key, no device)

- [ ] `python -m pytest tests -q --continue-on-collection-errors` -> `235 passed, 8 failed, 16 skipped, 1 error` on a machine **without**
      `pydub`/`openrouter`. With `pip install -r requirements.txt` done, the 8 failures and 1 error should disappear (if they do not, look at them).
- [ ] Delete `data/xiaozhi.db*`, run `python -m core.db.seed`, run it again: second run prints `Rows added: setting=0, model_config=0, agent=0`.
- [ ] `sqlite3 data/xiaozhi.db "PRAGMA user_version; SELECT count(*) FROM model_config;"` -> `1` and `8`.

### 2.1 Startup

- [ ] Fresh `data/` (no db): `python app.py` starts without error and logs the seeding lines.
- [ ] Start again: **no** seeding lines (the DB already has a default agent).
- [ ] Open `http://<LAN IP>:8003/xiaozhi/ota/` in a browser: message says it is running and shows the WebSocket URL.
- [ ] Delete a non-default seed row (e.g. a `setting`), restart: it is **not** re-created (auto-seed only when no default agent).
- [ ] Docker only: `docker compose up -d --build` builds; the container stays up (`docker ps`); same OTA page works via the host IP.

### 2.2 First device connection

- [ ] Power the device, it fetches OTA and connects. Evidence: `SELECT mac, agent_id, last_connected_at FROM device;` shows the device, lower-case MAC, agent `default`.
- [ ] Set `device.auto_register` to `false`, delete the device row, reconnect: the device is refused and no row is created. Set it back to `true`.
- [ ] Log shows no `NoDefaultAgent`, no traceback on connect.

### 2.3 Conversation (needs the key from 1.4)

- [ ] Say a simple sentence ("what is two plus two"): you hear a spoken answer; the device screen shows what you said.
- [ ] Log shows an ASR line with your text (this is the **OpenRouter STT** path), an LLM call, a TTS line. Note the time from end of speech to first sound: ______ s (compare with FunASR in 2.8).
- [ ] Wrong key (temporarily blank it): the conversation does not crash; the device gets the system error reply; the log shows the OpenRouter error; the server keeps running.
- [ ] `agent.tts_voice` changed to a vi-VN voice and device reconnected: the voice changes. If not, record it as a bug.
- [ ] Say "goodbye" (also try "exit", "quit"): the conversation ends and the end prompt is spoken if `end_prompt.enable` is on.
- [ ] Stay silent for `close_connection_no_voice_time` seconds: the server ends the conversation.
- [ ] Interrupt the device mid-reply: speech stops, a new question is answered.

### 2.4 History, audio, titles

- [ ] After a conversation ends: `SELECT * FROM chat_session ORDER BY started_at DESC LIMIT 1;` has `ended_at`, a `title` and a `summary`.
- [ ] `chat_message` has user (type 1) and agent (type 2) rows in the right order.
- [ ] `SELECT m.chat_type, a.format, a.sample_rate, length(a.data) FROM chat_message m JOIN chat_audio a ON a.id=m.audio_id WHERE m.session_id='<id>';` has rows for both sides, `format = opus-frames`, non-zero length.
- [ ] `UPDATE agent SET history_mode = 1 ...`, reconnect, talk: new messages have **no** `audio_id` and no new `chat_audio` rows. `history_mode = 0`: nothing is stored. Set back to `2`.
- [ ] Known gap: there is no tool yet to play the stored audio back. Only existence/size is checked. (The container is length-prefixed Opus packets, see `core/db/chat_history.py`.)

### 2.5 Memory (per device)

- [ ] Tell the assistant a fact ("my dog is called Rex"), end the conversation. `SELECT * FROM memory;` has a row for **that device's MAC** with a JSON summary.
- [ ] Reconnect, ask "what is my dog called": the answer uses the memory.
- [ ] `UPDATE agent SET mem_id = 'Memory_nomem' ...`, reconnect, say something new, end: the `memory` row for that device does not change. Set back to `Memory_mem_local_short`.
- [ ] Two devices on the same agent keep **different** memory rows (if you have two).

### 2.6 Guardrails

Setup: `INSERT INTO guardrail_name(name) VALUES ('Nguyen Van A');`, reconnect.

- [ ] Say "my phone number is 0912 345 678": `SELECT content FROM chat_message ... ORDER BY id DESC` shows `[PHONE_1]`, not the number; the device screen still shows what you said.
- [ ] Say an email address: stored as `[EMAIL_1]`.
- [ ] Say a valid test card number (`4111 1111 1111 1111`): stored as `[CARD_1]`. Say a 16-digit number that fails the Luhn check (`1234 5678 9012 3456`): **not** masked.
- [ ] Say "Nguyen Van A": stored as `[NAME_1]`. A name that is not in the table is not masked.
- [ ] Say the same phone number twice in one conversation: both become `[PHONE_1]`; a different number becomes `[PHONE_2]`.
- [ ] `grep` the log for the raw number/email/card: **no hits** (`Select-String -Path tmp\server.log -Pattern "0912"` on Windows).
- [ ] The LLM does not repeat the number (it never received it). Check the `memory` summary too.
- [ ] `UPDATE setting SET value='false' WHERE key='guardrails.enabled';` + restart: text is stored unmasked (switch really works). Set back to `true`.
- [ ] Optional: `guardrails.restore_in_reply` = `true` + restart: when the LLM repeats a placeholder, the spoken reply contains the real value.
- [ ] Known limit: the **LLM's reply and the TTS text are not checked**; only user text is masked. All audio is stored (including unmasked speech).

### 2.7 Usage and cost

- [ ] After a conversation: `SELECT kind, purpose, requested_model, served_model, prompt_tokens, completion_tokens, cost, device_mac, agent_id FROM ai_usage ORDER BY id DESC LIMIT 20;`
      shows `chat`, `title` and `memory` LLM rows and one `stt` row per utterance, all with the right `device_mac` and `agent_id`.
- [ ] `cost` is filled for OpenRouter rows (if NULL everywhere, OpenRouter did not return it for that call; note it).
- [ ] `stt` rows have `audio_seconds` set. A deliberately failed STT call (wrong key) writes **no** row.
- [ ] Move the device to another agent (`UPDATE device SET agent_id='kids' ...`), reconnect, talk. Old rows keep the old `agent_id`; new rows get `kids`.
      `SELECT * FROM usage_by_agent;` and `usage_by_device` match your manual count.
- [ ] Total cost for a known set of questions matches the OpenRouter dashboard to within rounding.

### 2.8 STT comparison (the decision you said you would make later)

Do the same 10 sentences with each and record:

| | OpenRouter STT | FunASR (local) |
|---|---|---|
| Switch | default | `UPDATE model_config SET enabled=1 WHERE id='ASR_FunASR'; UPDATE model_config SET enabled=0 WHERE id='ASR_OpenRouter'; UPDATE agent SET asr_id='ASR_FunASR' WHERE is_default=1;` + download `models/SenseVoiceSmall/model.pt` + restart |
| Accuracy (x/10 correct) | | |
| End of speech -> first sound (s) | | |
| Server RAM idle / during a turn | | |
| Cost for the 10 sentences | | n/a |

### 2.9 Optional features

- [ ] **Replacement words:** `INSERT INTO replacement_word(source,target) VALUES ('AI','ay eye');` reconnect, make the assistant say "AI": it pronounces the target. The displayed/stored text is unchanged.
- [ ] **MCP endpoint:** set `UPDATE agent SET mcp_endpoint='<your endpoint url>' WHERE id='default';`, reconnect: the log shows the endpoint connecting and its tools being listed (see [mcp-endpoint-enable.md](./mcp-endpoint-enable.md)).
- [ ] **Device tools:** a tool the firmware reports (e.g. volume/screen) works by voice.
- [ ] **Plugins stay off:** with `tools.server_plugins_enabled=false`, "what is the weather" must **not** call a weather plugin (no `get_weather` call in the log).
      Turning it on is an explicit step (see [weather-integration.md](./weather-integration.md)).
- [ ] **Firmware OTA:** a `.bin` in `data/bin` is offered to a device with the matching model/version; `server.http_base_url` is used in the link.

### 2.10 Robustness

- [ ] Two devices (or the digital-human page plus a device) talking at the same time: no `database is locked` in the log, both get answers.
- [ ] Kill the server (Ctrl+C) in the middle of a conversation, start it again: DB opens normally, previous rows intact.
- [ ] Leave it running for an hour idle then talk: still works (idle STT client, WebSocket ping).
- [ ] Disconnect the network cable of the PC for 30 s then restore: the device reconnects.

### 2.11 Test without a device

`main/digital-human` is a browser client for the same WebSocket protocol: `cd main/digital-human; python start.py`, open the page,
point it at `ws://<LAN IP>:8000/xiaozhi/v1/`. It is a way to run 2.1-2.7 before the firmware is ready (see its README). Not verified here.

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
