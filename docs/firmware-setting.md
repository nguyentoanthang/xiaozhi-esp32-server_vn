# Configure a Custom Server Based on the Firmware Built by Brother Xia

## Step 1: Confirm the Version
Flash the firmware already built by Brother Xia, [version 1.6.1 or above](https://github.com/78/xiaozhi-esp32/releases)

## Step 2: Prepare Your OTA Address
Your OTA address is `http://<server ip>:8003/xiaozhi/ota/` (it is printed in the server's startup log).

Now open your OTA address in a browser. For example, my OTA address is
```
http://192.168.1.25:8003/xiaozhi/ota/
```

If it shows "OTA interface is running normally, the websocket address sent to devices is: ws://xxx:8000/xiaozhi/v1/", continue.

If the websocket address shown is wrong (Docker, domain name, several network cards), set it in the database and restart the server:

```bash
sqlite3 data/xiaozhi.db "UPDATE setting SET value = '\"ws://192.168.1.25:8000/xiaozhi/v1/\"' WHERE key = 'server.websocket';"
```

Then refresh the OTA address in the browser. If it is still not normal, double-check whether the Websocket service started properly and whether the port is open.

## Step 3: Enter Network Configuration Mode
Put the device into network configuration mode, click "Advanced Options" at the top of the page, enter your server's `ota` address there, and click Save. Then restart the device
![See: OTA address settings](../docs/images/firmware-setting-ota.png)

## Step 4: Wake Xiaozhi and Check the Log Output

Wake Xiaozhi and check whether the logs are output normally.


## FAQ
Here are some common questions for reference:

[1. Why does Xiaozhi recognize a lot of Korean, Japanese, and English from what I say](./FAQ.md)

[2. Why does the error "TTS task failed: file does not exist" appear?](./FAQ.md)

[3. TTS often fails or times out](./FAQ.md)

[4. I can connect to my self-hosted server over Wi-Fi, but not in 4G mode](./FAQ.md)

[5. How do I improve Xiaozhi's conversation response speed?](./FAQ.md)

[6. I speak slowly, and Xiaozhi keeps cutting in when I pause](./FAQ.md)

[7. I want to control lights, air conditioners, remote power on/off, etc. through Xiaozhi](./FAQ.md)
