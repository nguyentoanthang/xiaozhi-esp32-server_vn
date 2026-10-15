import asyncio
import json
from typing import Dict, Any

from core.handle.textMessageHandler import TextMessageHandler
from core.handle.textMessageType import TextMessageType
from core.providers.tools.device_mcp import handle_mcp_message

TAG = __name__

class ServerTextMessageHandler(TextMessageHandler):
    """Server message handler"""

    @property
    def message_type(self) -> TextMessageType:
        return TextMessageType.SERVER

    async def handle(self, conn, msg_json: Dict[str, Any]) -> None:
        # If the config is read from the API, the secret must be verified
        if not conn.read_config_from_api:
            return
        # Get the secret from the post request
        post_secret = msg_json.get("content", {}).get("secret", "")
        secret = conn.config["manager-api"].get("secret", "")
        # If the secret does not match, return
        if post_secret != secret:
            await conn.websocket.send(
                json.dumps(
                    {
                        "type": "server",
                        "status": "error",
                        "message": "Server secret verification failed",
                    }
                )
            )
            return
        # Dynamically update the config
        if msg_json["action"] == "update_config":
            try:
                # Update the WebSocketServer config
                if not conn.server:
                    await conn.websocket.send(
                        json.dumps(
                            {
                                "type": "server",
                                "status": "error",
                                "message": "Unable to get the server instance",
                                "content": {"action": "update_config"},
                            }
                        )
                    )
                    return

                if not await conn.server.update_config():
                    await conn.websocket.send(
                        json.dumps(
                            {
                                "type": "server",
                                "status": "error",
                                "message": "Failed to update server config",
                                "content": {"action": "update_config"},
                            }
                        )
                    )
                    return

                # Send the success response
                await conn.websocket.send(
                    json.dumps(
                        {
                            "type": "server",
                            "status": "success",
                            "message": "Config updated successfully",
                            "content": {"action": "update_config"},
                        }
                    )
                )
            except Exception as e:
                conn.logger.bind(tag=TAG).error(f"Failed to update config: {str(e)}")
                await conn.websocket.send(
                    json.dumps(
                        {
                            "type": "server",
                            "status": "error",
                            "message": f"Failed to update config: {str(e)}",
                            "content": {"action": "update_config"},
                        }
                    )
                )
        # Restart the server
        elif msg_json["action"] == "restart":
            await conn.handle_restart(msg_json)