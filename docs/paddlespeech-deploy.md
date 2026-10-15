# Integrating PaddleSpeechTTS with the Xiaozhi Service

## Key Notes
- Advantages: local offline deployment and fast speed
- Disadvantages: as of September 25, 2025, the default model is a Chinese model and does not support English text-to-speech. Text containing English will produce no sound. To support both Chinese and English, you need to train your own model.

## 1. Basic Environment Requirements
Operating system: Windows / Linux / WSL 2

Python version: 3.9 or above (adjust according to the official Paddle tutorial)

Paddle version: the latest official version   ```https://www.paddlepaddle.org.cn/install```

Dependency management tool: conda or venv

## 2. Start the paddlespeech Service
### 1. Pull the source code from the official paddlespeech repository
```bash 
git clone https://github.com/PaddlePaddle/PaddleSpeech.git
```
### 2. Create a virtual environment
```bash

conda create -n paddle_env python=3.10 -y
conda activate paddle_env
```
### 3. Install paddle
Because CPU and GPU architectures differ, create the environment according to the python versions officially supported by Paddle  
```
https://www.paddlepaddle.org.cn/install
```

### 4. Go to the paddlespeech directory
```bash
cd PaddleSpeech
```
### 5. Install paddlespeech
```bash
pip install pytest-runner -i https://pypi.tuna.tsinghua.edu.cn/simple

# Use any one of the following commands
pip install paddlepaddle -i https://mirror.baidu.com/pypi/simple
pip install paddlespeech -i https://pypi.tuna.tsinghua.edu.cn/simple
```
### 6. Download the speech model automatically with a command
```bash
paddlespeech tts --input "Hello, this is a test"
```
This step automatically downloads and caches the model in the local .paddlespeech/models directory

### 7. Modify the tts_online_application.yaml configuration
Reference path ```"PaddleSpeech\demos\streaming_tts_server\conf\tts_online_application.yaml"```
Open the ```tts_online_application.yaml``` file in an editor and set ```protocol``` to ```websocket```

### 8. Start the service
```yaml
paddlespeech_server start --config_file ./demos/streaming_tts_server/conf/tts_online_application.yaml
# Official default startup command:
paddlespeech_server start --config_file ./conf/tts_online_application.yaml
```
Run the command according to the actual location of your ```tts_online_application.yaml```. When you see the following logs, the service has started successfully
```
Prefix dict has been built successfully.
[2025-08-07 10:03:11,312] [   DEBUG] __init__.py:166 - Prefix dict has been built successfully.
INFO:     Started server process [2298]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8092 (Press CTRL+C to quit)
```

## 3. Modify Xiaozhi's Configuration File
### 1.```main/xiaozhi-server/core/providers/tts/paddle_speech.py```

### 2.```main/xiaozhi-server/data/.config.yaml```
Using the single-module deployment
```yaml
selected_module:
  TTS: PaddleSpeechTTS
TTS:
  PaddleSpeechTTS:
      type: paddle_speech
      protocol: websocket 
      url:  ws://127.0.0.1:8092/paddlespeech/tts/streaming  # URL of the TTS service, pointing to the local server [websocket default ws://127.0.0.1:8092/paddlespeech/tts/streaming]
      spk_id: 0  # Speaker ID; 0 usually means the default speaker
      sample_rate: 24000  # Sample rate [websocket default 24000, http default 0 auto-select]
      speed: 1.0  # Speech rate; 1.0 is normal, >1 is faster, <1 is slower
      volume: 1.0  # Volume; 1.0 is normal, >1 is louder, <1 is quieter
      save_path:   # Save path
```
### 3. Start the xiaozhi service
```py
python app.py
```
After starting `python start.py` under `main/digital-human`, open `http://127.0.0.1:8006/index.html` and test whether the paddlespeech side outputs logs when connecting and sending messages

Reference output logs:
```
INFO:     127.0.0.1:44312 - "WebSocket /paddlespeech/tts/streaming" [accepted]
INFO:     connection open
[2025-08-07 11:16:33,355] [    INFO] - sentence: Haha, why are you suddenly chatting with me?
[2025-08-07 11:16:33,356] [    INFO] - The durations of audio is: 2.4625 s
[2025-08-07 11:16:33,356] [    INFO] - first response time: 0.1143045425415039 s
[2025-08-07 11:16:33,356] [    INFO] - final response time: 0.4777836799621582 s
[2025-08-07 11:16:33,356] [    INFO] - RTF: 0.19402382942625715
[2025-08-07 11:16:33,356] [    INFO] - Other info: front time: 0.06514096260070801 s, first am infer time: 0.008037090301513672 s, first voc infer time: 0.04112648963928223 s,
[2025-08-07 11:16:33,356] [    INFO] - Complete the synthesis of the audio streams
INFO:     connection closed

```
