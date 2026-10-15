import requests
from requests.exceptions import RequestException
from config.logger import setup_logging
from core.providers.llm.base import LLMProviderBase

TAG = __name__
logger = setup_logging()


class LLMProvider(LLMProviderBase):
    def __init__(self, config):
        self.agent_id = config.get("agent_id")  # Corresponds to agent_id
        self.api_key = config.get("api_key")
        self.base_url = config.get("base_url", config.get("url"))  # Use base_url by default
        self.api_url = f"{self.base_url}/api/conversation/process"  # Assemble the full API URL

    def response(self, session_id, dialogue, **kwargs):
        # The home assistant voice assistant has its own intent handling; there is no need to use xiaozhi ai's, just pass what the user said to home assistant

        # Extract the content of the last message whose role is 'user'
        input_text = None
        if isinstance(dialogue, list):  # Make sure dialogue is a list
            # Iterate in reverse to find the last message whose role is 'user'
            for message in reversed(dialogue):
                if message.get("role") == "user":  # Found a message whose role is 'user'
                    input_text = message.get("content", "")
                    break  # Exit the loop immediately once found

        # Build the request data
        payload = {
            "text": input_text,
            "agent_id": self.agent_id,
            "conversation_id": session_id,  # Use session_id as conversation_id
        }
        # Set the request headers
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        # Send the POST request
        with requests.post(self.api_url, json=payload, headers=headers) as response:
            # Check whether the request succeeded
            response.raise_for_status()

            # Parse the response data
            data = response.json()
        speech = (
            data.get("response", {})
            .get("speech", {})
            .get("plain", {})
            .get("speech", "")
        )

        # Return the generated content
        if speech:
            yield speech
        else:
            logger.bind(tag=TAG).warning("No speech content in the API response data")

    def response_with_functions(self, session_id, dialogue, functions=None):
        logger.bind(tag=TAG).error(
            f"homeassistant does not support function call; consider using another intent recognition method"
        )
