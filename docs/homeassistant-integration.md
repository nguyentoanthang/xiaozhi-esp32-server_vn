# Xiaozhi ESP32 Open-Source Server and HomeAssistant Integration Guide

[TOC]

-----

## Introduction

This document guides you through integrating ESP32 devices with HomeAssistant.

## Prerequisites

- `HomeAssistant` is installed and configured
- The model I chose this time is the free ChatGLM, which supports function calling

## Required Preparation

### 1. Get the network address of HA

Visit your Home Assistant's network address. For example, my HA address is 192.168.4.7 and the port is the default 8123, so I open the following in a browser

```
http://192.168.4.7:8123
```

> How to look up the HA IP address manually **(only when the Xiaozhi esp32-server and HA are deployed on the same network [e.g. the same Wi-Fi])**:
>
> 1. Open Home Assistant (the frontend).
>
> 2. Click **Settings** in the lower left -> **System** -> **Network**.
>
> 3. Scroll to the bottom to the `Home Assistant website` section. Under `local network`, click the `eye` button to see the IP address currently in use (such as `192.168.1.10`) and the network interface. Click `copy link` to copy it directly.
>
>    ![image-20250504051716417](images/image-ha-integration-01.png)

Or, if you have already set up a directly accessible Home Assistant OAuth address, you can also open it directly in a browser

```
http://homeassistant.local:8123
```

### 2. Log in to `Home Assistant` to get the development key

Log in to `HomeAssistant`, click `your avatar in the lower left -> Profile`, switch to the `Security` tab, scroll to the bottom `Long-lived access tokens` and generate an api_key. Copy and save it; all the following methods need this api key, and it is shown only once (tip: you can save the generated QR code image and scan it later to retrieve the api key again).

## Method 1: HA Calling Feature Built by the Xiaozhi Community

### Feature Description

- If you add new devices later, this method requires manually restarting the `xiaozhi-esp32-server server` to update the device information **(important)**.

- You need to make sure `Xiaomi Home` is integrated in HomeAssistant and your Mijia devices have been imported into `HomeAssistant`.

- You need to make sure `xiaozhi-server` runs normally.


### Configuration Steps

#### 1. Log in to `HomeAssistant` and compile the list of devices to control

Log in to `HomeAssistant`, click `Settings` in the lower left, go to `Devices & Services`, and then click `Entities` at the top.

Then search the entities for the switch you want to control. When the results appear, click one of them in the list, and a switch panel will appear.

On the switch panel, try clicking the switch to see whether it turns on/off as you click. If it works, the device is connected to the network normally.

Next, find the settings button on the switch panel and click it to see the switch's `entity ID`.

Open a notepad and compile an entry in this format:

location + English comma + device name + English comma + `entity ID` + English semicolon

For example, I am at the office and have a toy lamp whose identifier is switch.cuco_cn_460494544_cp1_on_p_2_1, so I write this entry

```
Office,Toy lamp,switch.cuco_cn_460494544_cp1_on_p_2_1;
```

Of course, I may end up controlling two lamps, so my final result is:

```
Office,Toy lamp,switch.cuco_cn_460494544_cp1_on_p_2_1;
Office,Desk lamp,switch.iot_cn_831898993_socn1_on_p_2_1;
```

We call this string the "device list string". Keep it safe, because we will need it shortly.

#### 2. Configure the plugin in the database

The plugin parameters are stored in the `setting` row `plugins.home_assistant` (JSON): your `HomeAssistant` address, the long-lived access token, and the "device list string" from step 1 (the value of `devices` is that one string):

```bash
sqlite3 data/xiaozhi.db "UPDATE setting SET value = json('{\"base_url\": \"http://192.168.4.7:8123\", \"api_key\": \"your HomeAssistant token\", \"devices\": \"Office,Toy lamp,switch.cuco_cn_460494544_cp1_on_p_2_1;Office,Desk lamp,switch.iot_cn_831898993_socn1_on_p_2_1;\"}') WHERE key = 'plugins.home_assistant';"
```

Plugins are switched off by default. Enable them and list the two Home Assistant functions in the `functions` of the `function_call` intent model (see [weather-integration.md](./weather-integration.md) for the commands; the function names are `hass_get_state` and `hass_set_state`), then restart the server. After it is saved successfully, you can wake the device and operate it.

#### 3. Wake the device to control it

Try saying to the esp32, "Turn on the XXX light"

## Method 2: Xiaozhi Uses the Home Assistant Voice Assistant as an LLM Tool

### Feature Description

