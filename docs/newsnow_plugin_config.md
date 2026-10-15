# get_news_from_newsnow Plugin News Source Configuration Guide

<!-- TODO(vi): customize for Vietnamese usage (see docs/remove-chinese-plan.md). The news source names below are Chinese plugin data and must match the NewsNow identifiers. -->

## Overview

The `get_news_from_newsnow` plugin now supports configuring news sources dynamically through the web management interface, with no need to modify code. Users can configure different news sources for each agent in the Control Panel.

## Configuration Methods

### 1. Configure Through the Web Management Interface (Recommended)

1. Log in to the Control Panel
2. Go to the "Role Configuration" page
3. Select the agent to configure
4. Click the "Edit Functions" button
5. In the parameter configuration area on the right, find the "newsnow news aggregation" plugin
6. In the "News Source Configuration" field, enter the Chinese names separated by semicolons

### 2. Configuration File

Configure in `config.yaml`:

```yaml
plugins:
  get_news_from_newsnow:
    url: "https://newsnow.busiyi.world/api/s?id="
    news_sources: "澎湃新闻;百度热搜;财联社;微博;抖音"
```

## News Source Configuration Format

The news source configuration uses Chinese names separated by semicolons, in the format:

```
Chinese-name-1;Chinese-name-2;Chinese-name-3
```

### Configuration Example

```
澎湃新闻;百度热搜;财联社;微博;抖音;知乎;36氪
```

## Supported News Sources

The plugin supports the following news sources, identified by their Chinese names:

- 澎湃新闻
- 百度热搜
- 财联社
- 微博
- 抖音
- 知乎
- 36氪
- 华尔街见闻
- IT之家
- 今日头条
- 虎扑
- 哔哩哔哩
- 快手
- 雪球
- 格隆汇
- 法布财经
- 金十数据
- 牛客
- 少数派
- 稀土掘金
- 凤凰网
- 虫部落
- 联合早报
- 酷安
- 远景论坛
- 参考消息
- 卫星通讯社
- 百度贴吧
- 靠谱新闻
- and more...

## Default Configuration

If no news source is configured, the plugin uses the following default configuration:

```
澎湃新闻;百度热搜;财联社
```

## Usage

1. **Configure news sources**: Set the Chinese names of the news sources in the web interface or the configuration file, separated by semicolons
2. **Call the plugin**: The user can say "broadcast the news" or "get the news"
3. **Specify a news source**: The user can say "broadcast 澎湃新闻 (The Paper) news" or "get 百度热搜 (Baidu Hot Search)"
4. **Get details**: The user can say "tell me more about this news item"

## How It Works

1. The plugin accepts a Chinese name as a parameter (such as "澎湃新闻")
2. Based on the configured news source list, the Chinese name is converted to the corresponding English ID (such as "thepaper")
3. The English ID is used to call the API to fetch the news data
4. The news content is returned to the user

## Notes

1. The configured Chinese names must exactly match the names defined in CHANNEL_MAP
2. After changing the configuration, restart the service or reload the configuration
3. If a configured news source is invalid, the plugin automatically uses the default news source
4. Separate multiple news sources with the English semicolon (;), not the Chinese semicolon (；)