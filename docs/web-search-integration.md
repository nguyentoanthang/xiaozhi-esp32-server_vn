# Web Search Plugin Usage Guide

## Feature Overview

The web search plugin `web_search` supports searching the web for information in real time during a conversation and returning the results. The plugin supports three search providers: Metaso, Tavily, and Serply. Users can choose one of them as needed.

## API Key Application Guide

We currently support `Metaso Search`, `Tavily Search`, and `Serply Search`.
- Tavily Search: 1000 free calls per month.
- Metaso Search: has relatively high-quality domestic (Chinese) data sources.
- Serply Search: returns Google search results. Registration gives 2500 free calls; after the quota is used up, payment is required.

## API Key Application Guide

### Option 1: Use Metaso Search

- Visit the [Metaso Search API](https://metaso.cn/search-api/api-keys), register, and log in
- On the API key management page, click "Create new Key"
- Copy the generated API Key (prefixed with `mk-`). This is the key information needed for configuration

### Option 2: Use Tavily Search

- Visit the [Tavily console](https://app.tavily.com/home), register, and log in
- Create an API Key in the console
- Copy the generated API Key (prefixed with `tvly-`). This is the key information needed for configuration

### Option 3: Use Serply Search

- Visit [Serply](https://serply.io), register, and log in
- Create an API Key in the console
- Copy the generated API Key. This is the key information needed for configuration
- For the API description, see the [Serply documentation](https://serply.io/docs)

## Configuration Methods

### Method 1. Use the Control Panel Deployment (Recommended)

- Log in to the Control Panel
- Go to the "Configure Role" page and select the agent to configure
- Click the "Edit Functions" button and find the "Web search" plugin in the parameter configuration area on the right
- Check "Web search"
- Enter the search provider (`metaso`, `tavily`, or `serply`) and enter the corresponding `API Key` in the configuration item
- Save the configuration, then save the agent configuration

### Method 2. Single-Module xiaozhi-server Deployment

Configure in `data/.config.yaml`:

- Enter the search provider in `provider`; the options are `metaso`, `tavily`, or `serply`
- Enter the API Key you obtained in `api_key`

```yaml
plugins:
  web_search:
    provider: "metaso"
    api_key: "your API Key"
```

To customize the number of returned results and the tool description, additionally configure `max_results` and `description`:

```yaml
plugins:
  web_search:
    provider: "metaso"
    description: "Web search tool. Use this tool when the user explicitly needs to search the web for an answer."
    max_results: 5
    api_key: "your API Key"
```

Also make sure `web_search` is enabled in the `functions` list:

```yaml
plugins:
  functions:
    - web_search
```

Restart the service after the configuration for it to take effect.
