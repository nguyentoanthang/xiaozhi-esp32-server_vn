import json
from typing import Dict, Any

from core.handle.textMessageHandler import TextMessageHandler
from core.handle.textMessageType import TextMessageType

TAG = __name__


class ServerTextMessageHandler(TextMessageHandler):
    """Server message handler.

    The "update_config" and "restart" actions used to be sent by the Java manager-api, verified
    with its shared secret. That backend no longer exists and there is no other trusted sender
    (the WebSocket is open to devices), so these messages are refused. Config edits in SQLite
    apply to the next connection; the shared VAD/ASR/LLM instances need a restart.
    """

    @property
    def message_type(self) -> TextMessageType:
        return TextMessageType.SERVER

    async def handle(self, conn, msg_json: Dict[str, Any]) -> None:
        action = msg_json.get("action")
        conn.logger.bind(tag=TAG).warning(f"Ignoring server message (action={action}): not supported")
        await conn.websocket.send(
            json.dumps(
                {
                    "type": "server",
                    "status": "error",
                    "message": "Server messages are not supported",
                    "content": {"action": action},
                }
            )
        )
