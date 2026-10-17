# FAQ ❓

### 1. Why does Xiaozhi recognize a lot of Korean, Japanese, and English from what I say? 🇰🇷

Suggestion: this happens with the local FunASR model (`ASR_FunASR`). Check whether `models/SenseVoiceSmall` contains the `model.pt`
file; if not, download it, see [Model files](Deployment.md#model-files). The seeded default (OpenRouter STT) does not use it; set the `language` key of the `ASR_OpenRouter` row to fix the recognition language.

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
| TTS (speech synthesis) | EdgeTTS (Microsoft) | 👍DoubaoTTS (Volcano Engine) |
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
1. [How to deploy (Docker or from source)](./Deployment.md)<br/>
2. [Minimal server design: database, agents, devices](./minimal-server-design.md)<br/>

### 8. Firmware build tutorials
1. [How to build the Xiaozhi firmware yourself](./firmware-build.md)<br/>
2. [How to change the OTA address based on the firmware built by Brother Xia](./firmware-setting.md)<br/>
3. [How to configure firmware OTA auto-upgrade](./ota-upgrade-guide.md)<br/>

### 9. Extension tutorials (server plugins are off by default, see the guides)
1. [How to integrate HomeAssistant for smart home control](./homeassistant-integration.md)<br/>
2. [How to deploy an MCP endpoint](./mcp-endpoint-enable.md)<br/>
3. [How to connect to an MCP endpoint](./mcp-endpoint-integration.md)<br/>
4. [How to get device information with MCP methods](./mcp-get-device-info.md)<br/>
5. [News plugin source configuration guide](./newsnow_plugin_config.md)<br/>
6. [How to deploy a context provider](./context-provider-integration.md)<br/>
7. [How to configure the weather plugin to query the weather](./weather-integration.md)<br/>
8. [How to enable web search](./web-search-integration.md)<br/>

### 10. Digital human tutorials
1. [How to start the digital-human](./digital-human-wakeword.md)<br/>
2. [How to deploy the digital-human on an N100 mini PC](./all-in-one-digital-human-setup.md)<br/>

### 11. Local voice deployment tutorials
1. [How to deploy and integrate fish-speech local speech](./fish-speech-integration.md)<br/>
2. [How to deploy and integrate PaddleSpeech local speech](./paddlespeech-deploy.md)<br/>

### 12. Performance testing tutorials
1. [Component speed testing guide](./performance_tester.md)<br/>
2. [Regularly published test results](https://github.com/xinnan-tech/xiaozhi-performance-research)<br/>

### 13. More questions? Contact us for feedback 💬

You can submit your questions in [issues](https://github.com/xinnan-tech/xiaozhi-esp32-server/issues).