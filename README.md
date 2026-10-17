# xiaozhi-esp32-server (minimal personal server)

A single-process Python backend for [xiaozhi-esp32](https://github.com/78/xiaozhi-esp32) devices. Everything it needs
(settings, models, agents, devices, chat history with audio, memory, LLM/STT usage and cost) lives in **one SQLite file**,
`main/xiaozhi-server/data/xiaozhi.db`. There is no Java API, web console, MySQL, Redis or nginx.

This is the `minimal_server` branch of a fork of [xinnan-tech/xiaozhi-esp32-server](https://github.com/xinnan-tech/xiaozhi-esp32-server).
The original full-stack project is described in [docs/architecture.md](docs/architecture.md); the design of this
branch is in [docs/minimal-server-design.md](docs/minimal-server-design.md).

## What it does

- WebSocket server (port 8000) for the devices, and a small HTTP server (port 8003) with the built-in OTA endpoint
  `/xiaozhi/ota/` that tells a device which WebSocket URL to use (and serves `.bin` firmware from `data/bin` if you put any there).
- Voice pipeline: VAD (Silero) -> ASR -> LLM -> TTS. Seeded defaults: OpenRouter STT + OpenRouter LLM + EdgeTTS.
  Other ASR/TTS/LLM providers stay in the code and can be selected by editing `model_config`.
- Tools: device-reported tools (IoT, device MCP) and an MCP endpoint. The server plugins (weather, news, music, ...) are in the
  code but switched off by default (`tools.server_plugins_enabled`).
- Memory per device (`mem_local_short`, or `nomem` to turn it off), chat history with Opus audio, replacement words for the TTS,
  guardrails that mask names, phones, emails and card numbers in user text, and an `ai_usage` table with tokens and cost per call.

Not included: MQTT/UDP gateway, vision, voiceprint, RAGFlow, mem0ai/powermem memory, firmware management, any web or mobile UI.

## Quick start

Requirements: Python 3.10+, `ffmpeg` and libopus on the machine.

```bash
cd main/xiaozhi-server
pip install -r requirements.txt
python app.py
```

On the first start the database is created and **seeded automatically** (a default agent, the model rows, the settings,
`data/xiaozhi.db`); `data/.config.yaml` is not needed. Stop the server, then put your OpenRouter key into the database:

```bash
sqlite3 data/xiaozhi.db "UPDATE model_config
  SET config_json = json_set(config_json, '$.api_key', 'sk-or-...')
  WHERE id IN ('LLM_OpenRouter', 'ASR_OpenRouter');"
python app.py
```

(Any SQLite browser works too. The shared VAD/ASR/LLM instances are created at startup, so restart after changing them;
agent and device edits apply to the next connection.)

The startup log prints the OTA URL (`http://<ip>:8003/xiaozhi/ota/`) and the WebSocket URL (`ws://<ip>:8000/xiaozhi/v1/`).
Point the device at the OTA URL. If the printed WebSocket address is wrong (Docker, domain name), set it:

```bash
sqlite3 data/xiaozhi.db "UPDATE setting SET value = '\"ws://192.168.1.10:8000/xiaozhi/v1/\"' WHERE key = 'server.websocket';"
```

Setting values are JSON, so strings carry their own quotes.

### Docker

One service, one volume (`./data`):

```bash
cd main/xiaozhi-server
docker compose up -d --build
```

The first start seeds `./data/xiaozhi.db` (an empty `./data` is fine). Set the OpenRouter key with the `sqlite3` command above
(against `./data/xiaozhi.db` on the host), then `docker compose restart`. The image is built from
[Dockerfile-server](Dockerfile-server) (Python slim, libopus, ffmpeg). Mount `models/SenseVoiceSmall/model.pt` only if you
switch to the local FunASR model (see the comment in `docker-compose.yml`).

## Where things live

| What | Where |
|---|---|
| Database | `main/xiaozhi-server/data/xiaozhi.db` (override with env `XIAOZHI_DB` or `db.path` in `data/.config.yaml`) |
| Defaults used to seed it | `main/xiaozhi-server/config.yaml` (only read when seeding and for the bootstrap values) |
| Optional bootstrap overrides | `main/xiaozhi-server/data/.config.yaml` (`db.path`, `log`, `server.ip/port/http_port/auth_key`); may be absent or empty |
| Firmware (optional) | `main/xiaozhi-server/data/bin/<model>_<version>.bin` |
| Logs | `main/xiaozhi-server/tmp/server.log` |

Main tables: `setting`, `model_config`, `agent`, `device`, `replacement_word`, `guardrail_name`, `memory`, `chat_session`,
`chat_message`, `chat_audio`, `ai_usage`, and the views `usage_by_device` / `usage_by_agent`.
The full schema is in [docs/minimal-server-design.md](docs/minimal-server-design.md) (section 5) and `core/db/schema.sql`.

### Add an agent or a device

An unknown device is registered automatically on the default agent (`device.auto_register`). To make another agent and
assign a device to it, insert rows (the model ids come from `SELECT id, model_type FROM model_config;`):

```sql
INSERT INTO agent(id, name, system_prompt, vad_id, asr_id, llm_id, tts_id, mem_id, intent_id, history_mode)
VALUES ('kids', 'Kids helper', 'You are a friendly helper for children.',
        'VAD_SileroVAD', 'ASR_OpenRouter', 'LLM_OpenRouter', 'TTS_EdgeTTS', 'Memory_nomem', 'Intent_function_call', 2);

UPDATE device SET agent_id = 'kids' WHERE mac = 'aa:bb:cc:dd:ee:ff';   -- MAC in lower case
```

Column meanings, replacement words, guardrail names and the usage views are described in the design document.

## Tests

```bash
cd main/xiaozhi-server
python -m pytest tests -q --continue-on-collection-errors
```

Everything runs offline. Tests that need optional packages that are not installed (`pydub`, `openrouter`) are reported as
failures or errors on a machine without them. Live OpenRouter checks run only with `RUN_LIVE_API_TESTS=1` and a real key.

## Documentation

- [docs/minimal-server-design.md](docs/minimal-server-design.md): decisions, schema, phases and implementation notes
- [main/README_en.md](main/README_en.md): technical overview of the server code
- [docs/mcp-endpoint-integration.md](docs/mcp-endpoint-integration.md), [docs/mcp-endpoint-enable.md](docs/mcp-endpoint-enable.md): MCP endpoint
- [docs/ota-upgrade-guide.md](docs/ota-upgrade-guide.md), [docs/firmware-setting.md](docs/firmware-setting.md), [docs/firmware-build.md](docs/firmware-build.md): OTA and device firmware
- [docs/FAQ.md](docs/FAQ.md), [docs/homeassistant-integration.md](docs/homeassistant-integration.md), [docs/web-search-integration.md](docs/web-search-integration.md),
  [docs/weather-integration.md](docs/weather-integration.md), [docs/newsnow_plugin_config.md](docs/newsnow_plugin_config.md),
  [docs/context-provider-integration.md](docs/context-provider-integration.md): plugins and extras (plugins must be enabled first)
- [docs/architecture.md](docs/architecture.md): the ORIGINAL full-stack architecture (not this branch)

## Warning

1. This is open-source software with no commercial relationship to any third-party API provider it can connect to (speech recognition,
   LLM, speech synthesis, ...). Check the terms and privacy policy of every provider you use. Keys are stored in plain text in the local
   SQLite file; keep `data/` private and out of git.
2. The server has not passed a network security assessment. Keep it on a trusted LAN; do not expose ports 8000/8003 to the internet
   without authentication in front.

## Acknowledgments

Based on [xinnan-tech/xiaozhi-esp32-server](https://github.com/xinnan-tech/xiaozhi-esp32-server) (MIT license, see [LICENSE](LICENSE)) and
the [xiaozhi-esp32](https://github.com/78/xiaozhi-esp32) firmware. Thanks to the upstream contributors and to
[Tenclass](https://www.tenclass.com/) for the device communication protocol.
