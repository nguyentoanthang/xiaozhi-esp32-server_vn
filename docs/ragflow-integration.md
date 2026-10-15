# ragflow Integration Guide

This tutorial has two main parts

- 1. How to deploy ragflow
- 2. How to configure the ragflow API in the Control Panel

If you are familiar with ragflow and have already deployed it, you can skip the first part and go straight to the second part. But if you want guidance on deploying ragflow so that it shares the `mysql` and `redis` base services with `xiaozhi-esp32-server` to reduce resource costs, start from the first part.

# Part 1: How to Deploy ragflow
## Step 1: Confirm That mysql and redis Are Available

ragflow depends on the `mysql` database. If you have previously deployed the `Control Panel`, you already have `mysql` installed, and you can share it.

Try using the `telnet` command on the host to see whether you can reach port `3306` of `mysql`.
``` shell
telnet 127.0.0.1 3306

telnet 127.0.0.1 6379
```
If you can reach ports `3306` and `6379`, ignore the content below and go straight to Step 2.

If you cannot, recall how your `mysql` was installed.

If you installed mysql yourself from an installation package, your `mysql` is network-isolated. You may first need to solve the problem of accessing port `3306` of `mysql`.

If your `mysql` was installed through this project's `docker-compose_all.yml`, find the `docker-compose_all.yml` file you used when you created the database and modify the following

Before
``` yaml
  xiaozhi-esp32-server-db:
    ...
    networks:
      - default
    expose:
      - "3306:3306"
  xiaozhi-esp32-server-redis:
    ...
    expose:
      - 6379
```

After
``` yaml
  xiaozhi-esp32-server-db:
    ...
    networks:
      - default
    ports:
      - "3306:3306"
  xiaozhi-esp32-server-redis:
    ...
    ports:
      - "6379:6379"
```

Note that you need to change `expose` to `ports` under `xiaozhi-esp32-server-db` and `xiaozhi-esp32-server-redis`. After the change, restart is required. The following are the commands to restart mysql:

``` shell
# Go to the folder containing your docker-compose_all.yml, for example mine is xiaozhi-server
cd xiaozhi-server
docker compose -f docker-compose_all.yml down
docker compose -f docker-compose.yml up -d
```

After it starts, use the `telnet` command on the host again to see whether you can reach port `3306` of `mysql`.
``` shell
telnet 127.0.0.1 3306

telnet 127.0.0.1 6379
```
Normally it should be reachable now.

## Step 2: Create the Database and Tables
If your host can reach the mysql database normally, create a database named `rag_flow` and a user `rag_flow` with the password `infini_rag_flow` on mysql.

``` sql
-- Create the database
CREATE DATABASE IF NOT EXISTS rag_flow CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create the user and grant privileges
CREATE USER IF NOT EXISTS 'rag_flow'@'%' IDENTIFIED BY 'infini_rag_flow';
GRANT ALL PRIVILEGES ON rag_flow.* TO 'rag_flow'@'%';

-- Flush privileges
FLUSH PRIVILEGES;
```

## Step 3: Download the ragflow Project

Find a folder on your computer to store the ragflow project. For example, I use the `/home/system/xiaozhi` folder.

You can use the `git` command to download the ragflow project into this folder. This tutorial installs and deploys version `v0.22.0`.
```
git clone https://ghfast.top/https://github.com/infiniflow/ragflow.git
cd ragflow
git checkout v0.22.0
```
After downloading, go into the `docker` folder.
``` shell
cd docker
```
Edit the `docker-compose.yml` file in the `ragflow/docker` folder and remove the `depends_on` configuration of the `ragflow-cpu` and `ragflow-gpu` services, to remove the dependency of the `ragflow-cpu` service on `mysql`.

This is before the change:
``` yaml
  ragflow-cpu:
    depends_on:
      mysql:
        condition: service_healthy
    profiles:
      - cpu
  ...
  ragflow-gpu:
    depends_on:
      mysql:
        condition: service_healthy
    profiles:
      - gpu
```
This is after the change:
``` yaml
  ragflow-cpu:
    profiles:
      - cpu
  ...
  ragflow-gpu:
    profiles:
      - gpu
```

Next, edit the `docker-compose-base.yml` file in the `ragflow/docker` folder and remove the `mysql` and `redis` configuration.

For example, before deletion:
``` yaml
services:
  minio:
    image: quay.io/minio/minio:RELEASE.2025-06-13T11-33-47Z
    ...
  mysql:
    image: mysql:8.0
    ...
  redis:
    image: redis:6.2-alpine
    ...
```

After deletion
``` yaml
services:
  minio:
    image: quay.io/minio/minio:RELEASE.2025-06-13T11-33-47Z
    ...
```
## Step 4: Modify the Environment Variable Configuration

Edit the `.env` file in the `ragflow/docker` folder, find the following settings, and search for and modify them one by one! Search one by one, modify one by one!

For the `.env` changes below, 60% of people overlook the `MYSQL_USER` setting and ragflow then fails to start, so it must be emphasized three times:

Emphasis 1: if your `.env` file has no `MYSQL_USER` setting, add this item to the file!

Emphasis 2: if your `.env` file has no `MYSQL_USER` setting, add this item to the file!

Emphasis 3: if your `.env` file has no `MYSQL_USER` setting, add this item to the file!

