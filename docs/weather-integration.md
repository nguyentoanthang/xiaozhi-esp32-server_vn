# Weather Plugin Usage Guide

## Overview

The weather plugin `get_weather` is one of the core features of the Xiaozhi ESP32 voice assistant. It supports querying weather information for locations across China by voice. The plugin is based on the QWeather (Heweather) API and provides real-time weather and a 7-day forecast.

## API Key Application Guide

### 1. Register a QWeather Account

1. Visit the [QWeather console](https://console.qweather.com/)
2. Register an account and complete email verification
3. Log in to the console

### 2. Create an Application to Get an API Key

1. In the console, click ["Project Management"](https://console.qweather.com/project?lang=zh) on the right -> "Create Project"
2. Fill in the project information:
   - **Project name**: e.g. "Xiaozhi Voice Assistant"
3. Click Save
4. After the project is created, click "Create Credential" in the project
5. Fill in the credential information:
    - **Credential name**: e.g. "Xiaozhi Voice Assistant"
    - **Authentication method**: choose "API Key"
6. Click Save
7. Copy the `API Key` from the credential. This is the first key piece of configuration information

### 3. Get the API Host

1. In the console, click ["Settings"](https://console.qweather.com/setting?lang=zh) -> "API Host"
2. View the dedicated `API Host` address assigned to you. This is the second key piece of configuration information

These steps give you two important pieces of configuration information: the `API Key` and the `API Host`

## Configuration

The plugin parameters are stored in the `setting` row `plugins.get_weather` (JSON):

1. Enter the first key setting you copied, the `API Key`, into `api_key`
2. Enter the second key setting you copied, the `API Host`, into `api_host`
3. Enter your city into `default_location`, for example `Guangzhou`

```bash
sqlite3 data/xiaozhi.db "UPDATE setting SET value = json_set(value, '$.api_key', 'your QWeather API key', '$.api_host', 'your QWeather API host address', '$.default_location', 'your default query city') WHERE key = 'plugins.get_weather';"
```

Plugins are switched off by default. Enable them once in the database (the second command lists the plugin in the function list of the
`function_call` intent model; keep the other names if the list already has some):

```bash
sqlite3 data/xiaozhi.db "UPDATE setting SET value = 'true' WHERE key = 'tools.server_plugins_enabled';"
sqlite3 data/xiaozhi.db "UPDATE model_config SET config_json = json_set(config_json, '$.functions', json('[\"get_weather\"]')) WHERE id = 'Intent_function_call';"
```

Restart the server afterwards (the shared intent module is created at startup).