- This method has a rather serious drawback: **it cannot use the function_call plugin capabilities of the Xiaozhi open-source ecosystem**, because using Home Assistant as Xiaozhi's LLM tool hands the intent recognition over to Home Assistant. However, **this method lets you experience the native Home Assistant operation features, and Xiaozhi's chat ability is unchanged**. If you really mind, you can use [Method 3](#method-3-use-the-home-assistant-mcp-service-recommended), which is also supported by Home Assistant and lets you experience the Home Assistant features to the fullest.

### Configuration Steps:

#### 1. Configure the Home Assistant LLM voice assistant.

**You need to configure the Home Assistant voice assistant or LLM tool beforehand.**

#### 2. Get the Agent ID of the Home Assistant voice assistant.

1. Open the Home Assistant page. Click `Developer Tools` on the left.
2. In the opened `Developer Tools`, click the `Actions` tab (operation 1 in the figure). In the `Actions` dropdown on the page, find or enter `conversation.process (Conversation: Process)` and select `Conversation: Process` (operation 2 in the figure).

![image-20250504043539343](images/image-ha-integration-02.png)

3. Check the `agent` option on the page, then in the `conversation agent` field that becomes active, select the name of the voice assistant you configured in step 1. As shown in the figure, mine is `ZhipuAi`, which I selected.

![image-20250504043854760](images/image-ha-integration-03.png)

4. After selecting it, click `Switch to YAML mode` at the lower left of the form.

![image-20250504043951126](images/image-ha-integration-04.png)

5. Copy the value of agent-id. For example, mine in the figure is `01JP2DYMBDF7F4ZA2DMCF2AGX2` (for reference only).

![image-20250504044046466](images/image-ha-integration-05.png)

6. Switch to the `config.yaml` file of the Xiaozhi open-source server `xiaozhi-esp32-server`, find Home Assistant in the LLM configuration, and set your Home Assistant network address, Api key, and the agent_id you just looked up.
7. In the `config.yaml` file, change `LLM` under the `selected_module` property to `HomeAssistant` and `Intent` to `nointent`.
8. Restart the Xiaozhi open-source server `xiaozhi-esp32-server` and it is ready to use.

## Method 3: Use the Home Assistant MCP Service (Recommended)

### Feature Description

- You need to integrate and install the HA integration [Model Context Protocol Server](https://www.home-assistant.io/integrations/mcp_server/) in Home Assistant beforehand.

- This method and Method 2 are both solutions provided officially by HA. Unlike Method 2, you can use the community-built plugins of the Xiaozhi open-source server `xiaozhi-esp32-server` as usual, and you are free to use any LLM that supports function_call.

### Configuration Steps

#### 1. Install the Home Assistant MCP service integration.

Official integration page: [Model Context Protocol Server](https://www.home-assistant.io/integrations/mcp_server/).

Or follow the manual steps below.

> - Go to **[Settings > Devices & Services](https://my.home-assistant.io/redirect/integrations)** in Home Assistant.
>
> - In the lower right corner, select the **[Add Integration](https://my.home-assistant.io/redirect/config_flow_start?domain=mcp_server)** button.
>
> - Select **Model Context Protocol Server** from the list.
>
> - Follow the on-screen instructions to complete the setup.

#### 2. Configure the MCP settings of the Xiaozhi open-source server


Go to the `data` directory and find the `.mcp_server_settings.json` file.

If there is no `.mcp_server_settings.json` file in your `data` directory,
- copy the `mcp_server_settings.json` file from the root of the `xiaozhi-server` folder to the `data` directory and rename it to `.mcp_server_settings.json`
- or [download this file](https://github.com/xinnan-tech/xiaozhi-esp32-server/blob/main/main/xiaozhi-server/mcp_server_settings.json) into the `data` directory and rename it to `.mcp_server_settings.json`


Modify this part inside `"mcpServers"`:

```json
"Home Assistant": {
      "command": "mcp-proxy",
      "args": [
        "http://YOUR_HA_HOST/mcp_server/sse"
      ],
      "env": {
        "API_ACCESS_TOKEN": "YOUR_API_ACCESS_TOKEN"
      }
},
```

Note:

1. **Replace the configuration:**
   - Replace `YOUR_HA_HOST` in `args` with your HA service address. If your service address already includes https/http (for example `http://192.168.1.101:8123`), just enter `192.168.1.101:8123`.
   - Replace `YOUR_API_ACCESS_TOKEN` of `API_ACCESS_TOKEN` in `env` with the development key (api key) you obtained earlier.
2. **If you add the configuration inside the `"mcpServers"` braces and no other `mcpServers` entries follow, remove the trailing comma `,`**, otherwise parsing may fail.

**The final result looks like the following (for reference)**:

```json
 "mcpServers": {
    "Home Assistant": {
      "command": "mcp-proxy",
      "args": [
        "http://192.168.1.101:8123/mcp_server/sse"
      ],
      "env": {
        "API_ACCESS_TOKEN": "abcd.efghi.jkl"
      }
    }
  }
```

#### 3. Configure the system settings of the Xiaozhi open-source server

1. **Choose any LLM that supports function_call as Xiaozhi's LLM chat assistant (but do not choose Home Assistant as the LLM tool)**. The model I chose this time is the free ChatGLM, which supports function calling but is sometimes unstable. If you want stability, set the LLM to DoubaoLLM, with model_name doubao-1-5-pro-32k-250115.

2. Switch to the `config.yaml` file of the Xiaozhi open-source server `xiaozhi-esp32-server`, set your LLM configuration, and change `Intent` in `selected_module` to `function_call`.

3. Restart the Xiaozhi open-source server `xiaozhi-esp32-server` and it is ready to use.