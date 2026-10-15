# Device-to-Device Calling Plugin Guide

## Overview

The device calling feature allows two configured devices to communicate bidirectionally over a voice/data channel. When device A calls device B, the system works through the following flow:

```
Device A → authorization check → MQTT gateway → remote wake-up of device B → connection established → call established
```
## Prerequisites for Using This Feature
1. You must have at least two devices, and each must be an `ESP32-S3`, because only the `ESP32-S3` supports remote wake-up.
2. Your devices must have `two microphones`. If your device has only a `single microphone` and you just want to try the feature, that also works, but it will feel very laggy.
3. You must deploy this project using the [full-module deployment](Deployment_all.md), because you need the `Control Panel` to manage device permissions and communication.
4. You must install and configure the [MQTT gateway service](mqtt-gateway-integration.md) from `May 27, 2026` or later. If you have already deployed the MQTT gateway service, confirm that the code version is from after `May 27, 2026`.

The above are the hard requirements for using this feature; the details follow.

## Configuration Steps

### Step 1: Enable the Address Book Feature

1. Confirm that your Control Panel version is `0.9.4` or later.
2. Log in to the Control Panel back end
3. Go to **System Feature Configuration**
4. In the feature list on the left, check **Address Book**
5. Click **Save Configuration** to confirm

### Step 2: Configure Call Permissions Between Devices

1. In the top menu of the Control Panel, click **Address Book**
2. Under the agent list on the left, select your device A from the device list (you can search by MAC address or remark name)
3. In the detail panel on the right, find the name setting for the target device B, for example **"Xiao Wang"**
4. Check the **Call Permission** checkbox for device B
5. Click **Save**

**Note on two-way authorization:** For device A and device B to communicate with each other, you must configure each other's permissions on both sides in the Control Panel. For example:

- Check device B in device A's configuration → device A can communicate with device B
- Check device A in device B's configuration → device B can communicate with device A

### Step 3: Add the Call Tool in the Agent Configuration

1. In the top menu of the Control Panel, click **Agent Management**
2. On the agent for which you just configured device contacts, click **Edit Role**
3. In the detail panel on the right, click **Edit Functions**
4. Check the **Device Calls Device** tool
5. Click **Save Configuration** to confirm
6. Click **Save Configuration** again on the outer page, then restart the device

### Step 4: Add the Remote Wake-Up Tool in the Firmware

1. On top of the [xiaozhi-esp32](https://github.com/78/xiaozhi-esp32) code, add the remote wake-up tool MCP. Supported versions are 2.1.0 to 2.2.6 (the version as of May 29, 2026)
2. Add the remote wake-up function declaration to the application.h file
    ```cpp
    void RemoteWakeup(const std::string& reason);
    ```
3. Add the remote wake-up function to the application.cc file
    ```cpp
    void Application::RemoteWakeup(const std::string& reason){
        if (!protocol_) {
            return;
        }

        auto state = GetDeviceState();
        
        if (state == kDeviceStateIdle) {
            audio_service_.EncodeWakeWord();

            if (!protocol_->IsAudioChannelOpened()) {
                SetDeviceState(kDeviceStateConnecting);
                if (!protocol_->OpenAudioChannel()) {
                    audio_service_.EnableWakeWordDetection(true);
                    return;
                }
            }
            std::string wake_word = reason;
    #if CONFIG_USE_AFE_WAKE_WORD || CONFIG_USE_CUSTOM_WAKE_WORD
            // Encode and send the wake word data to the server
            while (auto packet = audio_service_.PopWakeWordPacket()) {
                protocol_->SendAudio(std::move(packet));
            }
            // Set the chat state to wake word detected
            protocol_->SendWakeWordDetected(wake_word);
            SetListeningMode(aec_mode_ == kAecOff ? kListeningModeAutoStop : kListeningModeRealtime);
    #else
            // Set flag to play popup sound after state changes to listening
            // (PlaySound here would be cleared by ResetDecoder in EnableVoiceProcessing)
            play_popup_on_listening_ = true;
            SetListeningMode(aec_mode_ == kAecOff ? kListeningModeAutoStop : kListeningModeRealtime);
    #endif
        } else if (state == kDeviceStateSpeaking) {
            AbortSpeaking(kAbortReasonWakeWordDetected);
            SetDeviceState(kDeviceStateIdle);
        } else if (state == kDeviceStateActivating) {
            SetDeviceState(kDeviceStateIdle);
        }
    }
    ```
4. Add the remote wake-up tool to the mcp_server.cc file
    ```cpp
    AddUserOnlyTool("self.remote_wakeup", "Remote wakeup function with configurable parameters",
        PropertyList({
            Property("reason", kPropertyTypeString, "Wakeup reason"),
        }),
        [this](const PropertyList& properties) -> ReturnValue {
            std::string reason = properties["reason"].value<std::string>();
            ESP_LOGI(TAG, "Wakeup reason=%s", reason.c_str());
            auto& app = Application::GetInstance();
            app.RemoteWakeup(reason);
            return true;
    ```
5. Follow the [firmware build and flashing guide](firmware-build.md) to flash the firmware
6. Whether your device has a single microphone or two, check the option to enable the AEC feature during the build!
7. Whether your device has a single microphone or two, check the option to enable the AEC feature during the build!
8. Whether your device has a single microphone or two, check the option to enable the AEC feature during the build!

### Step 5: Configure the MQTT Gateway Service

1. Deploy the MQTT gateway service; see the [MQTT gateway integration document](mqtt-gateway-integration.md)
2. If it is already deployed, confirm that the code version is the one from May 27, 2026

## Call Flow

Prepare two devices. After configuring the communication permissions in the Control Panel and adding the call tool to the agent, say to one of the Xiaozhi devices: "Call XXX", and observe whether device B responds.

## FAQ

### Q: Device B does not respond to the call?

- Check whether device B is online (device status in the Control Panel)
- Confirm that device B's firmware has the remote wake-up tool integrated correctly
- Check whether the MQTT gateway connection is normal
- Verify that the two-way permission configuration is complete

### Q: I get the message "No call permission"?

- In the Control Panel, confirm that device A has device B's call permission checked
- Confirm that the configuration has been saved (not just modified without saving)

### Q: How do I confirm that the address book feature is enabled?

- If the top menu of the Control Panel shows an "Address Book" entry, the feature is enabled

### Q: I tell it to call "Zhang Shan", but it keeps recognizing "Zhang San". What should I do?
- Check the documentation of the ASR service you use to confirm whether it supports hot word recognition.
- If you use `FunASRServer`, you can add "Zhang Shan" to the `hot word file` in the container and then restart the container.
- If you use the `Volcano Engine` service, you can add a `hot word file` in the `Volcano Engine console`, then go back to the `model configuration page` of the Control Panel and set the `hot word file name` on the `Volcano Engine TTS`.

