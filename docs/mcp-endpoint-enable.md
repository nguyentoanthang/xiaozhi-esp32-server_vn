# MCP Endpoint Deployment and Usage Guide

This tutorial has 3 parts
- 1. How to deploy the MCP endpoint service
- 2. How to configure the MCP endpoint in a full-module deployment
- 3. How to configure the MCP endpoint in a single-module deployment

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
250705 INFO-=====The addresses below are the Control Panel / single-module MCP endpoint addresses====
250705 INFO-Control Panel MCP parameter configuration: http://172.22.0.2:8004/mcp_endpoint/health?key=abc
250705 INFO-Single-module deployment MCP endpoint: ws://172.22.0.2:8004/mcp_endpoint/mcp/?token=def
250705 INFO-=====Choose according to your deployment. Do not disclose them to anyone======
```

Copy the two API addresses:

Because you deployed with docker, do NOT use the addresses above directly!

Because you deployed with docker, do NOT use the addresses above directly!

Because you deployed with docker, do NOT use the addresses above directly!

First copy the addresses into a scratch file. You need to know your computer's LAN IP. For example, my computer's LAN IP is `192.168.1.25`, so
my original API addresses
```
Control Panel MCP parameter configuration: http://172.22.0.2:8004/mcp_endpoint/health?key=abc
Single-module deployment MCP endpoint: ws://172.22.0.2:8004/mcp_endpoint/mcp/?token=def
```
need to be changed to
```
Control Panel MCP parameter configuration: http://192.168.1.25:8004/mcp_endpoint/health?key=abc
Single-module deployment MCP endpoint: ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=def
```

After changing them, use a browser to directly visit the `Control Panel MCP parameter configuration` address. If the browser shows code like the following, it worked.
```
{"result":{"status":"success","connections":{"tool_connections":0,"robot_connections":0,"total_connections":0}},"error":null,"id":null,"jsonrpc":"2.0"}
```

Keep the two `API addresses` above, because you will need them in the next step.

# 2. How to Configure the MCP Endpoint in a Full-Module Deployment
First, enable the MCP endpoint feature. In the Control Panel, click `Parameter Dictionary` at the top, and in the dropdown menu click the `System Feature Configuration` page. Check `MCP Endpoint` on the page and click `Save Configuration`. On the `Role Configuration` page, click the `Edit Functions` button to see the `MCP endpoint` feature.

If you use the full-module deployment, log in to the Control Panel with the administrator account, click `Parameter Dictionary` at the top, and choose `Parameter Management`.

Then search for the parameter `server.mcp_endpoint`. Its value should be `null` at this point.
Click the Edit button, paste the `Control Panel MCP parameter configuration` obtained in the previous step into `Parameter Value`, and then save.

If it saves successfully, everything went well and you can go to the agent to see the result. If not, the Control Panel cannot reach the MCP endpoint, most likely because of a network firewall or an incorrect LAN IP.

# 3. How to Configure the MCP Endpoint in a Single-Module Deployment

If you use the single-module deployment, find your configuration file `data/.config.yaml`.
Search the configuration file for `mcp_endpoint`. If it is not found, add the `mcp_endpoint` setting. Mine looks like this
```
server:
  websocket: ws://your-ip-or-domain:port/xiaozhi/v1/
  http_port: 8002
log:
  log_level: INFO

# There may be more configuration here..

mcp_endpoint: your endpoint websocket address
```
Now paste the `single-module deployment MCP endpoint` obtained in `How to deploy the MCP endpoint service` into `mcp_endpoint`. Like this

```
server:
  websocket: ws://your-ip-or-domain:port/xiaozhi/v1/
  http_port: 8002
log:
  log_level: INFO

# There may be more configuration here

mcp_endpoint: ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=def
```

After configuring, starting the single module prints logs like the following.
```
250705[__main__]-INFO-Component initialized: vad ok SileroVAD
250705[__main__]-INFO-Component initialized: asr ok FunASRServer
250705[__main__]-INFO-OTA endpoint is        http://192.168.1.25:8002/xiaozhi/ota/
250705[__main__]-INFO-Vision analysis endpoint is  http://192.168.1.25:8002/mcp/vision/explain
250705[__main__]-INFO-MCP endpoint is  ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=abc
250705[__main__]-INFO-Websocket address is ws://192.168.1.25:8000/xiaozhi/v1/
250705[__main__]-INFO-=======The address above is a websocket protocol address; do not open it in a browser=======
250705[__main__]-INFO-To test websocket, start the digital-human module and use the browser for interactive testing
250705[__main__]-INFO-=============================================================
```

As above, if it prints something like `MCP endpoint is` followed by `ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=abc`, the configuration succeeded.

