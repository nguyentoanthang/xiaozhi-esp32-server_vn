import random
import httpx
from io import BytesIO
from markitdown import MarkItDown, StreamInfo
from config.logger import setup_logging
from plugins_func.register import register_function, ToolType, ActionResponse, Action
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from core.connection import ConnectionHandler


TAG = __name__
logger = setup_logging()

# TODO(vi): customize for Vietnamese usage (see docs/remove-chinese-plan.md); Chinese source names kept (deferred plugin)
CHANNEL_MAP = {
    "V2EX": "v2ex-share",
    "知乎": "zhihu",
    "微博": "weibo",
    "联合早报": "zaobao",
    "酷安": "coolapk",
    "MKTNews": "mktnews-flash",
    "华尔街见闻": "wallstreetcn-quick",
    "36氪": "36kr-quick",
    "抖音": "douyin",
    "虎扑": "hupu",
    "百度贴吧": "tieba",
    "今日头条": "toutiao",
    "IT之家": "ithome",
    "澎湃新闻": "thepaper",
    "卫星通讯社": "sputniknewscn",
    "参考消息": "cankaoxiaoxi",
    "远景论坛": "pcbeta-windows11",
    "财联社": "cls-depth",
    "雪球": "xueqiu-hotstock",
    "格隆汇": "gelonghui",
    "法布财经": "fastbull-express",
    "Solidot": "solidot",
    "Hacker News": "hackernews",
    "Product Hunt": "producthunt",
    "Github": "github-trending-today",
    "哔哩哔哩": "bilibili-hot-search",
    "快手": "kuaishou",
    "靠谱新闻": "kaopu",
    "金十数据": "jin10",
    "百度热搜": "baidu",
    "牛客": "nowcoder",
    "少数派": "sspai",
    "稀土掘金": "juejin",
    "凤凰网": "ifeng",
    "虫部落": "chongbuluo-latest",
}

# Default news sources, used when none are specified in the config
DEFAULT_NEWS_SOURCES = "澎湃新闻;百度热搜;财联社"

def _get_newsnow_config(conn):
    # Get from the connection config
    plugins = conn.config.get("plugins", {})
    newsnow = plugins.get("get_news_from_newsnow", {})
    sources = newsnow.get("news_sources", "")
    if isinstance(sources, str) and sources.strip():
        return sources

    return ""

def get_news_sources_from_config(conn):
    """Get the news source string from the config"""
    try:
        result = _get_newsnow_config(conn)
        if result:
            logger.bind(tag=TAG).debug(f"Using configured news sources: {result}")
            return result

        logger.bind(tag=TAG).debug("News source config not found, using default config")
        return DEFAULT_NEWS_SOURCES

    except Exception as e:
        logger.bind(tag=TAG).error(f"Failed to get news source config: {e}, using default config")
        return DEFAULT_NEWS_SOURCES


# Get the available news source names from the default config (obtained dynamically at runtime by get_news_sources_from_config)
example_sources_str = DEFAULT_NEWS_SOURCES.replace(";", ", ")

GET_NEWS_FROM_NEWSNOW_FUNCTION_DESC = {
    "type": "function",
    "function": {
        "name": "get_news_from_newsnow",
        "description": "Call this when the user asks to view or listen to the news (e.g. 'give me some news', 'what is the news today').",
        "parameters": {
            "type": "object",
            "properties": {
                "source": {
                    "type": "string",
                    "description": f"The standard Chinese name of the news source, e.g. {example_sources_str}. Optional; if not provided, the default news source is used",
                },
                "detail": {
                    "type": "boolean",
                    "description": "Whether to get detailed content, default false. If true, get the details of the previous news item",
                },
                "lang": {
                    "type": "string",
                    "description": "The language code the user is using, e.g. zh_CN/zh_HK/en_US/ja_JP, default zh_CN",
                },
            },
            "required": ["lang"],
        },
    },
}


async def fetch_news_from_api(conn: "ConnectionHandler", source="thepaper"):
    """Get the news list from the API"""
    try:
        api_url = f"https://newsnow.busiyi.world/api/s?id={source}"

        news_config = conn.config.get("plugins", {}).get("get_news_from_newsnow", {})
        if news_config.get("url"):
            api_url = news_config["url"] + source

        headers = {"User-Agent": "Mozilla/5.0"}
        async with httpx.AsyncClient(timeout=httpx.Timeout(10.0, connect=3.0)) as client:
            response = await client.get(api_url, headers=headers)

        data = response.json()

        if "items" in data:
            return data["items"]
        else:
            logger.bind(tag=TAG).error(f"News API response format error: {data}")
            return []

    except Exception as e:
        logger.bind(tag=TAG).error(f"Failed to get news from API: {e}")
        return []


