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

## Configuration

The plugin parameters are stored in the `setting` row `plugins.web_search` (JSON):

- `provider`: the search provider, one of `metaso`, `tavily`, or `serply`
- `api_key`: the API Key you obtained
- optional `max_results` (default 5) and `description` (tool description for the LLM)

```bash
sqlite3 data/xiaozhi.db "UPDATE setting SET value = json_set(value, '$.provider', 'metaso', '$.api_key', 'your API Key') WHERE key = 'plugins.web_search';"
```

Plugins are switched off by default. Enable them once in the database (the second command sets the function list of the
`function_call` intent model; add to it instead if it already lists other plugins):

```bash
sqlite3 data/xiaozhi.db "UPDATE setting SET value = 'true' WHERE key = 'tools.server_plugins_enabled';"
sqlite3 data/xiaozhi.db "UPDATE model_config SET config_json = json_set(config_json, '$.functions', json('[\"web_search\"]')) WHERE id = 'Intent_function_call';"
```

Restart the server afterwards.
