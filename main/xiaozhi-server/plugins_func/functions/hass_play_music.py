import httpx
from config.logger import setup_logging
from plugins_func.functions.hass_init import initialize_hass_handler
from plugins_func.register import register_function, ToolType, ActionResponse, Action
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from core.connection import ConnectionHandler

TAG = __name__
logger = setup_logging()

hass_play_music_function_desc = {
    "type": "function",
    "function": {
        "name": "hass_play_music",
        "description": "Use when the user wants to listen to music or audiobooks; plays the corresponding audio on the room's media player (media_player)",
        "parameters": {
            "type": "object",
            "properties": {
                "media_content_id": {
                    "type": "string",
                    "description": "Can be the album name, song name, or artist of the music or audiobook; if not specified, use random",
                },
                "entity_id": {
                    "type": "string",
                    "description": "Device id of the speaker to operate, i.e. the entity_id in homeassistant, starting with media_player",
                },
            },
            "required": ["media_content_id", "entity_id"],
        },
    },
}


@register_function(
    "hass_play_music", hass_play_music_function_desc, ToolType.SYSTEM_CTL
)
async def hass_play_music(conn: "ConnectionHandler", entity_id="", media_content_id="random"):
    try:
        result = await handle_hass_play_music(conn, entity_id, media_content_id)
        return ActionResponse(
            action=Action.RECORD, result="Command received", response=result
        )
    except Exception as e:
        logger.bind(tag=TAG).error(f"Error handling music intent: {e}")
        return ActionResponse(
            action=Action.RESPONSE, result=str(e), response="An error occurred while playing music"
        )


async def handle_hass_play_music(
    conn: "ConnectionHandler", entity_id, media_content_id
):
    ha_config = initialize_hass_handler(conn)
    api_key = ha_config.get("api_key")
    base_url = ha_config.get("base_url")
    url = f"{base_url}/api/services/music_assistant/play_media"
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    data = {"entity_id": entity_id, "media_id": media_content_id}

    async with httpx.AsyncClient(timeout=httpx.Timeout(10.0, connect=3.0)) as client:
        response = await client.post(url, headers=headers, json=data)

    if response.status_code == 200:
        return f"Now playing music: {media_content_id}"
    else:
        return f"Failed to play music, error code: {response.status_code}"