async def fetch_news_detail(url):
    """Get the content of the news detail page and clean the HTML with MarkItDown"""
    try:
        headers = {"User-Agent": "Mozilla/5.0"}
        async with httpx.AsyncClient(timeout=httpx.Timeout(10.0, connect=3.0)) as client:
            response = await client.get(url, headers=headers)

        # Clean the HTML content with MarkItDown
        md = MarkItDown(enable_plugins=False)
        result = md.convert_stream(
            BytesIO(response.content),
            stream_info=StreamInfo(
                mimetype="text/html",
                extension=".html",
                charset=response.encoding or "utf-8",
            ),
        )

        # Get the cleaned text content
        clean_text = result.text_content

        # If the cleaned content is empty, return a hint message
        if not clean_text or len(clean_text.strip()) == 0:
            logger.bind(tag=TAG).warning(f"News content is empty after cleaning: {url}")
            return "Unable to parse the news detail content. The website structure may be special or the content restricted."

        return clean_text
    except Exception as e:
        logger.bind(tag=TAG).error(f"Failed to get news details: {e}")
        return "Unable to get detailed content"


@register_function(
    "get_news_from_newsnow",
    GET_NEWS_FROM_NEWSNOW_FUNCTION_DESC,
    ToolType.SYSTEM_CTL,
)
async def get_news_from_newsnow(
    conn: "ConnectionHandler",
    source: str = "澎湃新闻",
    detail: bool = False,
    lang: str = "zh_CN",
):
    """Get news and randomly select one to broadcast, or get the details of the previous news item"""
    try:
        # Get the currently configured news sources
        news_sources = get_news_sources_from_config(conn)

        # If detail is True, get the details of the previous news item
        detail = str(detail).lower() == "true"
        if detail:
            if (
                not hasattr(conn, "last_newsnow_link")
                or not conn.last_newsnow_link
                or "url" not in conn.last_newsnow_link
            ):
                return ActionResponse(
                    Action.REQLLM,
                    "Sorry, no recently queried news was found. Please get a news item first.",
                    None,
                )

            url = conn.last_newsnow_link.get("url")
            title = conn.last_newsnow_link.get("title", "Unknown title")
            source_id = conn.last_newsnow_link.get("source_id", "thepaper")
            source_name = CHANNEL_MAP.get(source_id, "Unknown source")

            if not url or url == "#":
                return ActionResponse(
                    Action.REQLLM, "Sorry, this news item has no available link to get detailed content.", None
                )

            logger.bind(tag=TAG).debug(
                f"Getting news details: {title}, source: {source_name}, URL={url}"
            )

            # Get the news details
            detail_content = await fetch_news_detail(url)

            if not detail_content or detail_content == "Unable to get detailed content":
                return ActionResponse(
                    Action.REQLLM,
                    f"Sorry, unable to get the detailed content of '{title}'. The link may have expired or the website structure may have changed.",
                    None,
                )

            # Build the detail report
            detail_report = (
                f"Based on the following data, respond to the user's news detail query in {lang}:\n\n"
                f"News title: {title}\n"
                # f"News source: {source_name}\n"
                f"Detailed content: {detail_content}\n\n"
                f"(Please summarize the above news content, extract the key information, and broadcast it to the user in a natural, fluent way, "
                f"without mentioning that this is a summary, as if telling a complete news story)"
            )

            return ActionResponse(Action.REQLLM, detail_report, None)

        # Otherwise, get the news list and randomly select one
        # Convert the Chinese name to the English ID
        english_source_id = None

        # Check whether the entered Chinese name is in the configured news sources
        news_sources_list = [
            name.strip() for name in news_sources.split(";") if name.strip()
        ]
        if source in news_sources_list:
            # If the entered Chinese name is in the configured news sources, look up the corresponding English ID in CHANNEL_MAP
            english_source_id = CHANNEL_MAP.get(source)

        # If no corresponding English ID is found, use the default source
        if not english_source_id:
            logger.bind(tag=TAG).warning(f"Invalid news source: {source}, using default source 澎湃新闻 (The Paper)")
            english_source_id = "thepaper"
            source = "澎湃新闻"

        logger.bind(tag=TAG).info(f"Getting news: news source={source}({english_source_id})")

        # Get the news list
        news_items = await fetch_news_from_api(conn, english_source_id)

        if not news_items:
            return ActionResponse(
                Action.REQLLM,
                f"Sorry, unable to get news from {source}. Please try again later or try another news source.",
                None,
            )

        # Randomly select a news item
        selected_news = random.choice(news_items)

        # Save the current news link to the connection object for later detail queries
        if not hasattr(conn, "last_newsnow_link"):
            conn.last_newsnow_link = {}
        conn.last_newsnow_link = {
            "url": selected_news.get("url", "#"),
            "title": selected_news.get("title", "Unknown title"),
            "source_id": english_source_id,
        }

        # Build the news report
        news_report = (
            f"Based on the following data, respond to the user's news query in {lang}:\n\n"
            f"News title: {selected_news['title']}\n"
            # f"News source: {source}\n"
            f"(Please broadcast this news title to the user in a natural, fluent way, "
            f"and tell the user they can ask for detailed content, in which case the news details will be fetched.)"
        )

        return ActionResponse(Action.REQLLM, news_report, None)

    except Exception as e:
        logger.bind(tag=TAG).error(f"Error getting news: {e}")
        return ActionResponse(
            Action.REQLLM, "Sorry, an error occurred while getting the news. Please try again later.", None
        )
