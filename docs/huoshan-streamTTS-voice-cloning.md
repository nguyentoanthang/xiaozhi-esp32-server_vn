# Control Panel: Volcano Engine Dual-Stream Speech Synthesis + Voice Cloning Setup Guide

This tutorial has 4 stages: preparation, configuration, cloning, and usage. It mainly describes how to configure Volcano Engine dual-stream speech synthesis + voice cloning through the Control Panel.

## Stage 1: Preparation
The super administrator first enables the Volcano Engine service in advance and obtains the App Id and Access Token. By default, Volcano Engine gives you one voice resource for free. This voice resource needs to be copied into this project.

If you want to clone multiple voices, you need to purchase and enable multiple voice resources. Just copy the voice ID (S_xxxxx) of each voice resource into this project and then assign it to a system account. The detailed steps are as follows:

### 1. Enable the Volcano Engine service
Visit https://console.volcengine.com/speech/app, create an application under Application Management, and check the speech synthesis large model and the voice cloning large model.

### 2. Get the voice resource ID
Visit https://console.volcengine.com/speech/service/9999 and copy three items: the App Id, the Access Token, and the voice ID (S_xxxxx), as shown

![Get the voice resource](images/image-clone-integration-01.png)

## Stage 2: Configure the Volcano Engine Service

### 1. Fill in the Volcano Engine configuration

Log in to the Control Panel with the super administrator account, click [Model Configuration] at the top, then click [Speech Synthesis] on the left side of the model configuration page, search for "Volcano Engine Dual-Stream Speech Synthesis", click Edit, enter your Volcano Engine `App Id` into the [Application ID] field and the `Access Token` into the [Access Token] field. Then save.

### 2. Assign the voice resource ID to a system account

Log in to the Control Panel with the super administrator account, click `Parameter Dictionary` at the top, and in the dropdown menu click the `System Feature Configuration` page. Check `Voice Cloning` on the page and click Save Configuration. You will then see the `Voice Cloning` button in the top menu.

Log in to the Control Panel with the super administrator account and click [Voice Cloning] and then [Voice Resources] at the top.

Click the Add button and select "Volcano Engine Dual-Stream Speech Synthesis" in [Platform Name];

Enter your Volcano Engine voice resource ID (S_xxxxx) in [Voice Resource ID] and press Enter;

In [Owner Account], select the system account to assign it to; you can assign it to yourself. Then click Save

## Stage 3: Cloning

After logging in, if you click [Voice Cloning] > [Voice Cloning] at the top and see [Your account has no voice resources. Please contact the administrator to assign voice resources], you have not yet assigned the voice resource ID to this account in Stage 2. Go back to Stage 2 and assign the voice resource to the account.

After logging in, if you click [Voice Cloning] > [Voice Cloning] at the top and can see the corresponding voice list, please continue.

You will see the corresponding voice list. Select one of the voice resources and click the [Upload Audio] button. After uploading, you can preview the sound or crop a segment of it. Once confirmed, click the [Upload Audio] button.
![Upload audio](images/image-clone-integration-02.png)

After uploading the audio, the corresponding voice in the list will change to the "Pending Cloning" status. Click the [Clone Now] button. The result is returned after 1 to 2 seconds.

If the cloning fails, hover the mouse over the "Error Information" icon to see the reason for the failure.

If the cloning succeeds, the corresponding voice in the list will change to the "Training Successful" status. You can then click the edit button in the [Voice Name] column to rename the voice resource for easier selection later.

## Stage 4: Usage

Click [Agent Management] at the top, select any agent, and click the [Configure Role] button.

For Speech Synthesis (TTS), select "Volcano Engine Dual-Stream Speech Synthesis". In the list, find the voice resource whose name contains "Cloned Voice" (as shown), select it, and click Save.
![Select a voice](images/image-clone-integration-03.png)

Next, you can wake Xiaozhi and talk to it.
