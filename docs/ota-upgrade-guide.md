# Firmware OTA Auto-Upgrade Configuration Guide for Single-Module Deployment

This tutorial guides you through configuring the firmware OTA auto-upgrade feature in a **single-module deployment** so that device firmware updates automatically.

If you already use the **full-module deployment**, ignore this tutorial.

## Feature Overview

In a single-module deployment, xiaozhi-server has built-in OTA firmware management that can detect device versions automatically and deliver upgrade firmware. Based on the device model and current version, the system automatically matches and pushes the latest firmware version.

## Prerequisites

- You have completed a **single-module deployment** and xiaozhi-server is running
- The device can connect to the server normally

## Step 1: Prepare the Firmware File

### 1. Create the Firmware Directory

Firmware files must be placed in the `data/bin/` directory. If the directory does not exist, create it manually:

```bash
mkdir -p data/bin
```

### 2. Firmware File Naming Rules

Firmware files must follow this naming format:

```
{device-model}_{version}.bin
```

**Naming rule details:**
- `device-model`: the model name of the device, for example `lichuang-dev`, `bread-compact-wifi`, etc.
- `version`: the firmware version number. It must start with a digit and may contain digits, letters, dots, underscores, and hyphens, for example `1.6.6`, `2.0.0`, etc.
- The file extension must be `.bin`

**Naming examples:**
```
bread-compact-wifi_1.6.6.bin
lichuang-dev_2.0.0.bin
```

### 3. Place the Firmware File

Copy the prepared firmware file (.bin file) into the `data/bin/` directory:

This is important, so it is said three times: the upgrade bin file is `xiaozhi.bin`, not the full firmware file `merged-binary.bin`!

This is important, so it is said three times: the upgrade bin file is `xiaozhi.bin`, not the full firmware file `merged-binary.bin`!

This is important, so it is said three times: the upgrade bin file is `xiaozhi.bin`, not the full firmware file `merged-binary.bin`!

```bash
cp xiaozhi.bin data/bin/device-model_version.bin
```

For example:
```bash
cp xiaozhi.bin data/bin/bread-compact-wifi_1.6.6.bin
```

## Step 2: Configure the Public Access Address (Required Only for Public Deployments)

**Note: This step applies only to single-module public network deployments.**

If your xiaozhi-server is deployed on a public network (using a public IP or domain name), you **must** configure the `server.vision_explain` parameter, because the OTA firmware download address uses the domain name and port from this setting.

If you deploy on a LAN, you can skip this step.

### Why Configure This Parameter?

In a single-module deployment, when the system generates the firmware download address, it uses the domain name and port configured in `vision_explain` as the base address. If it is not configured or is configured incorrectly, the device cannot reach the firmware download address.

### Configuration Method

Open the `data/.config.yaml` file, find the `server` section, and set the `vision_explain` parameter:

```yaml
server:
  vision_explain: http://your-domain-or-IP:port/mcp/vision/explain
```

**Configuration examples:**

LAN deployment (default):
```yaml
server:
  vision_explain: http://192.168.1.100:8003/mcp/vision/explain
```

Public domain name deployment:
```yaml
server:
  vision_explain: http://yourdomain.com:8003/mcp/vision/explain
```

### Notes

- The domain name or IP must be an address the device can reach
- If you deploy with Docker, do not use Docker-internal addresses (such as 127.0.0.1 or localhost)
- If you use an nginx reverse proxy, enter the external address and port number, not the port this project runs on


## FAQ

### 1. The Device Does Not Receive Firmware Updates

**Possible causes and solutions:**

- Check that the firmware file name follows the rule: `{model}_{version}.bin`
- Check that the firmware file is placed in the `data/bin/` directory
- Check that the device model matches the model in the firmware file name
- Check that the firmware version is higher than the device's current version
- Check the server logs to confirm that OTA requests are handled normally

### 2. The Device Reports That the Download Address Is Unreachable

**Possible causes and solutions:**

- Check that the domain name or IP configured in `server.vision_explain` is correct
- Confirm that the port number is configured correctly (default 8003)
- For a public deployment, make sure the device can reach that public address
- For a Docker deployment, make sure an internal address (127.0.0.1) is not used
- Check that the firewall allows the corresponding port
- If you use an nginx reverse proxy, enter the external address and port number, not the port this project runs on

### 3. How to Confirm the Device's Current Version

Check the OTA request logs, which show the version reported by the device:

```
[ota_handler] - Device AA:BB:CC:DD:EE:FF firmware is already up to date: 1.6.6
```

### 4. The Firmware File Does Not Take Effect After Being Placed

The system has a 30-second cache time (default). You can:
- Wait 30 seconds before having the device send an OTA request
- Restart the xiaozhi-server service
- Set `firmware_cache_ttl` to a shorter time
