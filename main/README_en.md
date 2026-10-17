# Technical Overview: `xiaozhi-esp32-server` (minimal server)

This branch runs `main/xiaozhi-server` as a **single Python process** with a local SQLite database. For the quick start, Docker, the
database location and the test command see the [root README](../README.md). Decisions, schema and per-phase implementation notes are in
[docs/minimal-server-design.md](../docs/minimal-server-design.md). The architecture of the original full-stack project (Java API, web console,
mobile app, MySQL, Redis, MQTT gateway, ...) is in [docs/architecture.md](../docs/architecture.md); those parts are **not** in this branch.

## Layout

| Path | Purpose |
|---|---|
| `main/xiaozhi-server/app.py` | Entry point: loads the config from SQLite, starts the WebSocket server (:8000) and the HTTP server (:8003) |
| `main/xiaozhi-server/config.yaml` | Defaults used to seed an empty database, plus bootstrap values (server ports, log block) |
| `main/xiaozhi-server/data/` | Runtime data (git-ignored): `xiaozhi.db`, optional `.config.yaml`, optional `bin/` firmware |
| `main/xiaozhi-server/core/db/` | SQLite layer: schema (`schema.sql`), seed, config assembly per device, chat history, usage recorder |
| `main/xiaozhi-server/core/connection.py` | One `ConnectionHandler` per device WebSocket connection |
| `main/xiaozhi-server/core/api/ota_handler.py` | Built-in OTA endpoint (`/xiaozhi/ota/`): WebSocket URL, optional token, firmware from `data/bin` |
| `main/xiaozhi-server/core/providers/` | VAD, ASR, LLM, TTS, memory (`mem_local_short`, `nomem`), intent (`function_call`), tools (IoT, device MCP, MCP endpoint, server plugins) |
| `main/xiaozhi-server/plugins_func/` | Server plugins (weather, news, music, Home Assistant, ...); off unless `tools.server_plugins_enabled` is true |
| `main/xiaozhi-server/tests/` | Offline test suite (`python -m pytest tests`) |
| `main/digital-human/` | Browser test client for the WebSocket service |
| `Dockerfile-server`, `main/xiaozhi-server/docker-compose.yml` | One image, one service, one volume (`./data`) |

## How a conversation flows

1. The device calls the OTA endpoint and receives the WebSocket URL (and a token if `server.auth.enabled`).
2. It connects to `ws://<host>:8000/xiaozhi/v1/` with its `device-id` (MAC). An unknown MAC is added to the default agent (`device.auto_register`).
3. `core/db/config_assembly.py` builds the per-device config from `device` -> `agent` -> `model_config` rows (VAD, ASR, LLM, TTS, memory, intent), the prompt, replacement words and guardrail names.
4. Opus audio is decoded, VAD finds the end of the utterance, ASR returns text, guardrails mask personal data, the LLM answers (streaming, with tools), the TTS speaks sentence by sentence and the Opus frames go back to the device.
5. Chat rows (with Opus audio), `ai_usage` rows and, at disconnect, the title/summary and the per-device memory are written to SQLite through one writer thread.

## Providers kept in the code

ASR: OpenRouter STT (default), FunASR (local), FunASRServer, Sherpa-ONNX, Vosk, Doubao, Aliyun, Baidu, Tencent, Qwen3-ASR, OpenAI and others.
LLM: OpenRouter (default), OpenAI-compatible, Gemini, Ollama, Xinference, Dify, FastGPT, Coze, Home Assistant, Aliyun Bailian.
TTS: EdgeTTS (default), Doubao, Aliyun, Tencent, SiliconFlow, OpenAI, CozeCn, FishSpeech, GPT-SoVITS, PaddleSpeech, custom HTTP.
Only the seeded providers are selectable without extra work; add a row to `model_config` and point an agent at it to use another one.

## Removed from the original project

Java `manager-api`, Vue `manager-web`, `manager-mobile`, MySQL, Redis, nginx, RAGFlow, the MQTT/UDP gateway code, vision (VLLM and `/mcp/vision/explain`),
voiceprint, the `mem0ai` / `powermem` / `mem_report_only` memory providers, the bind-code/activation flow, and six Chinese-only streaming TTS providers.
`intent_llm` and `nointent` are still in the code but not seeded (the supported intent mode is `function_call`).
