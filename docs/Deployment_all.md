# Deployment Architecture Diagram
![See: full-module installation architecture diagram](../docs/images/deploy2.png)
# Method 1: Run all modules with Docker
Starting from version `0.8.2`, the docker images released by this project only support the `x86 architecture`. If you need to deploy on an `arm64 architecture` CPU, you can follow [this tutorial](docker-build.md) to build the `arm64 image` locally.

## 1. Install docker

If docker is not yet installed on your computer, you can install it by following this tutorial: [Install docker](https://www.runoob.com/docker/ubuntu-docker-install.html)

There are two ways to install all modules with docker. You can [use the lazy script](./Deployment_all.md#11-lazy-script) (author: [@VanillaNahida](https://github.com/VanillaNahida)).  
The script automatically downloads the required files and configuration files for you. You can also use [manual deployment](./Deployment_all.md#12-manual-deployment) to build everything from scratch.



### 1.1 Lazy Script
Deployment is simple. See the [video tutorial](https://www.bilibili.com/video/BV17bbvzHExd/); the text version of the tutorial follows:
> [!NOTE]  
> Currently only one-click deployment on Ubuntu servers is supported. Other systems have not been tried and may have some odd bugs.

Connect to the server with an SSH tool and run the following script as root
```bash
sudo bash -c "$(wget -qO- https://ghfast.top/https://raw.githubusercontent.com/xinnan-tech/xiaozhi-esp32-server/main/docker-setup.sh)"
```

The script automatically does the following:
> 1. Install Docker
> 2. Configure registry mirrors
> 3. Download/pull images
> 4. Download the speech recognition model file
> 5. Guide you through configuring the server
>

After the script finishes and you complete the simple configuration, follow the 3 most important things mentioned in [4. Run the program](#4-run-the-program) and [5. Restart xiaozhi-esp32-server](#5-restart-xiaozhi-esp32-server). Once these three items are configured, you can start using it.

### 1.2 Manual Deployment

#### 1.2.1 Create the directories

After installation, you need to pick a directory for this project's configuration files. For example, we can create a folder called `xiaozhi-server`.

After creating the directory, create the `data` folder and the `models` folder under `xiaozhi-server`, and then create a `SenseVoiceSmall` folder under `models`.

The final directory structure looks like this:

```
xiaozhi-server
  ├─ data
  ├─ models
     ├─ SenseVoiceSmall
```

#### 1.2.2 Download the speech recognition model file

By default, this project uses the `SenseVoiceSmall` model for speech-to-text. Because the model is large, it must be downloaded separately. After downloading, put the `model.pt`
file in the `models/SenseVoiceSmall`
directory. Choose either of the two download routes below.

- Route 1: Download from Alibaba ModelScope: [SenseVoiceSmall](https://modelscope.cn/models/iic/SenseVoiceSmall/resolve/master/model.pt)
- Route 2: Download from Baidu Netdisk: [SenseVoiceSmall](https://pan.baidu.com/share/init?surl=QlgM58FHhYv1tFnUT_A8Sg&pwd=qvna) Extraction code:
  `qvna`


#### 1.2.3 Download the configuration files

You need to download two configuration files: `docker-compose_all.yaml` and `config_from_api.yaml`. Both files must be downloaded from the project repository.

##### 1.2.3.1 Download docker-compose_all.yaml

Open [this link](../main/xiaozhi-server/docker-compose_all.yml) in a browser.

On the right side of the page, find the button named `RAW`. Next to the `RAW` button, find the download icon and click it to download the `docker-compose_all.yml` file. Download the file into your
`xiaozhi-server`.

Or run `wget https://raw.githubusercontent.com/xinnan-tech/xiaozhi-esp32-server/refs/heads/main/main/xiaozhi-server/docker-compose_all.yml` directly to download it.

After downloading, come back to this tutorial and continue.

##### 1.2.3.2 Download config_from_api.yaml

Open [this link](../main/xiaozhi-server/config_from_api.yaml) in a browser.

On the right side of the page, find the button named `RAW`. Next to the `RAW` button, find the download icon and click it to download the `config_from_api.yaml` file. Download the file into the `data` folder under your
`xiaozhi-server`, and then rename the `config_from_api.yaml` file to `.config.yaml`.

Or run `wget https://raw.githubusercontent.com/xinnan-tech/xiaozhi-esp32-server/refs/heads/main/main/xiaozhi-server/config_from_api.yaml` directly to download and save it.

After downloading the configuration files, let's confirm that the files in `xiaozhi-server` look like this:

```
xiaozhi-server
  ├─ docker-compose_all.yml
  ├─ data
    ├─ .config.yaml
  ├─ models
     ├─ SenseVoiceSmall
       ├─ model.pt
```

If your directory structure matches the one above, continue. If not, look carefully to see whether you missed a step.

## 2. Back up your data

If you have previously run the Control Panel successfully and it holds your key information, first copy the important data from the Control Panel, because the upgrade process may overwrite the original data.

## 3. Remove old images and containers
Next, open a command-line tool (`Terminal` or `Command Prompt`), go to your `xiaozhi-server` directory, and run the following commands

```
docker compose -f docker-compose_all.yml down

docker stop xiaozhi-esp32-server
docker rm xiaozhi-esp32-server

docker stop xiaozhi-esp32-server-web
docker rm xiaozhi-esp32-server-web

docker stop xiaozhi-esp32-server-db
docker rm xiaozhi-esp32-server-db

docker stop xiaozhi-esp32-server-redis
docker rm xiaozhi-esp32-server-redis

docker rmi ghcr.nju.edu.cn/xinnan-tech/xiaozhi-esp32-server:server_latest
docker rmi ghcr.nju.edu.cn/xinnan-tech/xiaozhi-esp32-server:web_latest
```

## 4. Run the program
Run the following command to start the new version of the containers

```
docker compose -f docker-compose_all.yml up -d
```

After it finishes, run the following command to view the logs.

```
docker logs -f xiaozhi-esp32-server-web
```

When you see this log output, your `Control Panel` has started successfully.

```
2025-xx-xx 22:11:12.445 [main] INFO  c.a.d.s.b.a.DruidDataSourceAutoConfigure - Init DruidDataSource
2025-xx-xx 21:28:53.873 [main] INFO  xiaozhi.AdminApplication - Started AdminApplication in 16.057 seconds (process running for 17.941)
http://localhost:8002/xiaozhi/doc.html
```

Note that only the `Control Panel` is running at this point. If the `xiaozhi-esp32-server` on port 8000 reports errors, ignore them for now.

At this point, use a browser to open the `Control Panel` at http://127.0.0.1:8002 and register the first user. The first user is the super administrator; later users are regular users. Regular users can only bind devices and configure agents; the super administrator can manage models, manage users, configure parameters, and more.

Next, there are three important things to do:

### The First Important Thing

Log in to the Control Panel with the super administrator account, find `Parameter Management` in the top menu, find the first entry in the list (parameter code `server.secret`), and copy its `Parameter Value`.

A note on `server.secret`: this `Parameter Value` is very important. It lets our `Server` connect to `manager-api`. `server.secret` is a key that is randomly generated automatically each time the manager module is deployed from scratch.

After copying the `Parameter Value`, open the `.config.yaml` file in the `data` directory under `xiaozhi-server`. At this point your configuration file should look like this:

```
manager-api:
  url:  http://127.0.0.1:8002/xiaozhi
  secret: your server.secret value
```
1. Copy the `Parameter Value` of `server.secret` that you just copied from the `Control Panel` into `secret` in the `.config.yaml` file.

2. Because you deployed with docker, change `url` to the following: `http://xiaozhi-esp32-server-web:8002/xiaozhi`

3. Because you deployed with docker, change `url` to the following: `http://xiaozhi-esp32-server-web:8002/xiaozhi`

4. Because you deployed with docker, change `url` to the following: `http://xiaozhi-esp32-server-web:8002/xiaozhi`

The result should look something like this
```
manager-api:
  url: http://xiaozhi-esp32-server-web:8002/xiaozhi
  secret: 12345678-xxxx-xxxx-xxxx-123456789000
```

After saving, continue with the second important thing

### The Second Important Thing

Log in to the Control Panel with the super administrator account, find `Model Configuration` in the top menu, click `Large Language Model` in the left sidebar, find the first entry `Zhipu AI`, and click the `Edit` button.
When the edit dialog appears, enter the `Zhipu AI` key you registered into `API Key`, then click Save.

## 5. Restart xiaozhi-esp32-server

Next, open a command-line tool (`Terminal` or `Command Prompt`) and enter
```
docker restart xiaozhi-esp32-server
docker logs -f xiaozhi-esp32-server
```
If you see logs similar to the following, the Server has started successfully.

```
25-02-23 12:01:09[core.websocket_server] - INFO - Websocket address is ws://xxx.xx.xx.xx:8000/xiaozhi/v1/
25-02-23 12:01:09[core.websocket_server] - INFO - =======The address above is a websocket protocol address; do not open it in a browser=======
25-02-23 12:01:09[core.websocket_server] - INFO - To test websocket, start the digital-human module and use the browser for interactive testing
25-02-23 12:01:09[core.websocket_server] - INFO - =======================================================
```

Because you deployed all modules, there are two important API addresses that need to be written into the esp32.

OTA API:
```
http://your-host-LAN-ip:8002/xiaozhi/ota/
```

WebSocket API:
```
ws://your-host-ip:8000/xiaozhi/v1/
```

### The Third Important Thing

Log in to the Control Panel with the super administrator account, find `Parameter Management` in the top menu, find the parameter with code `server.websocket`, and enter your `WebSocket API` address.

Log in to the Control Panel with the super administrator account, find `Parameter Management` in the top menu, find the parameter with code `server.ota`, and enter your `OTA API` address.

Next, you can start working with your esp32 device. You can either `build the esp32 firmware yourself` or configure and use `the firmware version 1.6.1 or above that Brother Xia has already built`. Choose either one.

1. [Build your own esp32 firmware](firmware-build.md).

2. [Configure a custom server based on the firmware built by Brother Xia](firmware-setting.md).


# Method 2: Run all modules from local source

## 1. Install the MySQL database

If MySQL is already installed on this machine, you can directly create a database named `xiaozhi_esp32_server`.

```sql
CREATE DATABASE xiaozhi_esp32_server CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

If you do not have MySQL yet, you can install it with docker

```
docker run --name xiaozhi-esp32-server-db -e MYSQL_ROOT_PASSWORD=123456 -p 3306:3306 -e MYSQL_DATABASE=xiaozhi_esp32_server -e MYSQL_INITDB_ARGS="--character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci" -e TZ=Asia/Shanghai -d mysql:latest
```

## 2. Install Redis

If you do not have Redis yet, you can install it with docker

```
docker run --name xiaozhi-esp32-server-redis -d -p 6379:6379 redis
```

## 3. Run the manager-api program

3.1 Install JDK 21 and set the JDK environment variable

3.2 Install Maven and set the Maven environment variable

3.3 Use VS Code and install the Java environment plugins

3.4 Load the manager-api module in VS Code

Configure the database connection information in `src/main/resources/application-dev.yml`

```
spring:
  datasource:
    username: root
    password: 123456
```
Configure the Redis connection information in `src/main/resources/application-dev.yml`
```
spring:
    data:
      redis:
        host: localhost
        port: 6379
        password:
        database: 0
```

3.5 Run the main program

This project is a SpringBoot project, started as follows:
Open `Application.java` and run the `Main` method to start it

```
Path:
src/main/java/xiaozhi/AdminApplication.java
```

When you see this log output, your `manager-api` has started successfully.

```
2025-xx-xx 22:11:12.445 [main] INFO  c.a.d.s.b.a.DruidDataSourceAutoConfigure - Init DruidDataSource
2025-xx-xx 21:28:53.873 [main] INFO  xiaozhi.AdminApplication - Started AdminApplication in 16.057 seconds (process running for 17.941)
http://localhost:8002/xiaozhi/doc.html
```

## 4. Run the manager-web program

4.1 Install Node.js

4.2 Load the manager-web module in VS Code

In a terminal, go into the manager-web directory

```
npm install
```
Then start it
```
npm run serve
```

Note that if your manager-api is not at `http://localhost:8002`, change the path in
`main/manager-web/.env.development` during development

After it runs successfully, use a browser to open the `Control Panel` at http://127.0.0.1:8001 and register the first user. The first user is the super administrator; later users are regular users. Regular users can only bind devices and configure agents; the super administrator can manage models, manage users, configure parameters, and more.


Important: after registering successfully, log in to the Control Panel with the super administrator account, find `Model Configuration` in the top menu, click `Large Language Model` in the left sidebar, find the first entry `Zhipu AI`, and click the `Edit` button.
When the edit dialog appears, enter the `Zhipu AI` key you registered into `API Key`, then click Save.

Important: after registering successfully, log in to the Control Panel with the super administrator account, find `Model Configuration` in the top menu, click `Large Language Model` in the left sidebar, find the first entry `Zhipu AI`, and click the `Edit` button.
When the edit dialog appears, enter the `Zhipu AI` key you registered into `API Key`, then click Save.

Important: after registering successfully, log in to the Control Panel with the super administrator account, find `Model Configuration` in the top menu, click `Large Language Model` in the left sidebar, find the first entry `Zhipu AI`, and click the `Edit` button.
When the edit dialog appears, enter the `Zhipu AI` key you registered into `API Key`, then click Save.

## 5. Install the Python environment

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

## 6. Install the project dependencies

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

### 7. Download the speech recognition model file

By default, this project uses the `SenseVoiceSmall` model for speech-to-text. Because the model is large, it must be downloaded separately. After downloading, put the `model.pt`
file in the `models/SenseVoiceSmall`
directory. Choose either of the two download routes below.

- Route 1: Download from Alibaba ModelScope: [SenseVoiceSmall](https://modelscope.cn/models/iic/SenseVoiceSmall/resolve/master/model.pt)
- Route 2: Download from Baidu Netdisk: [SenseVoiceSmall](https://pan.baidu.com/share/init?surl=QlgM58FHhYv1tFnUT_A8Sg&pwd=qvna) Extraction code:
  `qvna`

## 8. Configure the project files

Log in to the Control Panel with the super administrator account, find `Parameter Management` in the top menu, find the first entry in the list (parameter code `server.secret`), and copy its `Parameter Value`.

A note on `server.secret`: this `Parameter Value` is very important. It lets our `Server` connect to `manager-api`. `server.secret` is a key that is randomly generated automatically each time the manager module is deployed from scratch.

If your `xiaozhi-server` directory has no `data` directory, you need to create it.
If there is no `.config.yaml` file under `data`, you can copy the `config_from_api.yaml` file from the `xiaozhi-server` directory to `data` and rename it to `.config.yaml`

After copying the `Parameter Value`, open the `.config.yaml` file in the `data` directory under `xiaozhi-server`. At this point your configuration file should look like this:

```
manager-api:
  url: http://127.0.0.1:8002/xiaozhi
  secret: your server.secret value
```

Copy the `Parameter Value` of `server.secret` that you just copied from the `Control Panel` into `secret` in the `.config.yaml` file.

The result should look something like this
```
manager-api:
  url: http://127.0.0.1:8002/xiaozhi
  secret: 12345678-xxxx-xxxx-xxxx-123456789000
```

## 9. Run the project

```
# Make sure you run this in the xiaozhi-server directory
conda activate xiaozhi-esp32-server
python app.py
```

If you see logs similar to the following, the project service has started successfully.

```
25-02-23 12:01:09[core.websocket_server] - INFO - Server is running at ws://xxx.xx.xx.xx:8000/xiaozhi/v1/
25-02-23 12:01:09[core.websocket_server] - INFO - =======The address above is a websocket protocol address; do not open it in a browser=======
25-02-23 12:01:09[core.websocket_server] - INFO - To test websocket, start the digital-human module and use the browser for interactive testing
25-02-23 12:01:09[core.websocket_server] - INFO - =======================================================
```

Because you deployed all modules, you have two important API addresses.

OTA API:
```
http://your-computer-LAN-ip:8002/xiaozhi/ota/
```

WebSocket API:
```
ws://your-computer-LAN-ip:8000/xiaozhi/v1/
```

Be sure to enter the two API addresses above into the Control Panel: they affect websocket address distribution and the automatic upgrade feature.

1. Log in to the Control Panel with the super administrator account, find `Parameter Management` in the top menu, find the parameter with code `server.websocket`, and enter your `WebSocket API` address.

2. Log in to the Control Panel with the super administrator account, find `Parameter Management` in the top menu, find the parameter with code `server.ota`, and enter your `OTA API` address.


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
