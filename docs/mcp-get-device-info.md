# How to Get Device Information in MCP Methods

This tutorial guides you through using MCP methods to get device information.

Step 1: Customize your `agent-base-prompt.txt` file

Copy the content of the `agent-base-prompt.txt` file from the xiaozhi-server directory into your `data` directory and rename it to `.agent-base-prompt.txt`.

Step 2: Edit the `data/.agent-base-prompt.txt` file, find the `<context>` tag, and add the following content inside the tag:
```
- **Device ID:** {{device_id}}
```

After adding it, the content of the `<context>` tag in your `data/.agent-base-prompt.txt` file looks roughly like this:
```
<context>
[Important! The following information has been provided in real time. There is no need to call a tool to query it; use it directly:]
- **Device ID:** {{device_id}}
- **Current time:** {{current_time}}
- **Today's date:** {{today_date}} ({{today_weekday}})
- **Today's lunar date:** {{lunar_date}}
- **User's city:** {{local_address}}
- **Local weather for the next 7 days:** {{weather_info}}
</context>
```

Step 3: Edit the `data/.config.yaml` file, find the `agent-base-prompt` setting. The content before the change is as follows:
```
prompt_template: agent-base-prompt.txt
```
Change it to
```
prompt_template: data/.agent-base-prompt.txt
```

Step 4: Restart your xiaozhi-server service.

Step 5: Add a parameter named `device_id`, of type `string`, with the description `Device ID`, to your mcp method.

Step 6: Wake Xiaozhi again, have it call your mcp method, and check whether your mcp method can get the `Device ID`.
