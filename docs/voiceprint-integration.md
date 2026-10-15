# Voiceprint Recognition Enablement Guide

This tutorial has 3 parts
- 1. How to deploy the voiceprint recognition service
- 2. How to configure the voiceprint recognition API in a full-module deployment
- 3. How to configure voiceprint recognition in a minimal deployment

# 1. How to Deploy the Voiceprint Recognition Service

## Step 1: Download the Voiceprint Recognition Project Source Code

Open the [voiceprint recognition project](https://github.com/xinnan-tech/voiceprint-api) in a browser

After it opens, find the green button labeled `Code` on the page, click it, and you will see the `Download ZIP` button.

Click it to download the project source archive. After it is downloaded to your computer, extract it. At this point its name may be `voiceprint-api-main`.
You need to rename it to `voiceprint-api`.

## Step 2: Create the Database and Tables

Voiceprint recognition depends on the `mysql` database. If you have previously deployed the `Control Panel`, you already have `mysql` installed, and you can share it.

Try using the `telnet` command on the host to see whether you can reach port `3306` of `mysql`.
```
telnet 127.0.0.1 3306
```
If you can reach port 3306, ignore the content below and go straight to Step 3.

If you cannot, recall how your `mysql` was installed.

If you installed mysql yourself from an installation package, your `mysql` is network-isolated. You may first need to solve the problem of accessing port `3306` of `mysql`.

If your `mysql` was installed through this project's `docker-compose_all.yml`, find the `docker-compose_all.yml` file you used when you created the database and modify the following

Before
```
  xiaozhi-esp32-server-db:
    ...
    networks:
      - default
    expose:
      - "3306:3306"
```

After
```
  xiaozhi-esp32-server-db:
    ...
    networks:
      - default
    ports:
      - "3306:3306"
```

Note that you need to change `expose` to `ports` under `xiaozhi-esp32-server-db`. After the change, restart is required. The following are the commands to restart mysql:

```
# Go to the folder containing your docker-compose_all.yml, for example mine is xiaozhi-server
cd xiaozhi-server
docker compose -f docker-compose_all.yml down
docker compose -f docker-compose.yml up -d
```

After it starts, use the `telnet` command on the host again to see whether you can reach port `3306` of `mysql`.
```
telnet 127.0.0.1 3306
```
Normally it should be reachable now.

## Step 3: Create the Database and Tables
If your host can reach the mysql database normally, create a database named `voiceprint_db` and a `voiceprints` table on mysql.

```
CREATE DATABASE voiceprint_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE voiceprint_db;

CREATE TABLE voiceprints (
    id INT AUTO_INCREMENT PRIMARY KEY,
    speaker_id VARCHAR(255) NOT NULL UNIQUE,
    feature_vector LONGBLOB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_speaker_id (speaker_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## Step 4: Configure the Database Connection

Go into the `voiceprint-api` folder and create a folder named `data`.

Copy `voiceprint.yaml` from the root of `voiceprint-api` into the `data` folder and rename it to `.voiceprint.yaml`

Next, you need to focus on configuring the database connection in `.voiceprint.yaml`.

```
mysql:
  host: "127.0.0.1"
  port: 3306
  user: "root"
  password: "your_password"
  database: "voiceprint_db"
```

Note! Because your voiceprint recognition service is deployed with docker, `host` must be set to the `LAN IP of the machine where mysql runs`.

Note! Because your voiceprint recognition service is deployed with docker, `host` must be set to the `LAN IP of the machine where mysql runs`.

Note! Because your voiceprint recognition service is deployed with docker, `host` must be set to the `LAN IP of the machine where mysql runs`.

## Step 5: Start the Program
This is a very simple project, and running it with docker is recommended. If you do not want to use docker, you can run it from source by following [this page](https://github.com/xinnan-tech/voiceprint-api/blob/main/README.md). The following is the docker method

```
# Go to the root directory of this project's source code
cd voiceprint-api

# Clear the cache
docker compose -f docker-compose.yml down
docker stop voiceprint-api
docker rm voiceprint-api
docker rmi ghcr.nju.edu.cn/xinnan-tech/voiceprint-api:latest

# Start the docker container
docker compose -f docker-compose.yml up -d
# View the logs
docker logs -f voiceprint-api
```

At this point, logs similar to the following are printed
```
250711 INFO-🚀 Starting: production server started (Uvicorn), listening on: 0.0.0.0:8005
250711 INFO-============================================================
250711 INFO-Voiceprint API address: http://127.0.0.1:8005/voiceprint/health?key=abcd
250711 INFO-============================================================
```

Copy the voiceprint API address:

Because you deployed with docker, do NOT use the address above directly!

Because you deployed with docker, do NOT use the address above directly!

Because you deployed with docker, do NOT use the address above directly!

First copy the address into a scratch file. You need to know your computer's LAN IP. For example, my computer's LAN IP is `192.168.1.25`, so
my original API address
```
http://127.0.0.1:8005/voiceprint/health?key=abcd

```
needs to be changed to
```
http://192.168.1.25:8005/voiceprint/health?key=abcd
```

After changing it, use a browser to directly visit the `voiceprint API address`. If the browser shows code like the following, it worked.
```
{"total_voiceprints":0,"status":"healthy"}
```

Keep the modified `voiceprint API address`, because you will need it in the next step.

# 2. How to Configure Voiceprint Recognition in a Full-Module Deployment

## Step 1: Configure the API
First, enable the voiceprint recognition feature. In the Control Panel, click `Parameter Dictionary` at the top, and in the dropdown menu click the `System Feature Configuration` page. Check `Voiceprint Recognition` on the page and click `Save Configuration`. You will then see the `Voiceprint Recognition` button on the card of newly created agents.

If you use the full-module deployment, log in to the Control Panel with the administrator account, click `Parameter Dictionary` at the top, and choose `Parameter Management`.

Then search for the parameter `server.voice_print`. Its value should be `null` at this point.
Click the Edit button, paste the `voiceprint API address` obtained in the previous step into `Parameter Value`, and then save.

If it saves successfully, everything went well and you can go to the agent to see the result. If not, the Control Panel cannot reach voiceprint recognition, most likely because of a network firewall or an incorrect LAN IP.

## Step 2: Set the Agent's Memory Mode

Go to your agent's role configuration and set memory to `Local short-term memory`. Be sure to enable `Report text + voice`.

## Step 3: Chat with Your Agent

Power on your device and chat with it at a normal speaking speed and tone.

## Step 4: Set Up Voiceprints

In the Control Panel, on the `Agent Management` page, there is a `Voiceprint Recognition` button on the agent's panel; click it. At the bottom there is an `Add button`, which lets you register the voiceprint of what a person says.
In the popup, it is recommended to fill in the `Description` field, which can be this person's occupation, personality, or hobbies. This helps the agent analyze and understand the speaker.

## Step 3: Chat with Your Agent

Power on your device and ask it, "Do you know who I am?" If it can answer, voiceprint recognition is working.

# 3. How to Configure Voiceprint Recognition in a Minimal Deployment

## Step 1: Configure the API
Open the `xiaozhi-server/data/.config.yaml` file (create it if it does not exist), then add/modify the following:

```
# Voiceprint recognition configuration
voiceprint:
  # Voiceprint API address
  url: your voiceprint API address
  # Speaker configuration: speaker_id,name,description
  speakers:
    - "test1,Alice,Alice is a programmer"
    - "test2,Bob,Bob is a product manager"
    - "test3,Carol,Carol is a designer"
```

Paste the `voiceprint API address` obtained in the previous step into `url`. Then save.

Add the `speakers` parameter as needed. Pay attention to the `speaker_id` parameter here, because it is used later when registering voiceprints.

## Step 2: Register Voiceprints
If you have already started the voiceprint service, visit `http://localhost:8005/voiceprint/docs` in a local browser to view the API documentation. Here we only explain how to use the voiceprint registration API.

The voiceprint registration API address is `http://localhost:8005/voiceprint/register`, and the request method is POST.

The request header must include Bearer Token authentication. The token is the part of the `voiceprint API address` after `?key=`. For example, if my voiceprint address is `http://127.0.0.1:8005/voiceprint/health?key=abcd`, then my token is `abcd`.

The request body contains the speaker ID (speaker_id) and a WAV audio file (file). A request example follows:

```
curl -X POST \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "speaker_id=your_speaker_id_here" \
  -F "file=@/path/to/your/file" \
  http://localhost:8005/voiceprint/register
```

 Here `file` is the audio file of the speaker to be registered speaking, and `speaker_id` must match the `speaker_id` configured in Step 1. For example, if I need to register Alice's voiceprint and Alice's `speaker_id` in `.config.yaml` is `test1`, then when registering Alice's voiceprint I put `test1` as the `speaker_id` in the request body and the audio file of Alice speaking as `file`.

 ## Step 3: Start the Service

Start the Xiaozhi server and the voiceprint service, and it is ready to use.
