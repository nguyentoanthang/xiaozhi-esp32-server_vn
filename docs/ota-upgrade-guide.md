# Firmware OTA Auto-Upgrade Configuration Guide

This tutorial guides you through configuring the firmware OTA auto-upgrade feature of the built-in OTA endpoint so that device firmware updates automatically.

## Feature Overview

xiaozhi-server has built-in OTA firmware management that can detect device versions automatically and deliver upgrade firmware. Based on the device model and current version, the system automatically matches and pushes the latest firmware version.

## Prerequisites

- xiaozhi-server is running
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

## Step 2: Configure the Download Address (Only if the Default Is Wrong)

By default the firmware download link is `http://<server LAN ip>:<http_port>/xiaozhi/ota/download/<file>`. On a plain LAN
you can skip this step. Behind Docker NAT, a domain name or a reverse proxy the automatic address is wrong, so set the
base URL in the `setting` table (the value is JSON, so the string keeps its quotes):

```bash
sqlite3 data/xiaozhi.db "INSERT OR REPLACE INTO setting(key, value, note) VALUES ('server.http_base_url', '\"http://192.168.1.100:8003\"', 'OTA firmware base URL');"
```

Restart the server afterwards. Use only the scheme, host and port: the path `/xiaozhi/ota/download/<file>` is added by the server.

### Notes

- The domain name or IP must be an address the device can reach
- If you deploy with Docker, do not use Docker-internal addresses (such as 127.0.0.1 or localhost)
- If you use a reverse proxy, enter the external address and port number, not the port this project runs on


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

- Check that the domain name or IP configured in `server.http_base_url` is correct
- Confirm that the port number is configured correctly (default 8003)
- For a public deployment, make sure the device can reach that public address
- For a Docker deployment, make sure an internal address (127.0.0.1) is not used
- Check that the firewall allows the corresponding port
- If you use a reverse proxy, enter the external address and port number, not the port this project runs on

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
