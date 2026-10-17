# MCP Endpoint Deployment and Usage Guide

This tutorial has 2 parts
- 1. How to deploy the MCP endpoint service
- 2. How to configure the MCP endpoint in xiaozhi-server

# 1. How to Deploy the MCP Endpoint Service

## Step 1: Download the MCP endpoint project source code

Open the [MCP endpoint project](https://github.com/xinnan-tech/mcp-endpoint-server) in a browser

After it opens, find the green button labeled `Code` on the page, click it, and you will see the `Download ZIP` button.

Click it to download the project source archive. After it is downloaded to your computer, extract it. At this point its name may be `mcp-endpoint-server-main`.
You need to rename it to `mcp-endpoint-server`.

## Step 2: Start the Program
This is a very simple project, and running it with docker is recommended. If you do not want to use docker, you can run it from source by following [this page](https://github.com/xinnan-tech/mcp-endpoint-server/blob/main/README_dev.md). The following is the docker method

```
# Go to the root directory of this project's source code
cd mcp-endpoint-server

# Clear the cache
docker compose -f docker-compose.yml down
docker stop mcp-endpoint-server
docker rm mcp-endpoint-server
docker rmi ghcr.nju.edu.cn/xinnan-tech/mcp-endpoint-server:latest

# Start the docker container
docker compose -f docker-compose.yml up -d
# View the logs
docker logs -f mcp-endpoint-server
```

At this point, logs similar to the following are printed
```
250705 INFO-=====The addresses below are the MCP endpoint addresses====
250705 INFO-MCP health check: http://172.22.0.2:8004/mcp_endpoint/health?key=abc
250705 INFO-MCP endpoint: ws://172.22.0.2:8004/mcp_endpoint/mcp/?token=def
250705 INFO-=====Choose according to your deployment. Do not disclose them to anyone======
```

Copy the two API addresses:

Because you deployed with docker, do NOT use the addresses above directly!

Because you deployed with docker, do NOT use the addresses above directly!

Because you deployed with docker, do NOT use the addresses above directly!

First copy the addresses into a scratch file. You need to know your computer's LAN IP. For example, my computer's LAN IP is `192.168.1.25`, so
my original API addresses
```
MCP health check: http://172.22.0.2:8004/mcp_endpoint/health?key=abc
MCP endpoint: ws://172.22.0.2:8004/mcp_endpoint/mcp/?token=def
```
need to be changed to
```
MCP health check: http://192.168.1.25:8004/mcp_endpoint/health?key=abc
MCP endpoint: ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=def
```

After changing them, use a browser to directly visit the `MCP health check` address. If the browser shows code like the following, it worked.
```
{"result":{"status":"success","connections":{"tool_connections":0,"robot_connections":0,"total_connections":0}},"error":null,"id":null,"jsonrpc":"2.0"}
```

Keep the two `API addresses` above, because you will need them in the next step.

# 2. How to Configure the MCP Endpoint in xiaozhi-server

The MCP endpoint address is stored per agent in the SQLite database (`agent.mcp_endpoint`). Put the `MCP endpoint` address from the previous step into the agent that your device uses (the default agent is `default`):

```bash
sqlite3 data/xiaozhi.db "UPDATE agent SET mcp_endpoint = 'ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=def' WHERE id = 'default';"
```

The change applies to the next device connection; restart the server if you want the startup log to print it. When the server starts it prints logs like the following.
```
250705[__main__]-INFO-Component initialized: vad ok SileroVAD
250705[__main__]-INFO-OTA endpoint is        http://192.168.1.25:8003/xiaozhi/ota/
250705[__main__]-INFO-MCP endpoint is  ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=abc
250705[__main__]-INFO-Websocket address is ws://192.168.1.25:8000/xiaozhi/v1/
```

As above, if it prints something like `MCP endpoint is` followed by `ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=abc`, the configuration succeeded.
