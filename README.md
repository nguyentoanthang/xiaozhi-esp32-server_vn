[![Banners](docs/images/banner1.png)](https://github.com/xinnan-tech/xiaozhi-esp32-server)

<h1 align="center">Xiaozhi Backend Service: xiaozhi-esp32-server</h1>

<p align="center">
This project develops a software and hardware system for smart terminals based on human-machine symbiotic intelligence theory and technology.<br/>It provides backend services for the open-source smart hardware project
<a href="https://github.com/78/xiaozhi-esp32">xiaozhi-esp32</a><br/>
Implemented in Python, Java, and Vue according to the <a href="https://ccnphfhqs21z.feishu.cn/wiki/M0XiwldO9iJwHikpXD5cEx71nKh">Xiaozhi communication protocol</a><br/>
Supports the MQTT+UDP protocol, the WebSocket protocol, MCP endpoints, voiceprint recognition, and a knowledge base
</p>

<p align="center">
<a href="./docs/FAQ.md">FAQ</a>
· <a href="https://github.com/xinnan-tech/xiaozhi-esp32-server/issues">Report Issues</a>
· <a href="./README.md#deployment-documentation">Deployment Documentation</a>
· <a href="https://github.com/xinnan-tech/xiaozhi-esp32-server/releases">Changelog</a>
</p>

<p align="center">
  <a href="./docs/readme/README_en.md"><img alt="README in English" src="https://img.shields.io/badge/English-DFE0E5"></a>
  <a href="./docs/readme/README_vi.md"><img alt="Tiếng Việt" src="https://img.shields.io/badge/Tiếng Việt-DFE0E5"></a>
  <a href="./docs/readme/README_de.md"><img alt="Deutsch" src="https://img.shields.io/badge/Deutsch-DFE0E5"></a>
  <a href="./docs/readme/README_pt_BR.md"><img alt="Português (Brasil)" src="https://img.shields.io/badge/Português (Brasil)-DFE0E5"></a>
  <a href="https://github.com/xinnan-tech/xiaozhi-esp32-server/releases">
    <img alt="GitHub Contributors" src="https://img.shields.io/github/v/release/xinnan-tech/xiaozhi-esp32-server?logo=docker" />
  </a>
  <a href="https://github.com/xinnan-tech/xiaozhi-esp32-server/blob/main/LICENSE">
    <img alt="GitHub pull requests" src="https://img.shields.io/badge/license-MIT-white?labelColor=black" />
  </a>
  <a href="https://github.com/xinnan-tech/xiaozhi-esp32-server">
    <img alt="stars" src="https://img.shields.io/github/stars/xinnan-tech/xiaozhi-esp32-server?color=ffcb47&labelColor=black" />
  </a>
</p>

<p align="center">
Spearheaded by Professor Siyuan Liu's Team (South China University of Technology)
</br>
Led by Professor Siyuan Liu's team (South China University of Technology)
</br>
<img src="./docs/images/hnlg.jpg" alt="South China University of Technology" width="50%">
</p>

---

## Target Audience 👥

This project is meant to be used with ESP32 hardware devices. If you have purchased ESP32-related hardware, have successfully connected it to the backend service deployed by Brother Xia (the xiaozhi-esp32 author), and want to build your own
`xiaozhi-esp32` backend service, this project is a great fit for you.

Want to see it in action? Check out the videos 🎥

<table>
  <tr>
    <td>
      <a href="https://www.bilibili.com/video/BV1FMFyejExX" target="_blank">
        <picture>
          <img alt="Response speed demo" src="docs/images/demo9.png" /></picture>
      </a>
    </td>
    <td>
      <a href="https://www.bilibili.com/video/BV1vchQzaEse" target="_blank">
        <picture>
          <img alt="Speed optimization tips" src="docs/images/demo6.png" /></picture>
      </a>
    </td>
    <td>
      <a href="https://www.bilibili.com/video/BV1WEcxzFEAT" target="_blank">
        <picture>
          <img alt="Xiaozhi digital human with voice wake-up" src="docs/images/demo8.png" /></picture>
      </a>
    </td>
    <td>
      <a href="https://www.bilibili.com/video/BV1CKVz6UEuB" target="_blank">
        <picture>
          <img alt="Device-to-device calling" src="docs/images/demo0.png" /></picture>
      </a>
    </td>
    <td>
      <a href="https://www.bilibili.com/video/BV1C1tCzUEZh" target="_blank">
        <picture>
          <img alt="Complex medical scenario" src="docs/images/demo1.png" /></picture>
      </a>
    </td>
  </tr>
  <tr>
    <td>
      <a href="https://www.bilibili.com/video/BV1VC96Y5EMH" target="_blank">
        <picture>
          <img alt="Playing music, checking weather, and broadcasting news" src="docs/images/demo7.png" /></picture>
      </a>
    </td>
    <td>
      <a href="https://www.bilibili.com/video/BV12J7WzBEaH" target="_blank">
        <picture>
          <img alt="Real-time interruption" src="docs/images/demo10.png" /></picture>
      </a>
    </td>
    <td>
      <a href="https://www.bilibili.com/video/BV1Co76z7EvK" target="_blank">
        <picture>
          <img alt="Take a photo to identify objects" src="docs/images/demo12.png" /></picture>
      </a>
    </td>
    <td>
      <a href="https://www.bilibili.com/video/BV1pNXWYGEx1" target="_blank">
        <picture>
          <img alt="Controlling home appliance switches" src="docs/images/demo5.png" /></picture>
      </a>
    </td>
    <td>
      <a href="https://www.bilibili.com/video/BV1TJ7WzzEo6" target="_blank">
        <picture>
          <img alt="Multi-command tasks" src="docs/images/demo11.png" /></picture>
      </a>
    </td>
  </tr>
  <tr>
    <td>
      <a href="https://www.bilibili.com/video/BV1ZQKUzYExM" target="_blank">
        <picture>
          <img alt="MCP endpoint" src="docs/images/demo13.png" /></picture>
      </a>
    </td>
    <td>
      <a href="https://www.bilibili.com/video/BV1zUW5zJEkq" target="_blank">
        <picture>
          <img alt="MQTT command delivery" src="docs/images/demo4.png" /></picture>
      </a>
    </td>
    <td>
      <a href="https://www.bilibili.com/video/BV1Exu3zqEDe" target="_blank">
        <picture>
          <img alt="Voiceprint recognition" src="docs/images/demo14.png" /></picture>
      </a>
    </td>
    <td>
      <a href="https://www.bilibili.com/video/BV1CDKWemEU6" target="_blank">
        <picture>
          <img alt="Custom voice" src="docs/images/demo2.png" /></picture>
      </a>
    </td>
    <td>
      <a href="https://www.bilibili.com/video/BV12yA2egEaC" target="_blank">
        <picture>
          <img alt="Talking in Cantonese" src="docs/images/demo3.png" /></picture>
      </a>
    </td>
  </tr>
</table>

---

## Warning ⚠️

1. This project is open-source software. It has no commercial partnership with any third-party API service provider it connects to (including but not limited to speech recognition, large language model, and speech synthesis platforms), and does not provide any form of guarantee for their service quality or the security of funds.
Users are advised to give priority to providers that hold the relevant business licenses, and to read their service agreements and privacy policies carefully. This software does not host any account keys, does not participate in fund transfers, and does not bear the risk of losses on top-up funds.

2. The features of this project are incomplete and it has not passed a network security assessment, so do not use it in a production environment. If you deploy this project on a public network for learning purposes, be sure to put the necessary protections in place.

---

## Deployment Documentation

![Banners](docs/images/banner2.png)

This project provides two deployment methods. Please choose according to your needs:

#### 🚀 Choosing a Deployment Method
| Deployment Method | Features | Use Cases | Deployment Docs | Requirements | Video Tutorial | 
|---------|------|---------|---------|---------|---------|
| **Minimal Installation** | Intelligent conversation, single-agent management | Low-spec environments; data is stored in the config file, no database needed | [①Docker version](./docs/Deployment.md#method-1-docker-runs-only-the-server) / [②Source deployment](./docs/Deployment.md#method-2-run-only-the-server-from-local-source)| 2 cores 4 GB if using `FunASR`; 2 cores 2 GB if using all APIs | - | 
| **Full-Module Installation** | Intelligent conversation, multi-user management, multi-agent management, Control Panel UI | Full-featured experience; data is stored in a database |[①Docker version](./docs/Deployment_all.md#method-1-run-all-modules-with-docker) / [②Source deployment](./docs/Deployment_all.md#method-2-run-all-modules-from-local-source) / [③Source deployment auto-update guide](./docs/dev-ops-integration.md) | 4 cores 8 GB if using `FunASR`; 2 cores 4 GB if using all APIs| [Local source startup video tutorial](https://www.bilibili.com/video/BV1wBJhz4Ewe) | 

For FAQs and related tutorials, see [this link](./docs/FAQ.md)

> 💡 Tip: The following is a test platform deployed from the latest code. You can flash a device to test it if needed. It supports 6 concurrent connections, and data is cleared every day.

```
Control Panel URL: https://2662r3426b.vicp.fun
Control Panel (H5 version): https://2662r3426b.vicp.fun/h5/index.html

Service test tool: https://2662r3426b.vicp.fun/test/
OTA API URL: https://2662r3426b.vicp.fun/xiaozhi/ota/
WebSocket API URL: wss://2662r3426b.vicp.fun/xiaozhi/v1/
```

#### 🚩 Configuration Notes and Recommendations
> [!Note]
> This project provides two configuration options:
> 
> 1. `Entry-level, fully free` configuration: suitable for personal and home use. All components use free options, with no extra cost.
> 
> 2. `Streaming` configuration: suitable for demos, training, more than 2 concurrent connections, and similar scenarios. It uses streaming processing for faster responses and a better experience.
> 
> Since version `0.5.2`, the project supports the streaming configuration. Compared with earlier versions, response time is reduced by about `2.5 seconds`, significantly improving the user experience.

| Module | Entry-level Fully Free Setup | Streaming Configuration |
|:---:|:---:|:---:|
| ASR (speech recognition) | FunASR (local) | 👍XunfeiStreamASR (iFlytek streaming) |
| LLM (large language model) | glm-4-flash (Zhipu) | 👍qwen-flash (Alibaba Bailian) |
| VLLM (vision large model) | glm-4v-flash (Zhipu) | 👍qwen3.5-flash (Alibaba Bailian) |
| TTS (speech synthesis) | EdgeTTS (Microsoft) | 👍DoubaoTTS (Volcano Engine) |
| Intent (intent recognition) | function_call (function calling) | function_call (function calling) |
| Memory (memory feature) | mem_local_short (local short-term memory) | mem_local_short (local short-term memory) |

If you care about the latency of each component, see the [Xiaozhi component performance test report](https://github.com/xinnan-tech/xiaozhi-performance-research); you can follow the test method in the report to test in your own environment.

#### 🔧 Test Tools
This project provides the following test tools to help you verify the system and choose suitable models:

| Tool | Location | Usage | Description |
|:---:|:---|:---:|:---:|
| Audio interaction test tool | main > digital-human > index.html | Run `python start.py` in `main/digital-human`, then visit `http://127.0.0.1:8006/index.html` | Tests audio playback and reception, and verifies that Python-side audio processing works correctly |
| Model response test tool | main > xiaozhi-server > performance_tester.py | Run `python performance_tester.py` | Tests the response speed of the core modules: ASR (speech recognition), LLM (large language model), VLLM (vision model), and TTS (speech synthesis) |

> 💡 Tip: When testing model speed, only models with a configured key are tested.

---
## Feature List ✨
### Implemented ✅
![See: full-module installation architecture diagram](docs/images/deploy2.png)
| Feature | Description |
|:---:|:---|
| Core architecture | Based on the [MQTT+UDP gateway](https://github.com/xinnan-tech/xiaozhi-esp32-server/blob/main/docs/mqtt-gateway-integration.md), WebSocket, and HTTP server, with a complete console management and authentication system |
| Voice interaction | Supports streaming ASR (speech recognition), streaming TTS (speech synthesis), and VAD (voice activity detection), with multilingual recognition and speech processing |
| Voiceprint recognition | Supports multi-user voiceprint registration, management, and recognition. Runs in parallel with ASR, identifies the speaker in real time, and passes the identity to the LLM for personalized responses |
| Intelligent conversation | Supports multiple LLMs (large language models) for intelligent conversation |
| Visual perception | Supports multiple VLLMs (vision large models) for multimodal interaction |
| Intent recognition | Supports external LLM intent recognition and autonomous LLM function calling, with a pluggable intent-handling mechanism |
| Memory system | Supports local short-term memory, mem0ai API memory, and PowerMem intelligent memory, with memory summarization |
| Knowledge base | Supports the RAGFlow knowledge base; the LLM decides whether to query the knowledge base before answering |
| Tool calling | Supports the client IoT protocol, client MCP protocol, server MCP protocol, MCP endpoint protocol, and custom tool functions |
| Command delivery | Built on the MQTT protocol, supports delivering MCP commands from the Control Panel to ESP32 devices |
| Admin console | Provides a web management interface supporting user management, system configuration, and device management; the UI supports Simplified Chinese, Traditional Chinese, and English |
| Test tools | Provides a performance test tool, a vision model test tool, and an audio interaction test tool |
| Deployment support | Supports Docker deployment and local deployment, with complete configuration file management |
| Plugin system | Supports feature plugin extensions, custom plugin development, and hot plugin loading |

### In Development 🚧

To see the detailed development plan and progress, [click here](https://github.com/users/xinnan-tech/projects/3). For FAQs and related tutorials, see [this link](./docs/FAQ.md)

If you are a software developer, here is an [Open Letter to Developers](docs/contributor_open_letter.md). You are welcome to join!

---

## Product Ecosystem 👬
Xiaozhi is an ecosystem. While using this product, you can also check out other [excellent projects](https://github.com/78/xiaozhi-esp32/blob/main/README_zh.md#%E7%9B%B8%E5%85%B3%E5%BC%80%E6%BA%90%E9%A1%B9%E7%9B%AE)

---

## Platforms and Components Supported by This Project 📋
### LLM (Language Models)

| Usage | Supported Platforms | Free Platforms |
|:---:|:---:|:---:|
| openai API call | Alibaba Bailian, Volcano Engine, DeepSeek, Zhipu, Gemini, iFlytek | Zhipu, Gemini |
| ollama API call | Ollama | - |
| openrouter API call | OpenRouter | - |
| dify API call | Dify | - |
| fastgpt API call | Fastgpt | - |
| coze API call | Coze | - |
| xinference API call | Xinference | - |
| homeassistant API call | HomeAssistant | - |

In fact, any LLM that supports the openai API can be connected and used.

---

### VLLM (Vision Models)

| Usage | Supported Platforms | Free Platforms |
|:---:|:---:|:---:|
| openai API call | Alibaba Bailian, Zhipu ChatGLMVLLM | Zhipu ChatGLMVLLM |

In fact, any VLLM that supports the openai API can be connected and used.

---

### TTS (Speech Synthesis)

| Usage | Supported Platforms | Free Platforms |
|:---:|:---:|:---:|
| API call | EdgeTTS, Volcano Engine, Tencent Cloud, Alibaba Cloud, CosyVoiceSiliconflow, TTS302AI, CozeCnTTS, GizwitsTTS, ACGNTTS, OpenAITTS, Lingxi Streaming TTS | Lingxi Streaming TTS, EdgeTTS, CosyVoiceSiliconflow (partial) |
| Local service | FishSpeech, GPT_SOVITS_V2, GPT_SOVITS_V3, PaddleSpeech | PaddleSpeech, FishSpeech, GPT_SOVITS_V2, GPT_SOVITS_V3 |

---

### VAD (Voice Activity Detection)

| Type  |   Platform    | Usage | Pricing | Notes |
|:---:|:---------:|:----:|:----:|:--:|
| VAD | SileroVAD | Local |  Free  |    |

---

### ASR (Speech Recognition)

| Usage | Supported Platforms | Free Platforms |
|:---:|:---:|:---:|
| Local | FunASR, SherpaASR | FunASR, SherpaASR |
| API call | FunASRServer, Volcano Engine, iFlytek, Tencent Cloud, Alibaba Cloud, Baidu Cloud, OpenAI ASR | FunASRServer |

---

### Voiceprint (Voiceprint Recognition)

| Usage | Supported Platforms | Free Platforms |
|:---:|:---:|:---:|
| Local | 3D-Speaker | 3D-Speaker |

---

### Memory (Memory Storage)

|   Type   |      Platform       | Usage |   Pricing    | Notes |
|:------:|:---------------:|:----:|:---------:|:--:|
| Memory |     mem0ai      | API call | 1000 calls/month quota |    |
| Memory |     [powermem](./docs/powermem-integration.md)    | Local summarization | Depends on the LLM and DB |  Open-sourced by OceanBase, supports intelligent retrieval  |
| Memory | mem_local_short | Local summarization |    Free     |    |
| Memory |     nomem       | No-memory mode |    Free     |    |

---

### Intent (Intent Recognition)

|   Type   |     Platform      | Usage |  Pricing   |          Notes           |
|:------:|:-------------:|:----:|:-------:|:---------------------:|
| Intent |  intent_llm   | API call | Depends on the LLM |    Recognizes intent via the LLM, highly general     |
| Intent | function_call | API call | Depends on the LLM | Completes intents through LLM function calling; fast and effective |
| Intent |    nointent   | No-intent mode |    Free     |    No intent recognition; returns the conversation result directly     |

---

### Rag (Retrieval-Augmented Generation)

|   Type   |     Platform      | Usage |  Pricing   |          Notes           |
|:------:|:-------------:|:----:|:-------:|:---------------------:|
| Rag |  ragflow   | API call | Charged by tokens consumed in chunking and tokenization |    Uses RagFlow's retrieval-augmented generation to provide more accurate conversation replies     |

---

## Acknowledgments 🙏

| Logo | Project/Company | Description |
|:---:|:---:|:---|
| <img src="./docs/images/logo_bailing.png" width="160"> | [Bailing voice dialogue robot](https://github.com/wwbin2017/bailing) | This project was inspired by the [Bailing voice dialogue robot](https://github.com/wwbin2017/bailing) and built on top of it |
| <img src="./docs/images/logo_tenclass.png" width="160"> | [Tenclass](https://www.tenclass.com/) | Thanks to [Tenclass](https://www.tenclass.com/) for establishing the standard communication protocol, multi-device compatibility solutions, and high-concurrency practice examples for the Xiaozhi ecosystem, and for providing end-to-end technical documentation for this project |
| <img src="./docs/images/logo_xuanfeng.png" width="160"> | [Xuanfeng Technology](https://github.com/Eric0308) | Thanks to [Xuanfeng Technology](https://github.com/Eric0308) for contributing the implementation of the function-calling framework, the MCP communication protocol, and the pluggable invocation mechanism. Through a standardized command scheduling system and dynamic extensibility, it significantly improves the interaction efficiency and functional extensibility of front-end (IoT) devices |
| <img src="./docs/images/logo_junsen.png" width="160"> | [huangjunsen](https://github.com/huangjunsen0406) | Thanks to [huangjunsen](https://github.com/huangjunsen0406) for contributing the `Control Panel mobile` module, which enables efficient control of and real-time interaction with cross-platform mobile devices and greatly improves the system's usability and management efficiency in mobile scenarios |
| <img src="./docs/images/logo_huiyuan.png" width="160"> | [Huiyuan Design](http://ui.kwd988.net/) | Thanks to [Huiyuan Design](http://ui.kwd988.net/) for providing professional visual design solutions for this project, bringing its design experience from serving over a thousand companies to improve the product's user experience |
| <img src="./docs/images/logo_qinren.png" width="160"> | [Xi'an Qinren Information Technology](https://www.029app.com/) | Thanks to [Xi'an Qinren Information Technology](https://www.029app.com/) for deepening the visual system of this project, ensuring consistency and extensibility of the overall design style across scenarios |
| <img src="./docs/images/logo_contributors.png" width="160"> | [Code contributors](https://github.com/xinnan-tech/xiaozhi-esp32-server/graphs/contributors) | Thanks to [all code contributors](https://github.com/xinnan-tech/xiaozhi-esp32-server/graphs/contributors). Your efforts make the project more robust and powerful. |


<a href="https://www.star-history.com/?repos=xinnan-tech%2Fxiaozhi-esp32-server&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=xinnan-tech/xiaozhi-esp32-server&type=date&theme=dark&legend=top-left&sealed_token=cQovHKgZjqEnQ-svfYfN392irNvGuq-6pyv4cA8nd2jQEhQLz1ETV4YHTVk2UZyLMFbCQuZA7jduRh3YbeK5WPYaRLrfmIimGQa3lram652jJL9oQk-UuSZA5H6L4dPIhZc8KCc-Ur_UAUNbly7TePpnTR2otGknBLCOjOliD4fk1st6z7tPEDVjSRx5" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=xinnan-tech/xiaozhi-esp32-server&type=date&legend=top-left&sealed_token=cQovHKgZjqEnQ-svfYfN392irNvGuq-6pyv4cA8nd2jQEhQLz1ETV4YHTVk2UZyLMFbCQuZA7jduRh3YbeK5WPYaRLrfmIimGQa3lram652jJL9oQk-UuSZA5H6L4dPIhZc8KCc-Ur_UAUNbly7TePpnTR2otGknBLCOjOliD4fk1st6z7tPEDVjSRx5" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=xinnan-tech/xiaozhi-esp32-server&type=date&legend=top-left&sealed_token=cQovHKgZjqEnQ-svfYfN392irNvGuq-6pyv4cA8nd2jQEhQLz1ETV4YHTVk2UZyLMFbCQuZA7jduRh3YbeK5WPYaRLrfmIimGQa3lram652jJL9oQk-UuSZA5H6L4dPIhZc8KCc-Ur_UAUNbly7TePpnTR2otGknBLCOjOliD4fk1st6z7tPEDVjSRx5" />
 </picture>
</a>