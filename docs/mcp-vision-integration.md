# Vision Model Usage Guide
This tutorial has two parts:
- Part 1: Enable the vision model when running xiaozhi-server as a single module
- Part 2: How to enable the vision model in a full-module deployment

Before enabling the vision model, you need to prepare three things:
- You need a device with a camera, and the device must already have camera calling implemented in Brother Xia's repository, for example the `LCSC Practical ESP32-S3 development board`
- Your device firmware version must be upgraded to 1.6.6 or above
- You have already gotten the basic conversation module working

## Enable the Vision Model When Running xiaozhi-server as a Single Module

### Step 1: Confirm the Network
The vision model starts port 8003 by default.

If you run with docker, check whether your `docker-compose.yml` exposes port `8003`. If not, update to the latest `docker-compose.yml` file

If you run from source, confirm that the firewall allows port `8003`

### Step 2: Choose Your Vision Model
Open your `data/.config.yaml` file and set `selected_module.VLLM` to a vision model. We currently support vision models with an `openai`-type API. `ChatGLMVLLM` is one of the `openai`-compatible models.

```
selected_module:
  VAD: ..
  ASR: ..
  LLM: ..
  VLLM: ChatGLMVLLM
  TTS: ..
  Memory: ..
  Intent: ..
```

Suppose we use `ChatGLMVLLM` as the vision model. We first need to log in to the [Zhipu AI](https://bigmodel.cn/usercenter/proj-mgmt/apikeys) website and apply for a key. If you have applied for a key before, you can reuse it.

Add this configuration to your configuration file. If it already exists, just set your api_key.

```
VLLM:
  ChatGLMVLLM:
    api_key: your api_key
```

### Step 3: Start the xiaozhi-server Service
If you run from source, enter the command to start it
```
python app.py
```
If you run with docker, restart the container
```
docker restart xiaozhi-esp32-server
```

After starting, logs with the following content are printed.

```
2025-06-01 **** - OTA endpoint is        http://192.168.4.7:8003/xiaozhi/ota/
2025-06-01 **** - Vision analysis endpoint is  http://192.168.4.7:8003/mcp/vision/explain
2025-06-01 **** - Websocket address is ws://192.168.4.7:8000/xiaozhi/v1/
2025-06-01 **** - =======The address above is a websocket protocol address; do not open it in a browser=======
2025-06-01 **** - To test websocket, start the digital-human module and use the browser for interactive testing
2025-06-01 **** - =============================================================
```

After starting, use a browser to open the `vision analysis interface` link in the logs. See what it outputs. If you are on Linux without a browser, you can run this command:
```
curl -i <your vision analysis interface>
```

Normally it displays like this
```
MCP Vision interface is running normally, the vision explain interface address is:http://xxxx:8003/mcp/vision/explain
```

Note that if you deploy on a public network or with docker, you must change this setting in your `data/.config.yaml`
```
server:
  vision_explain: http://your-ip-or-domain:port/mcp/vision/explain
```

Why? Because the vision explain interface address is sent down to the device. If your address is a LAN address or a docker-internal address, the device cannot reach it.

Suppose your public address is `111.111.111.111`; then `vision_explain` should be configured like this

```
server:
  vision_explain: http://111.111.111.111:8003/mcp/vision/explain
```

If your MCP Vision interface runs normally and you have also tried opening the delivered `vision explain interface address` in a browser successfully, continue to the next step

### Step 4: Wake the Device

Say to the device, "Please turn on the camera and tell me what you see"

Watch the log output of xiaozhi-server to see whether there are any errors.


## How to Enable the Vision Model in a Full-Module Deployment

### Step 1: Confirm the Network
The vision model starts port 8003 by default.

If you run with docker, check whether your `docker-compose_all.yml` maps port `8003`. If not, update to the latest `docker-compose_all.yml` file

If you run from source, confirm that the firewall allows port `8003`

### Step 2: Check Your Configuration File

Open your `data/.config.yaml` file and check whether its structure matches `data/config_from_api.yaml`. If it does not, or an item is missing, fill it in.

### Step 3: Configure the Vision Model Key

We first need to log in to the [Zhipu AI](https://bigmodel.cn/usercenter/proj-mgmt/apikeys) website and apply for a key. If you have applied for a key before, you can reuse it.

Log in to the `Control Panel`, click `Model Configuration` in the top menu, click `Vision Large Language Model` in the left sidebar, find `VLLM_ChatGLMVLLM`, click the Edit button, enter your key in `API Key` in the dialog, and click Save.

After saving successfully, go to the agent you want to test, click `Configure Role`, and in the opened content check whether `Vision Large Language Model (VLLM)` has the vision model you just configured selected. Click Save.

### Step 3: Start the xiaozhi-server Module
If you run from source, enter the command to start it
```
python app.py
```
If you run with docker, restart the container
```
docker restart xiaozhi-esp32-server
```

After starting, logs with the following content are printed.

```
2025-06-01 **** - Vision analysis endpoint is  http://192.168.4.7:8003/mcp/vision/explain
2025-06-01 **** - Websocket address is ws://192.168.4.7:8000/xiaozhi/v1/
2025-06-01 **** - =======The address above is a websocket protocol address; do not open it in a browser=======
2025-06-01 **** - To test websocket, start the digital-human module and use the browser for interactive testing
2025-06-01 **** - =============================================================
```

After starting, use a browser to open the `vision analysis interface` link in the logs. See what it outputs. If you are on Linux without a browser, you can run this command:
```
curl -i <your vision analysis interface>
```

Normally it displays like this
```
MCP Vision interface is running normally, the vision explain interface address is:http://xxxx:8003/mcp/vision/explain
```

Note that if you deploy on a public network or with docker, you must change this setting in your `data/.config.yaml`
```
server:
  vision_explain: http://your-ip-or-domain:port/mcp/vision/explain
```

Why? Because the vision explain interface address is sent down to the device. If your address is a LAN address or a docker-internal address, the device cannot reach it.

Suppose your public address is `111.111.111.111`; then `vision_explain` should be configured like this

```
server:
  vision_explain: http://111.111.111.111:8003/mcp/vision/explain
```

If your MCP Vision interface runs normally and you have also tried opening the delivered `vision explain interface address` in a browser successfully, continue to the next step

### Step 4: Wake the Device

Say to the device, "Please turn on the camera and tell me what you see"

Watch the log output of xiaozhi-server to see whether there are any errors.
