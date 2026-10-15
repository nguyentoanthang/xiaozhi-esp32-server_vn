# FAQ ❓

### 1. Why does Xiaozhi recognize a lot of Korean, Japanese, and English from what I say? 🇰🇷

Suggestion: check whether `models/SenseVoiceSmall` already contains the `model.pt`
file. If not, you need to download it; see [Download the speech recognition model file](Deployment.md#model-files)

### 2. Why does the error "TTS task failed: file does not exist" appear? 📁

Suggestion: check whether the `libopus` and `ffmpeg` libraries were installed correctly with `conda`.

If they are not installed, install them

```
conda install conda-forge::libopus
conda install conda-forge::ffmpeg
```

### 3. TTS often fails or times out ⏰

Suggestion: if `EdgeTTS` fails often, first check whether you are using a proxy (VPN). If so, try turning the proxy off and try again;  
if you are using Volcano Engine's Doubao TTS and it fails often, we recommend the paid version, because the trial version supports only 2 concurrent connections.

### 4. I can connect to my self-hosted server over Wi-Fi, but not in 4G mode 🔐

Cause: in Brother Xia's firmware, 4G mode requires a secure connection.

Solution: there are currently two ways to solve this. Choose either one:

1. Modify the code. See this video: https://www.bilibili.com/video/BV18MfTYoE85

2. Use nginx to configure an SSL certificate. See this tutorial: https://icnt94i5ctj4.feishu.cn/docx/GnYOdMNJOoRCljx1ctecsj9cnRe

### 5. How do I improve Xiaozhi's conversation response speed? ⚡

This project's default configuration is a low-cost setup. Beginners are advised to start with the default free models to get it "running" first, and then optimize to make it "run fast".  
To improve the response speed, try replacing the components. Since version `0.5.2`, the project supports the streaming configuration. Compared with earlier versions, response time is reduced by about `2.5 seconds`, significantly improving the user experience.

| Module | Entry-level Fully Free Setup | Streaming Configuration |
|:---:|:---:|:---:|
| ASR (speech recognition) | FunASR (local) | 👍XunfeiStreamASR (iFlytek streaming) |
| LLM (large language model) | glm-4-flash (Zhipu) | 👍qwen-flash (Alibaba Bailian) |
| VLLM (vision large model) | glm-4v-flash (Zhipu) | 👍qwen3.5-flash (Alibaba Bailian) |
| TTS (speech synthesis) | EdgeTTS (Microsoft) | 👍HuoshanDoubleStreamTTS (Volcano Engine streaming) |
| Intent (intent recognition) | function_call (function calling) | function_call (function calling) |
| Memory (memory feature) | mem_local_short (local short-term memory) | mem_local_short (local short-term memory) |

If you care about the latency of each component, see the [Xiaozhi component performance test report](https://github.com/xinnan-tech/xiaozhi-performance-research); you can follow the test method in the report to test in your own environment.

### 6. I speak slowly, and Xiaozhi keeps cutting in when I pause 🗣️

Suggestion: find the following section in the configuration file and increase the value of `min_silence_duration_ms` (for example, to `1000`):

```yaml
VAD:
  SileroVAD:
    threshold: 0.5
    model_dir: models/snakers4_silero-vad
    min_silence_duration_ms: 700  # Increase this value if you tend to pause for longer
```

### 7. Deployment-related tutorials
1. [How to do a minimal deployment](./Deployment.md)<br/>
2. [How to do a full-module deployment](./Deployment_all.md)<br/>
3. [How to deploy the MQTT gateway to enable the MQTT+UDP protocol](./mqtt-gateway-integration.md)<br/>
4. [How to automatically pull the latest project code, then build and start it](./dev-ops-integration.md)<br/>
5. [How to integrate with Nginx](https://github.com/xinnan-tech/xiaozhi-esp32-server/issues/791)<br/>
6. [How to build your own Docker image after modifying the code](./docker-build.md)<br/>

### 8. Firmware build tutorials
1. [How to build the Xiaozhi firmware yourself](./firmware-build.md)<br/>
2. [How to change the OTA address based on the firmware built by Brother Xia](./firmware-setting.md)<br/>
3. [How to configure firmware OTA auto-upgrade for a single-module deployment](./ota-upgrade-guide.md)<br/>

### 9. Extension tutorials
1. [How to enable phone number registration for the Control Panel](./ali-sms-integration.md)<br/>
2. [How to integrate HomeAssistant for smart home control](./homeassistant-integration.md)<br/>
3. [How to enable the vision model to identify objects from photos](./mcp-vision-integration.md)<br/>
4. [How to deploy an MCP endpoint](./mcp-endpoint-enable.md)<br/>
5. [How to connect to an MCP endpoint](./mcp-endpoint-integration.md)<br/>
6. [How to get device information with MCP methods](./mcp-get-device-info.md)<br/>
7. [How to enable voiceprint recognition](./voiceprint-integration.md)<br/>
8. [News plugin source configuration guide](./newsnow_plugin_config.md)<br/>
9. [RAGFlow knowledge base integration guide](./ragflow-integration.md)<br/>
10. [How to deploy a context provider](./context-provider-integration.md)<br/>
11. [How to integrate PowerMem intelligent memory](./powermem-integration.md)<br/>
12. [How to configure the weather plugin to query the weather](./weather-integration.md)<br/>
13. [How to enable the device call plugin](./device-call-guide.md)<br/>
14. [How to enable web search](./web-search-integration.md)<br/>

### 10. Digital human tutorials
1. [How to start the digital-human](./digital-human-wakeword.md)<br/>
2. [How to deploy the digital-human on an N100 mini PC](./all-in-one-digital-human-setup.md)<br/>

### 11. Voice cloning and local voice deployment tutorials
1. [How to clone a voice in the Control Panel](./huoshan-streamTTS-voice-cloning.md)<br/>
2. [How to deploy and integrate index-tts local speech](./index-stream-integration.md)<br/>
3. [How to deploy and integrate fish-speech local speech](./fish-speech-integration.md)<br/>
4. [How to deploy and integrate PaddleSpeech local speech](./paddlespeech-deploy.md)<br/>

### 12. Performance testing tutorials
1. [Component speed testing guide](./performance_tester.md)<br/>
2. [Regularly published test results](https://github.com/xinnan-tech/xiaozhi-performance-research)<br/>

### 13. More questions? Contact us for feedback 💬

You can submit your questions in [issues](https://github.com/xinnan-tech/xiaozhi-esp32-server/issues).