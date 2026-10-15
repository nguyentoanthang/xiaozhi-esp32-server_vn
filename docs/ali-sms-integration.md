# Alibaba Cloud SMS Integration Guide

Log in to the Alibaba Cloud console and go to the "SMS Service" page: https://dysms.console.aliyun.com/overview

## Step 1: Add a signature
![Step](images/alisms/sms-01.png)
![Step](images/alisms/sms-02.png)

These steps give you a signature. Enter it into the Control Panel parameter `aliyun.sms.sign_name`

## Step 2: Add a template
![Step](images/alisms/sms-11.png)

These steps give you a template code. Enter it into the Control Panel parameter `aliyun.sms.sms_code_template_code`

Note: the signature takes up to 7 business days; SMS can only be sent successfully after the carrier filing is approved.

Note: the signature takes up to 7 business days; SMS can only be sent successfully after the carrier filing is approved.

Note: the signature takes up to 7 business days; SMS can only be sent successfully after the carrier filing is approved.

You can wait until the filing is approved before continuing.

## Step 3: Create an SMS account and grant permissions

Log in to the Alibaba Cloud console and go to the "Access Control" page: https://ram.console.aliyun.com/overview?activeTab=overview

![Step](images/alisms/sms-21.png)
![Step](images/alisms/sms-22.png)
![Step](images/alisms/sms-23.png)
![Step](images/alisms/sms-24.png)
![Step](images/alisms/sms-25.png)

These steps give you an access_key_id and an access_key_secret. Enter them into the Control Panel parameters `aliyun.sms.access_key_id` and `aliyun.sms.access_key_secret`
## Step 4: Enable phone number registration

1. Normally, once all of the above is filled in, you will see this result. If not, a step may have been missed

![Step](images/alisms/sms-31.png)

2. Allow non-administrator users to register: set the parameter `server.allow_user_register` to `true`

3. Enable phone number registration: set the parameter `server.enable_mobile_register` to `true`
![Step](images/alisms/sms-32.png)