``` env
# Port settings
SVR_WEB_HTTP_PORT=8008           # HTTP port
SVR_WEB_HTTPS_PORT=8009          # HTTPS port
# MySQL configuration - change to your local MySQL information
MYSQL_HOST=host.docker.internal  # Use host.docker.internal so the container can reach host services
MYSQL_PORT=3306                  # Local MySQL port
MYSQL_USER=rag_flow              # The username created above; add this item if it does not exist
MYSQL_PASSWORD=infini_rag_flow   # The password set above
MYSQL_DBNAME=rag_flow            # Database name

# Redis configuration - change to your local Redis information
REDIS_HOST=host.docker.internal  # Use host.docker.internal so the container can reach host services
REDIS_PORT=6379                  # Local Redis port
REDIS_PASSWORD=                  # If your Redis has no password, leave it like this; otherwise enter the password
```

Note that if your Redis has no password, you also need to edit `service_conf.yaml.template` in the `ragflow/docker` folder and replace `infini_rag_flow` with an empty string.

Before
``` shell
redis:
  db: 1
  password: '${REDIS_PASSWORD:-infini_rag_flow}'
  host: '${REDIS_HOST:-redis}:6379'
```
After
``` shell
redis:
  db: 1
  password: '${REDIS_PASSWORD:-}'
  host: '${REDIS_HOST:-redis}:6379'
```

## Step 5: Start the ragflow Service
Run the command:
``` shell
docker-compose -f docker-compose.yml up -d
```
After it succeeds, you can use the `docker logs -n 20 -f docker-ragflow-cpu-1` command to view the logs of the `docker-ragflow-cpu-1` service.

If there are no errors in the logs, the ragflow service started successfully.

# Step 5: Register an Account
You can visit `http://127.0.0.1:8008` in a browser, click `Sign Up`, and register an account.

After registering successfully, you can click `Sign In` to log in to the ragflow service. If you want to turn off registration for the ragflow service so that others cannot register accounts, set the `REGISTER_ENABLED` item to `0` in the `.env` file in the `ragflow/docker` folder.

``` dotenv
REGISTER_ENABLED=0
```
After the change, restart the ragflow service.
``` shell
docker-compose -f docker-compose.yml down
docker-compose -f docker-compose.yml up -d
```

# Step 6: Configure the Models of the ragflow Service
You can visit `http://127.0.0.1:8008` in a browser, click `Sign In`, and log in to the ragflow service. Click the `avatar` in the upper right corner of the page to go to the settings page.
First, click `Model Providers` in the left navigation bar to go to the model configuration page. Under the `Available Models` search box on the right, select `LLM`, choose the model provider you use from the list, click `Add`, and enter your key;
Then select `TEXT EMBEDDING`, choose the model provider you use from the list, click `Add`, and enter your key.
Finally, refresh the page, click LLM and Embedding in the `Set Default Models` list respectively, and select the models you use. Make sure your key has the corresponding services enabled. For example, my Embedding model is from provider xxx, so I need to go to that provider's website to check whether the model requires purchasing a resource package before it can be used.


# Part 2: Configure the ragflow Service

# Step 1: Log in to the ragflow Service
You can visit `http://127.0.0.1:8008` in a browser, click `Sign In`, and log in to the ragflow service.

Then click the `avatar` in the upper right corner to go to the settings page. In the left navigation bar, click the `API` feature, then click the "API Key" button. A dialog appears.

In the dialog, click the "Create new Key" button to generate an API Key. Copy this `API Key`; you will use it later.

# Step 2: Configure It in the Control Panel
Make sure your Control Panel version is `0.8.7` or above. Log in to the Control Panel with the super administrator account.

First, enable the knowledge base feature. In the top navigation bar, click `Parameter Dictionary`, and in the dropdown menu click the `System Feature Configuration` page. Check `Knowledge Base` on the page and click `Save Configuration`. You will then see the `Knowledge Base` feature in the navigation bar.

In the top navigation bar, click `Model Configuration`, and in the left navigation bar click `Knowledge Base`. Find `RAG_RAGFlow` in the list and click the `Edit` button.

In `Service Address`, enter `http://<LAN IP of your ragflow service>:8008`. For example, my ragflow service's LAN IP is `192.168.1.100`, so I enter `http://192.168.1.100:8008`.

In `API Key`, enter the `API Key` copied earlier.

Finally, click the Save button.

# Step 2: Create a Knowledge Base
Log in to the Control Panel with the super administrator account. In the top navigation bar, click `Knowledge Base`, and click the `Add` button at the lower left of the list. Enter a name and description for the knowledge base. Click Save.

To improve the LLM's understanding and recall of the knowledge base, it is recommended to enter a meaningful name and description when creating it. For example, if you create a knowledge base about a `company introduction`, the name can be `Company Introduction`, and the description can be `Information about the company, such as basic company information, services, contact phone numbers, addresses, etc.`.

After saving, you can see this knowledge base in the knowledge base list. Click the `View` button of the knowledge base you just created to enter the knowledge base details page.

On the knowledge base details page, click the `Add` button at the lower left to upload documents to the knowledge base.

After uploading, you can see the uploaded documents on the knowledge base details page. You can then click the `Parse` button of a document to parse it.

After parsing is complete, you can view the parsed chunk information. On the knowledge base details page, you can click the `Recall Test` button to test the knowledge base's recall/retrieval function.

# Step 3: Let Xiaozhi Use the ragflow Knowledge Base
Log in to the Control Panel. In the top navigation bar, click `Agents`, find the agent you want to configure, and click the `Configure Role` button.

To the left of Intent Recognition, click the `Edit Functions` button and a dialog pops up. Select the knowledge base you want to add in the dialog. Save and you are done.
