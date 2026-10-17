# MCP Endpoint Usage Guide

This tutorial uses the mcp calculator feature open-sourced by Brother Xia as an example to show how to connect your own custom mcp service to your own endpoint.

The prerequisite of this tutorial is that your `xiaozhi-server` already has the mcp endpoint feature enabled. If you have not enabled it yet, first enable it by following [this tutorial](./mcp-endpoint-enable.md).

# How to Connect a Simple mcp Feature, Such as a Calculator, to an Agent

Your `MCP endpoint address` is the value of `agent.mcp_endpoint` for your agent (`sqlite3 data/xiaozhi.db "SELECT id, mcp_endpoint FROM agent;"`).
When the server starts it also prints it, for example
```
250705[__main__]-INFO-MCP endpoint is  ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=abc
```

This `MCP endpoint address` is important; you will use it shortly.

## Step 1: Download Brother Xia's MCP Calculator Project Code

Open the [calculator project](https://github.com/78/mcp-calculator) written by Brother Xia in a browser,

After it opens, find the green button labeled `Code` on the page, click it, and you will see the `Download ZIP` button.

Click it to download the project source archive. After it is downloaded to your computer, extract it. At this point its name may be `mcp-calculator-main`.
You need to rename it to `mcp-calculator`. Next, we use the command line to enter the project directory and install the dependencies


```bash
# Go to the project directory
cd mcp-calculator

conda remove -n mcp-calculator --all -y
conda create -n mcp-calculator python=3.10 -y
conda activate mcp-calculator

pip install -r requirements.txt
```

## Step 2: Start

Before starting, first copy the MCP endpoint address of your agent (see above).

For example, my agent's mcp address is
```
ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=abc
```

Start entering the commands

```bash
export MCP_ENDPOINT=ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=abc
```

After entering them, start the program

```bash
python mcp_pipe.py calculator.py
```

### Check the Result
After a device connects, similar logs are printed, which means it succeeded

```
250705 -INFO-Initializing MCP endpoint: wss://2662r3426b.vicp.fun/mcp_e 
250705 -INFO-Send MCP endpoint initialization message
250705 -INFO-MCP endpoint connected successfully
250705 -INFO-MCP endpoint initialized successfully
250705 -INFO-Unified tool handler initialized
250705 -INFO-MCP endpoint server info: name=Calculator, version=1.9.4
250705 -INFO-Number of tools supported by the MCP endpoint: 1
250705 -INFO-All MCP endpoint tools retrieved; client is ready
250705 -INFO-Tool cache refreshed
250705 -INFO-Currently supported function list: [ 'get_time', 'get_lunar', 'play_music', 'get_weather', 'handle_exit_intent', 'calculator']
```
If `'calculator'` is included, the device will be able to call the calculator tool based on intent recognition.