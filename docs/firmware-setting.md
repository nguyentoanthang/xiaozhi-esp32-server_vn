# Configure a Custom Server Based on the Firmware Built by Brother Xia

## Step 1: Confirm the Version
Flash the firmware already built by Brother Xia, [version 1.6.1 or above](https://github.com/78/xiaozhi-esp32/releases)

## Step 2: Prepare Your OTA Address
If you followed the tutorial and used the full-module deployment, you should have an OTA address.

Now open your OTA address in a browser. For example, my OTA address is
```
https://2662r3426b.vicp.fun/xiaozhi/ota/
```

If it shows "OTA interface is running normally, number of websocket clusters: X", continue.

If it shows "OTA interface is not running normally", you probably have not yet configured the `Websocket` address in the `Control Panel`. In that case:

- 1. Log in to the Control Panel as the super administrator

- 2. Click `Parameter Management` in the top menu

- 3. Find the `server.websocket` item in the list and enter your `Websocket` address. For example, mine is

```
wss://2662r3426b.vicp.fun/xiaozhi/v1/
```

After configuring it, refresh your OTA API address in the browser and see whether it is normal now. If it is still not normal, double-check whether the Websocket service started properly and whether the Websocket address was configured.

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
