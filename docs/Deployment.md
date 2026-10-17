# Deployment

The minimal server is one Python process with one SQLite file. Pick one of the two ways to run it. The short version of both is in the
[root README](../README.md); this page adds the details.

## Prerequisites

- An OpenRouter API key (the seeded LLM and speech-to-text both use OpenRouter).
- Docker, or Python 3.10+ with `ffmpeg` and `libopus` installed.

## Method 1: Docker (one service, one volume)

From the repository root:

```bash
cd main/xiaozhi-server
docker compose up -d --build
docker logs -f xiaozhi-esp32-server
```

- The only volume is `./data`, mounted at `/opt/xiaozhi-esp32-server/data`. It holds `xiaozhi.db` and, if you use them, `data/bin` (firmware) and `data/.config.yaml`.
- An empty `./data` is fine: the database is created and seeded on the first start.
- Set the OpenRouter key (the server may be running; the shared models are created at startup, so restart afterwards):

  ```bash
  sqlite3 data/xiaozhi.db "UPDATE model_config SET config_json = json_set(config_json, '$.api_key', 'sk-or-...') WHERE id IN ('LLM_OpenRouter', 'ASR_OpenRouter');"
  docker compose restart
  ```

- The addresses in the log are container addresses. Your OTA address is `http://<host LAN ip>:8003/xiaozhi/ota/` and the WebSocket address
  `ws://<host LAN ip>:8000/xiaozhi/v1/`. Make the OTA reply carry the right WebSocket address with:

  ```bash
  sqlite3 data/xiaozhi.db "UPDATE setting SET value = '\"ws://192.168.1.25:8000/xiaozhi/v1/\"' WHERE key = 'server.websocket';"
  ```

  (If you serve firmware from `data/bin`, also set `server.http_base_url`, see [ota-upgrade-guide.md](./ota-upgrade-guide.md).)
- Upgrade: `git pull`, then `docker compose up -d --build` again. The database in `./data` is kept.
- The image is built from [Dockerfile-server](../Dockerfile-server); `docker compose` builds it locally. It was not built or run in the
  environment where these docs were written, so report any problem you find.

## Method 2: Run from source

```bash
cd main/xiaozhi-server
python -m venv .venv && . .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

With conda you can get the native libraries with `conda install libopus ffmpeg`. On Debian/Ubuntu: `apt install libopus0 ffmpeg`.

The first start creates `data/xiaozhi.db` and seeds it; `data/.config.yaml` is not needed. Put the OpenRouter key in as shown above and restart.

## Configuration

Everything is in the database (see [minimal-server-design.md](./minimal-server-design.md)). Optional bootstrap values can be placed in
`data/.config.yaml` (it may be missing or empty):

```yaml
db:
  path: data/xiaozhi.db      # or set the env var XIAOZHI_DB
server:
  ip: 0.0.0.0
  port: 8000                 # WebSocket
  http_port: 8003            # OTA
log:
  log_level: DEBUG
```

## Model files

The default speech recognition is OpenRouter STT (no local model). The Silero VAD model ships with the repository (`models/snakers4_silero-vad`).
Only if you switch to the local FunASR model (`UPDATE model_config SET enabled = 1 WHERE id = 'ASR_FunASR'; UPDATE model_config SET enabled = 0 WHERE id = 'ASR_OpenRouter'; UPDATE agent SET asr_id = 'ASR_FunASR' WHERE is_default = 1;`)
you must download `SenseVoiceSmall` `model.pt` into `models/SenseVoiceSmall/`:

- ModelScope: [SenseVoiceSmall](https://modelscope.cn/models/iic/SenseVoiceSmall/resolve/master/model.pt)

With Docker, also uncomment the `model.pt` mount in `docker-compose.yml`.

## Confirm running status

If you see logs similar to the following, the server has started.

```
250427 13:04:20[0.3.11_SiFuChTTnofu][__main__]-INFO-OTA endpoint is        http://192.168.4.123:8003/xiaozhi/ota/
250427 13:04:20[0.3.11_SiFuChTTnofu][__main__]-INFO-Websocket address is ws://192.168.4.123:8000/xiaozhi/v1/
```

Open the OTA address in a browser: it should say "OTA interface is running normally" and show the WebSocket address that devices will receive.
To test the WebSocket connection without a device, start the `digital-human` module (`main/digital-human`, `python start.py`) and open `index.html`.

Then connect your device:

1. [Build your own esp32 firmware](firmware-build.md).
2. [Configure a custom server based on the firmware built by Brother Xia](firmware-setting.md).

## More

- [FAQ](./FAQ.md)
- [MCP endpoint](./mcp-endpoint-enable.md), [Home Assistant](./homeassistant-integration.md), [weather](./weather-integration.md), [news](./newsnow_plugin_config.md), [web search](./web-search-integration.md)
- [fish-speech](./fish-speech-integration.md), [PaddleSpeech](./paddlespeech-deploy.md) local TTS
- [Performance testing](./performance_tester.md)
