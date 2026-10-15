# Building the esp32 Firmware

## Step 1: Prepare Your OTA Address

If you are using version 0.3.12 of this project, you will have an OTA address regardless of whether you use the simple Server deployment or the full-module deployment.

Because the OTA address is set differently in the simple Server deployment and the full-module deployment, choose the specific method below:

### If You Use the Simple Server Deployment
Now open your OTA address in a browser. For example, my OTA address is
```
http://192.168.1.25:8003/xiaozhi/ota/
```
If it shows "OTA interface is running normally, the websocket address sent to devices is: ws://xxx:8000/xiaozhi/v1/

You can start the `digital-human` module and open `index.html` to test whether you can connect to the websocket address shown on the OTA page.

If it cannot be reached, you need to change the `server.websocket` address in the `.config.yaml` configuration file, restart, and test again until `index.html` can connect normally.

Once it succeeds, continue to Step 2

### If You Use the Full-Module Deployment
Now open your OTA address in a browser. For example, my OTA address is
```
http://192.168.1.25:8002/xiaozhi/ota/
```

If it shows "OTA interface is running normally, number of websocket clusters: X", continue to Step 2.

If it shows "OTA interface is not running normally", you probably have not yet configured the `Websocket` address in the `Control Panel`. In that case:

- 1. Log in to the Control Panel as the super administrator

- 2. Click `Parameter Management` in the top menu

- 3. Find the `server.websocket` item in the list and enter your `Websocket` address. For example, mine is

```
ws://192.168.1.25:8000/xiaozhi/v1/
```

After configuring it, refresh your OTA API address in the browser and see whether it is normal now. If it is still not normal, double-check whether the Websocket service started properly and whether the Websocket address was configured.

## Step 2: Configure the Environment
First configure the project environment by following this tutorial: [Setting up the ESP IDF 5.3.2 development environment on Windows and building Xiaozhi](https://icnynnzcwou8.feishu.cn/wiki/JEYDwTTALi5s2zkGlFGcDiRknXf)

## Step 3: Open the Configuration File
After configuring the build environment, download the source code of Brother Xia's xiaozhi-esp32 project,

Download Brother Xia's [xiaozhi-esp32 project source code](https://github.com/78/xiaozhi-esp32) from here.

After downloading, open the `xiaozhi-esp32/main/Kconfig.projbuild` file.

## Step 4: Change the OTA Address

Find the `default` content of `OTA_URL` and change `https://api.tenclass.net/xiaozhi/ota/`
   to your own address. For example, my API address is `http://192.168.1.25:8002/xiaozhi/ota/`, so I change the content to that.

Before:
```
config OTA_URL
    string "Default OTA URL"
    default "https://api.tenclass.net/xiaozhi/ota/"
    help
        The application will access this URL to check for new firmwares and server address.
```
After:
```
config OTA_URL
    string "Default OTA URL"
    default "http://192.168.1.25:8002/xiaozhi/ota/"
    help
        The application will access this URL to check for new firmwares and server address.
```

## Step 4: Set the Build Parameters

Set the build parameters

```
# In a terminal, go to the root directory of xiaozhi-esp32
cd xiaozhi-esp32
# For example, my board is an esp32s3, so I set the build target to esp32s3. If your board is a different model, replace it with the corresponding model
idf.py set-target esp32s3
# Enter menu configuration
idf.py menuconfig
```

After entering menu configuration, go into `Xiaozhi Assistant` and set `BOARD_TYPE` to the specific model of your board
Save and exit, then return to the terminal command line.

## Step 5: Build the Firmware

```
idf.py build
```

## Step 6: Package the bin Firmware

```
cd scripts
python release.py
```

After the packaging commands above finish, the firmware file `merged-binary.bin` is generated in the `build` directory under the project root.
This `merged-binary.bin` is the firmware file to flash onto the hardware.

Note: if you get a "zip"-related error after running the second command, ignore it, as long as the firmware file `merged-binary.bin` is generated in the `build` directory
it has no significant impact on you; please continue.

## Step 7: Flash the Firmware
   Connect the esp32 device to your computer and open the following URL in the Chrome browser

```
https://espressif.github.io/esp-launchpad/
```

Open this tutorial: [Flash tool / flashing firmware from the web (no IDF development environment)](https://ccnphfhqs21z.feishu.cn/wiki/Zpz4wXBtdimBrLk25WdcXzxcnNS).
Scroll to: `Method 2: ESP-Launchpad browser-based flashing`, and starting from `3. Flash the firmware / download to the development board`, follow the tutorial.

After flashing succeeds and the device connects to the network, wake Xiaozhi with the wake word and watch the console output of the server.

## FAQ
Here are some common questions for reference:

[1. Why does Xiaozhi recognize a lot of Korean, Japanese, and English from what I say](./FAQ.md)

[2. Why does the error "TTS task failed: file does not exist" appear?](./FAQ.md)

[3. TTS often fails or times out](./FAQ.md)

[4. I can connect to my self-hosted server over Wi-Fi, but not in 4G mode](./FAQ.md)

[5. How do I improve Xiaozhi's conversation response speed?](./FAQ.md)

[6. I speak slowly, and Xiaozhi keeps cutting in when I pause](./FAQ.md)

[7. I want to control lights, air conditioners, remote power on/off, etc. through Xiaozhi](./FAQ.md)
