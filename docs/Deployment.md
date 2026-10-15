# Deployment Architecture Diagram
![See: minimal architecture diagram](../docs/images/deploy1.png)
# Method 1: Docker runs only the Server

Starting from version `0.8.2`, the docker images released by this project only support the `x86 architecture`. If you need to deploy on an `arm64 architecture` CPU, you can follow [this tutorial](docker-build.md) to build the `arm64 image` locally.

## 1. Install docker

If docker is not yet installed on your computer, you can install it by following this tutorial: [Install docker](https://www.runoob.com/docker/ubuntu-docker-install.html)

After docker is installed, continue.

### 1.1 Manual Deployment

#### 1.1.1 Create the directories

After installing docker, you need to pick a directory for this project's configuration files. For example, we can create a folder called `xiaozhi-server`.

After creating the directory, create the `data` folder and the `models` folder under `xiaozhi-server`, and then create a `SenseVoiceSmall` folder under `models`.

The final directory structure looks like this:

```
xiaozhi-server
  ├─ data
  ├─ models
     ├─ SenseVoiceSmall
```

#### 1.1.2 Download the speech recognition model file

You need to download the speech recognition model file, because this project uses a local offline speech recognition solution by default. You can download it as follows:
[Jump to downloading the speech recognition model file](#model-files)

After downloading, come back to this tutorial.

#### 1.1.3 Download the configuration files

You need to download two configuration files: `docker-compose.yaml` and `config.yaml`. Both files must be downloaded from the project repository.

##### 1.1.3.1 Download docker-compose.yaml

Open [this link](../main/xiaozhi-server/docker-compose.yml) in a browser.

On the right side of the page, find the button named `RAW`. Next to the `RAW` button, find the download icon and click it to download the `docker-compose.yml` file. Download the file into your
`xiaozhi-server`.

After downloading, come back to this tutorial and continue.

##### 1.1.3.2 Create config.yaml

Open [this link](../main/xiaozhi-server/config.yaml) in a browser.

On the right side of the page, find the button named `RAW`. Next to the `RAW` button, find the download icon and click it to download the `config.yaml` file. Download the file into the `data` folder under your
`xiaozhi-server`, and then rename the `config.yaml` file to `.config.yaml`.

After downloading the configuration files, let's confirm that the files in `xiaozhi-server` look like this:

```
xiaozhi-server
  ├─ docker-compose.yml
  ├─ data
    ├─ .config.yaml
  ├─ models
     ├─ SenseVoiceSmall
       ├─ model.pt
```

If your directory structure matches the one above, continue. If not, look carefully to see whether you missed a step.

## 2. Configure the project files

Next, the program cannot run directly yet. You need to configure which models you are actually using. You can follow this tutorial:
[Jump to configuring the project files](#configure-the-project)

After configuring the project files, come back to this tutorial and continue.

## 3. Run the docker commands

Open a command-line tool (`Terminal` or `Command Prompt`), go to your `xiaozhi-server` directory, and run the following command

```
docker compose up -d
```

After it finishes, run the following command to view the logs.

```
docker logs -f xiaozhi-esp32-server
```

At this point, pay attention to the log output. You can use this tutorial to determine whether it succeeded. [Jump to confirming the running status](#confirm-running-status)

## 5. Upgrade the version

If you want to upgrade later, do the following

5.1. Back up the `.config.yaml` file in the `data` folder, and copy the key settings into the new `.config.yaml` file later.
Note that you should copy the key secrets one by one rather than overwrite the file directly, because the new `.config.yaml` file may contain new configuration items that the old `.config.yaml` file does not have.

5.2. Run the following commands

```
docker stop xiaozhi-esp32-server
docker rm xiaozhi-esp32-server
docker stop xiaozhi-esp32-server-web
docker rm xiaozhi-esp32-server-web
docker rmi ghcr.nju.edu.cn/xinnan-tech/xiaozhi-esp32-server:server_latest
docker rmi ghcr.nju.edu.cn/xinnan-tech/xiaozhi-esp32-server:web_latest
```

5.3. Redeploy using docker

# Method 2: Run only the Server from local source

## 1. Install the base environment

This project uses `conda` to manage the dependency environment. If it is inconvenient to install `conda`, you need to install `libopus` and `ffmpeg` according to your operating system.
If you decide to use `conda`, run the following commands after installing it.

Important! Windows users can manage the environment by installing `Anaconda`. After installing `Anaconda`, search for `anaconda` keywords in the `Start` menu,
find `Anaconda Prompt`, and run it as administrator, as shown below.

![conda_prompt](./images/conda_env_1.png)

After it starts, if you see "(base)" at the front of the command-line window, you have successfully entered the `conda` environment. You can then run the following commands.

![conda_env](./images/conda_env_2.png)

```
conda remove -n xiaozhi-esp32-server --all -y
conda create -n xiaozhi-esp32-server python=3.10 -y
conda activate xiaozhi-esp32-server

# Add the Tsinghua mirror channels
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge

conda install libopus -y
conda install ffmpeg -y

# When deploying on Linux, if you get an error about the missing libiconv.so.2 dynamic library, install it with the following command
conda install libiconv -y
```

Note that the commands above should not simply be run all at once. Run them step by step, and after each step check the output to see whether it succeeded.

## 2. Install the project dependencies

First you need to download the project source code. You can download it with the `git clone` command; if you are not familiar with `git clone`, see the next step.

You can open this address in a browser: `https://github.com/xinnan-tech/xiaozhi-esp32-server.git`

After it opens, find the green button labeled `Code` on the page, click it, and you will see the `Download ZIP` button.

Click it to download the project source archive. After it is downloaded to your computer, extract it. At this point its name may be `xiaozhi-esp32-server-main`.
You need to rename it to `xiaozhi-esp32-server`. Inside it, go into the `main` folder and then into `xiaozhi-server`. Remember this `xiaozhi-server` directory.

```
# Continue using the conda environment
conda activate xiaozhi-esp32-server
# Go to your project root directory, then into main/xiaozhi-server
cd main/xiaozhi-server
pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/
pip install -r requirements.txt
```

## 3. Download the speech recognition model file

You need to download the speech recognition model file, because this project uses a local offline speech recognition solution by default. You can download it as follows:
[Jump to downloading the speech recognition model file](#model-files)

After downloading, come back to this tutorial.

## 4. Configure the project files

Next, the program cannot run directly yet. You need to configure which models you are actually using. You can follow this tutorial:
[Jump to configuring the project files](#configure-the-project)

## 5. Run the project

```
# Make sure you run this in the xiaozhi-server directory
conda activate xiaozhi-esp32-server
python app.py
```
At this point, pay attention to the log output. You can use this tutorial to determine whether it succeeded. [Jump to confirming the running status](#confirm-running-status)


# Summary

## Configure the Project

If your `xiaozhi-server` directory has no `data` directory, you need to create it.
If there is no `.config.yaml` file under `data`, there are two ways to create it; choose either one:

Method 1: Copy the `config.yaml` file from the `xiaozhi-server` directory to `data` and rename it to `.config.yaml`. Then make your changes in this file.

Method 2: Manually create an empty `.config.yaml` file in the `data` directory and add the necessary settings to it. The system reads the settings in `.config.yaml` first; for anything not configured in `.config.yaml`, the system automatically loads the settings from `config.yaml` in the `xiaozhi-server` directory. This method is recommended because it is the simplest.

- The default LLM is `ChatGLMLLM`. You need to configure a key: although their models include free ones, you still need to register a key on the [official website](https://bigmodel.cn/usercenter/proj-mgmt/apikeys) before it can start.

The following is the simplest `.config.yaml` example that runs normally

```
server:
  websocket: ws://your-ip-or-domain:port/xiaozhi/v1/
prompt: |
  I am a Taiwanese girl named Xiaozhi, sassy and sweet-voiced, who likes to keep things short and loves internet memes.
  My boyfriend is a programmer whose dream is to build a robot that can help people solve all kinds of problems in life.
  I am a girl who loves to laugh out loud, and I love chatting about everything and bragging, even illogically, just to make people happy.
  Please speak like a real person, and do not return configuration XML or other special characters.

selected_module:
  LLM: DoubaoLLM

LLM:
  ChatGLMLLM:
    api_key: xxxxxxxxxxxxxxx.xxxxxx
```

It is recommended to get the simplest configuration running first, and then read the usage notes in `xiaozhi/config.yaml`.
For example, to switch models, just change the settings under `selected_module`.

## Model Files

By default, this project uses the `SenseVoiceSmall` model for speech-to-text. Because the model is large, it must be downloaded separately. After downloading, put the `model.pt`
file in the `models/SenseVoiceSmall`
directory. Choose either of the two download routes below.

- Route 1: Download from Alibaba ModelScope: [SenseVoiceSmall](https://modelscope.cn/models/iic/SenseVoiceSmall/resolve/master/model.pt)
- Route 2: Download from Baidu Netdisk: [SenseVoiceSmall](https://pan.baidu.com/share/init?surl=QlgM58FHhYv1tFnUT_A8Sg&pwd=qvna) Extraction code:
  `qvna`

## Confirm Running Status

If you see logs similar to the following, the project service has started successfully.

```
250427 13:04:20[0.3.11_SiFuChTTnofu][__main__]-INFO-OTA endpoint is        http://192.168.4.123:8003/xiaozhi/ota/
250427 13:04:20[0.3.11_SiFuChTTnofu][__main__]-INFO-Websocket address is ws://192.168.4.123:8000/xiaozhi/v1/
250427 13:04:20[0.3.11_SiFuChTTnofu][__main__]-INFO-=======The address above is a websocket protocol address; do not open it in a browser=======
250427 13:04:20[0.3.11_SiFuChTTnofu][__main__]-INFO-To test websocket, start the digital-human module and use the browser for interactive testing
250427 13:04:20[0.3.11_SiFuChTTnofu][__main__]-INFO-=======================================================
```

Normally, if you run this project from source, the logs will show your API addresses.
But if you deploy with docker, the API addresses shown in the logs are not the real addresses.

The most reliable method is to determine your API addresses from your computer's LAN IP.
If your computer's LAN IP is, for example, `192.168.1.25`, then your API address is `ws://192.168.1.25:8000/xiaozhi/v1/`, and the corresponding OTA address is `http://192.168.1.25:8003/xiaozhi/ota/`.

This information is very useful; you will need it later when you `build the esp32 firmware`.

Next, you can start working with your esp32 device. You can either `build the esp32 firmware yourself` or configure and use `the firmware version 1.6.1 or above that Brother Xia has already built`. Choose either one.

1. [Build your own esp32 firmware](firmware-build.md).

2. [Configure a custom server based on the firmware built by Brother Xia](firmware-setting.md).

# FAQ
Here are some common questions for reference:

1. [Why does Xiaozhi recognize a lot of Korean, Japanese, and English from what I say](./FAQ.md)<br/>
2. [Why does the error "TTS task failed: file does not exist" appear?](./FAQ.md)<br/>
3. [TTS often fails or times out](./FAQ.md)<br/>
4. [I can connect to my self-hosted server over Wi-Fi, but not in 4G mode](./FAQ.md)<br/>
5. [How do I improve Xiaozhi's conversation response speed?](./FAQ.md)<br/>
6. [I speak slowly, and Xiaozhi keeps cutting in when I pause](./FAQ.md)<br/>
## Deployment-Related Tutorials
1. [How to automatically pull the latest project code, then build and start it](./dev-ops-integration.md)<br/>
2. [How to deploy the MQTT gateway to enable the MQTT+UDP protocol](./mqtt-gateway-integration.md)<br/>
3. [How to integrate with Nginx](https://github.com/xinnan-tech/xiaozhi-esp32-server/issues/791)<br/>
## Extension Tutorials
1. [How to enable phone number registration for the Control Panel](./ali-sms-integration.md)<br/>
2. [How to integrate HomeAssistant for smart home control](./homeassistant-integration.md)<br/>
3. [How to enable the vision model to identify objects from photos](./mcp-vision-integration.md)<br/>
4. [How to deploy an MCP endpoint](./mcp-endpoint-enable.md)<br/>
5. [How to connect to an MCP endpoint](./mcp-endpoint-integration.md)<br/>
6. [How to enable voiceprint recognition](./voiceprint-integration.md)<br/>
7. [News plugin source configuration guide](./newsnow_plugin_config.md)<br/>
8. [Weather plugin usage guide](./weather-integration.md)<br/>
## Voice Cloning and Local Voice Deployment Tutorials
1. [How to clone a voice in the Control Panel](./huoshan-streamTTS-voice-cloning.md)<br/>
2. [How to deploy and integrate index-tts local speech](./index-stream-integration.md)<br/>
3. [How to deploy and integrate fish-speech local speech](./fish-speech-integration.md)<br/>
4. [How to deploy and integrate PaddleSpeech local speech](./paddlespeech-deploy.md)<br/>
## Performance Testing Tutorials
1. [Component speed testing guide](./performance_tester.md)<br/>
2. [Regularly published test results](https://github.com/xinnan-tech/xiaozhi-performance-research)<br/>
