import random
import httpx
import xml.etree.ElementTree as ET
from bs4 import BeautifulSoup
from config.logger import setup_logging
from plugins_func.register import register_function, ToolType, ActionResponse, Action
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from core.connection import ConnectionHandler


TAG = __name__
logger = setup_logging()

GET_NEWS_FROM_CHINANEWS_FUNCTION_DESC = {
    "type": "function",
    "function": {
        "name": "get_news_from_chinanews",
        "description": (
            "Call this when the user asks to view or listen to the news (e.g. 'give me some news', 'what is the news today')."
            "The user can specify a news type, such as society news, technology news, international news, etc."
            "If none is specified, society news is broadcast by default."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "category": {
                    "type": "string",
                    "description": "News category, e.g. society, technology, international. Optional; if not provided, the default category is used",
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


async def fetch_news_from_rss(rss_url):
    """Get the news list from the RSS feed"""
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(5.0, connect=3.0)) as client:
            response = await client.get(rss_url)

        # Parse the XML
        root = ET.fromstring(response.content)

        # Find all item elements (news entries)
        news_items = []
        for item in root.findall(".//item"):
            title = (
                item.find("title").text if item.find("title") is not None else "No title"
            )
            link = item.find("link").text if item.find("link") is not None else "#"
            description = (
                item.find("description").text
                if item.find("description") is not None
                else "No description"
            )
            pubDate = (
                item.find("pubDate").text
                if item.find("pubDate") is not None
                else "Unknown time"
            )

            news_items.append(
                {
                    "title": title,
                    "link": link,
                    "description": description,
                    "pubDate": pubDate,
                }
            )

        return news_items
    except Exception as e:
        logger.bind(tag=TAG).error(f"Failed to get RSS news: {e}")
        return []


async def fetch_news_detail(url):
    """Get the content of the news detail page and summarize it"""
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(10.0, connect=3.0)) as client:
            response = await client.get(url)

        soup = BeautifulSoup(response.content, "html.parser")

        # Try to extract the main content (the selectors here need to be adjusted to the actual website structure)
        content_div = soup.select_one(
            ".content_desc, .content, article, .article-content"
        )
        if content_div:
            paragraphs = content_div.find_all("p")
            content = "\n".join(
                [p.get_text().strip() for p in paragraphs if p.get_text().strip()]
            )
            return content
        else:
            # If no specific content area is found, try to get all paragraphs
            paragraphs = soup.find_all("p")
            content = "\n".join(
                [p.get_text().strip() for p in paragraphs if p.get_text().strip()]
            )
            return content[:2000]  # Limit the length
    except Exception as e:
        logger.bind(tag=TAG).error(f"Failed to get news details: {e}")
        return "Unable to get detailed content"


def map_category(category_text):
    """Map the Chinese category entered by the user to the category key in the config file"""
    if not category_text:
        return None

    # Category mapping dictionary; currently supports society, international and finance news. For more types, see the config file
    # TODO(vi): customize for Vietnamese usage (see docs/remove-chinese-plan.md); Chinese keys kept for the Chinese-only source
    category_map = {
        "society": "society_rss_url",
        "world": "world_rss_url",
        "international": "world_rss_url",
        "finance": "finance_rss_url",
        # Society news
        "社会": "society_rss_url",
        "社会新闻": "society_rss_url",
        # International news
        "国际": "world_rss_url",
        "国际新闻": "world_rss_url",
        # Finance news
        "财经": "finance_rss_url",
        "财经新闻": "finance_rss_url",
        "金融": "finance_rss_url",
        "经济": "finance_rss_url",
    }

    # Convert to lowercase and strip spaces
    normalized_category = category_text.lower().strip()

    # Return the mapping result; if there is no match, return the original input
    return category_map.get(normalized_category, category_text)


@register_function(
    "get_news_from_chinanews",
    GET_NEWS_FROM_CHINANEWS_FUNCTION_DESC,
    ToolType.SYSTEM_CTL,
)
async def get_news_from_chinanews(
    conn: "ConnectionHandler",
    category: str = None,
    detail: bool = False,
    lang: str = "zh_CN",
):
    """Get news and randomly select one to broadcast, or get the details of the previous news item"""
    try:
        # If detail is True, get the details of the previous news item
        if detail:
            if (
                not hasattr(conn, "last_news_link")
                or not conn.last_news_link
                or "link" not in conn.last_news_link
            ):
                return ActionResponse(
                    Action.REQLLM,
                    "Sorry, no recently queried news was found. Please get a news item first.",
                    None,
                )

            link = conn.last_news_link.get("link")
            title = conn.last_news_link.get("title", "Unknown title")

            if link == "#":
                return ActionResponse(
                    Action.REQLLM, "Sorry, this news item has no available link to get detailed content.", None
                )

            logger.bind(tag=TAG).debug(f"Getting news details: {title}, URL={link}")

            # Get the news details
            detail_content = await fetch_news_detail(link)

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
                f"Detailed content: {detail_content}\n\n"
                f"(Please summarize the above news content, extract the key information, and broadcast it to the user in a natural, fluent way, "
                f"without mentioning that this is a summary, as if telling a complete news story)"
            )

            return ActionResponse(Action.REQLLM, detail_report, None)

        # Otherwise, get the news list and randomly select one
        # Get the RSS URL from the config
        rss_config = conn.config.get("plugins", {}).get("get_news_from_chinanews", {})
        default_rss_url = rss_config.get(
            "default_rss_url", "https://www.chinanews.com.cn/rss/society.xml"
        )

        # Map the user-entered category to the category key in the config
        mapped_category = map_category(category)

        # If a category is provided, try to get the corresponding URL from the config
        rss_url = default_rss_url
        if mapped_category and mapped_category in rss_config:
            rss_url = rss_config[mapped_category]

        logger.bind(tag=TAG).info(
            f"Getting news: original category={category}, mapped category={mapped_category}, URL={rss_url}"
        )

        # Get the news list
        news_items = await fetch_news_from_rss(rss_url)

        if not news_items:
            return ActionResponse(
                Action.REQLLM, "Sorry, unable to get news information. Please try again later.", None
            )

        # Randomly select a news item
        selected_news = random.choice(news_items)

        # Save the current news link to the connection object for later detail queries
        if not hasattr(conn, "last_news_link"):
            conn.last_news_link = {}
        conn.last_news_link = {
            "link": selected_news.get("link", "#"),
            "title": selected_news.get("title", "Unknown title"),
        }

        # Build the news report
        news_report = (
            f"Based on the following data, respond to the user's news query in {lang}:\n\n"
            f"News title: {selected_news['title']}\n"
            f"Publish time: {selected_news['pubDate']}\n"
            f"News content: {selected_news['description']}\n"
            f"(Please broadcast this news item to the user in a natural, fluent way; you may summarize the content appropriately, "
            f"just read out the news without any extra content. "
            f"If the user asks for more details, tell the user they can say 'please introduce this news in detail' to get more content)"
        )

        return ActionResponse(Action.REQLLM, news_report, None)

    except Exception as e:
        logger.bind(tag=TAG).error(f"Error getting news: {e}")
        return ActionResponse(
            Action.REQLLM, "Sorry, an error occurred while getting the news. Please try again later.", None
        )
