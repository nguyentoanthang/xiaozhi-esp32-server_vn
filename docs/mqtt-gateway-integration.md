# MQTT Gateway Deployment Guide

The `xiaozhi-esp32-server` project can be combined with the [xiaozhi-mqtt-gateway](https://github.com/78/xiaozhi-mqtt-gateway) project open-sourced by Brother Xia, with simple modifications, to enable MQTT+UDP connections for Xiaozhi hardware.
This tutorial has three parts. Depending on whether you use the full-module or single-module deployment, choose the corresponding part to connect the MQTT gateway:
- Part 1: Deploy the MQTT gateway
- Part 2: Full-module deployment, enabling MQTT+UDP connections for Xiaozhi hardware
- Part 3: Single-module xiaozhi-server deployment, enabling MQTT+UDP connections for Xiaozhi hardware

## Preparation
Prepare the `mqtt-websocket` connection address of your `xiaozhi-server`. Add the characters `?from=mqtt_gateway` to your original `websocket address` to get the `mqtt-websocket` connection address

1. If you deploy from source, your `mqtt-websocket` address is:
```
ws://127.0.0.1:8000/xiaozhi/v1/?from=mqtt_gateway
```

2. If you deploy with docker, your `mqtt-websocket` address is
```
ws://your-host-LAN-IP:8000/xiaozhi/v1/?from=mqtt_gateway
```

## Important Notice

If you deploy on a server, make sure ports `1883`, `8884`, and `8007` are all open to the outside. Choose the `UDP` protocol type for `8884`, and `TCP` for the others.

If you deploy on a server, make sure ports `1883`, `8884`, and `8007` are all open to the outside. Choose the `UDP` protocol type for `8884`, and `TCP` for the others.

If you deploy on a server, make sure ports `1883`, `8884`, and `8007` are all open to the outside. Choose the `UDP` protocol type for `8884`, and `TCP` for the others.


## Part 1: Deploy the MQTT Gateway

1. Clone the [modified xiaozhi-mqtt-gateway project](https://github.com/xinnan-tech/xiaozhi-mqtt-gateway.git):
```bash
git clone https://ghfast.top/https://github.com/xinnan-tech/xiaozhi-mqtt-gateway.git
cd xiaozhi-mqtt-gateway
```

2. Install dependencies:
```bash
npm install
npm install -g pm2
```

3. Configure `config.json`:
```bash
cp config/mqtt.json.example config/mqtt.json
```

4. Edit the configuration file config/mqtt.json and replace the `chat_servers` entries with the `mqtt-websocket` address from the `preparation section of this document`. For example, a source-deployed `xiaozhi-server` is configured as follows:

``` 
{
    "production": {
        "chat_servers": [
            "ws://127.0.0.1:8000/xiaozhi/v1/?from=mqtt_gateway"
        ]
    },
    "debug": false,
    "max_mqtt_payload_size": 8192,
    "mcp_client": {
        "capabilities": {
        },
        "client_info": {
            "name": "xiaozhi-mqtt-client",
            "version": "1.0.0"
        },
        "max_tools_count": 128
    }
}
```
5. Create a `.env` file in the project root directory and set the following environment variables:
```
PUBLIC_IP=your-ip         # Server public IP
MQTT_PORT=1883            # MQTT server port
UDP_PORT=8884             # UDP server port
API_PORT=8007             # Management API port
MQTT_SIGNATURE_KEY=test   # MQTT signature key
SERVER_SECRET=Te1st12134  # Server secret. Keep it consistent with the Control Panel (server.secret) or with xiaozhi-server (server.auth_key)
```
Note the `PUBLIC_IP` setting: make sure it matches the actual public IP, or use the domain name if you have one.

`MQTT_SIGNATURE_KEY` is the key used for MQTT connection authentication. It is best to make it fairly complex, ideally at least 8 characters containing both upper- and lowercase letters. This key will be used again later.

- Do not use a simple password such as `123456` or `test`.
- Do not use a simple password such as `123456` or `test`.
- Do not use a simple password such as `123456` or `test`.

`SERVER_SECRET` is used to generate the authentication information for websocket connections.

1. If you use the full-module deployment and `server.auth.enabled` is set to `true` in the Control Panel's Parameter Management, then `SERVER_SECRET` must match the Control Panel (`server.secret`).

2. If you use the single-module deployment and set `server.auth.enabled` to `true` in the configuration file, then `SERVER_SECRET` must match the configuration file (`server.auth_key`).


6. Start the MQTT gateway
```
# Start the service
pm2 start ecosystem.config.js

# View the logs
pm2 logs xz-mqtt
```

When you see the following logs, the MQTT gateway has started successfully:
```
0|xz-mqtt  | 2025-09-11T12:14:48: MQTT server is listening on port 1883
0|xz-mqtt  | 2025-09-11T12:14:48: UDP server is listening on x.x.x.x:8884
```

To restart the MQTT gateway, run the following command:
```
pm2 restart xz-mqtt
```

## Part 2: Full-Module Deployment, Enabling MQTT+UDP Connections for Xiaozhi Hardware

Check the version number at the bottom of your Control Panel home page to confirm that it is `0.7.7` or above. If not, upgrade the Control Panel.

1. At the top of the Control Panel, click `Parameter Management`, search for `server.mqtt_gateway`, click Edit, and enter `PUBLIC_IP`+`:`+`MQTT_PORT` as set in the `.env` file. Like this
```
192.168.0.7:1883
```
2. At the top of the Control Panel, click `Parameter Management`, search for `server.mqtt_signature_key`, click Edit, and enter the `MQTT_SIGNATURE_KEY` set in the `.env` file.

3. At the top of the Control Panel, click `Parameter Management`, search for `server.udp_gateway`, click Edit, and enter `PUBLIC_IP`+`:`+`UDP_PORT` as set in the `.env` file. Like this
```
192.168.0.7:8884
```
4. At the top of the Control Panel, click `Parameter Management`, search for `server.mqtt_manager_api`, click Edit, and enter `PUBLIC_IP`+`:`+`API_PORT` as set in the `.env` file. Like this
```
192.168.0.7:8007
```

After the configuration above is done, you can use a curl command to verify whether your OTA address delivers the mqtt configuration. Change `http://localhost:8002/xiaozhi/ota/` below to your OTA address
```
curl 'http://localhost:8002/xiaozhi/ota/' \
  -H 'Content-Type: application/json' \
  -H 'Client-Id: 7b94d69a-9808-4c59-9c9b-704333b38aff' \
  -H 'Device-Id: 11:22:33:44:55:66' \
  --data-raw $'{\n  "application": {\n    "version": "1.0.1",\n    "elf_sha256": "1"\n  },\n  "board": {\n    "mac": "11:22:33:44:55:66"\n  }\n}'
```

If the returned content contains `mqtt`-related configuration, the configuration succeeded. Like this

```
{"server_time":{"timestamp":1757567894012,"timeZone":"Asia/Shanghai","timezone_offset":480},"activation":{"code":"460609","message":"http://xiaozhi.server.com\n460609","challenge":"11:22:33:44:55:66"},"firmware":{"version":"1.0.1","url":"http://xiaozhi.server.com:8002/xiaozhi/otaMag/download/NOT_ACTIVATED_FIRMWARE_THIS_IS_A_INVALID_URL"},"websocket":{"url":"ws://192.168.4.23:8000/xiaozhi/v1/"},"mqtt":{"endpoint":"192.168.0.7:1883","client_id":"GID_default@@@11_22_33_44_55_66@@@7b94d69a-9808-4c59-9c9b-704333b38aff","username":"eyJpcCI6IjA6MDowOjA6MDowOjA6MSJ9","password":"Y8XP9xcUhVIN9OmbCHT9ETBiYNE3l3Z07Wk46wV9PE8=","publish_topic":"device-server","subscribe_topic":"devices/p2p/11_22_33_44_55_66"}}
```

Because the MQTT information is delivered through the OTA address, as long as you make sure the device can connect to the server's OTA address normally, just restart and wake it.

After waking it, watch the mqtt-gateway logs to confirm there is a log showing a successful connection.
```
pm2 logs xz-mqtt
```

## Part 3: Single-Module xiaozhi-server Deployment, Enabling MQTT+UDP Connections for Xiaozhi Hardware

Open your `data/.config.yaml` file, find `mqtt_gateway` under `server`, and enter `PUBLIC_IP`+`:`+`MQTT_PORT` as set in the `.env` file. Like this
```
192.168.0.7:1883
```
Find `mqtt_signature_key` under `server` and enter the `MQTT_SIGNATURE_KEY` set in the `.env` file.

Find `udp_gateway` under `server` and enter `PUBLIC_IP`+`:`+`UDP_PORT` as set in the `.env` file. Like this
```
192.168.0.7:8884
```

After the configuration above is done, you can use a curl command to verify whether your OTA address delivers the mqtt configuration. Change `http://localhost:8002/xiaozhi/ota/` below to your OTA address
```
curl 'http://localhost:8002/xiaozhi/ota/' \
  -H 'Device-Id: 11:22:33:44:55:66' \
  --data-raw $'{\n  "application": {\n    "version": "1.0.1",\n    "elf_sha256": "1"\n  },\n  "board": {\n    "mac": "11:22:33:44:55:66"\n  }\n}'
```

If the returned content contains `mqtt`-related configuration, the configuration succeeded. Like this
```
{"server_time":{"timestamp":1758781561083,"timeZone":"GMT+08:00","timezone_offset":480},"activation":{"code":"527111","message":"http://xiaozhi.server.com\n527111","challenge":"11:22:33:44:55:66"},"firmware":{"version":"1.0.1","url":"http://xiaozhi.server.com:8002/xiaozhi/otaMag/download/NOT_ACTIVATED_FIRMWARE_THIS_IS_A_INVALID_URL"},"websocket":{"url":"ws://192.168.1.15:8000/xiaozhi/v1/"},"mqtt":{"endpoint":"192.168.1.15:1883","client_id":"GID_default@@@11_22_33_44_55_66@@@11_22_33_44_55_66","username":"eyJpcCI6IjE5Mi4xNjguMS4xNSJ9","password":"fjAYs49zTJecWqJ3jBt+kqxVn/x7vkXRAc85ak/va7Y=","publish_topic":"device-server","subscribe_topic":"devices/p2p/11_22_33_44_55_66"}}
```

Because the MQTT information is delivered through the OTA address, as long as you make sure the device can connect to the server's OTA address normally, just restart and wake it.

After waking it, watch the mqtt-gateway logs to confirm there is a log showing a successful connection.
```
pm2 logs xz-mqtt
```
