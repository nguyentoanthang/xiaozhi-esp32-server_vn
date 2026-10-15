from abc import ABC, abstractmethod
from typing import List, Dict
from config.logger import setup_logging

TAG = __name__
logger = setup_logging()


class IntentProviderBase(ABC):
    def __init__(self, config):
        self.config = config

    def set_llm(self, llm):
        self.llm = llm
        # Get model name and type info
        model_name = getattr(llm, "model_name", str(llm.__class__.__name__))
        # Log more detail
        logger.bind(tag=TAG).info(f"Intent recognition LLM set: {model_name}")

    @abstractmethod
    async def detect_intent(self, conn, dialogue_history: List[Dict], text: str) -> str:
        """
        Detect the intent of the user's last utterance
        Args:
            dialogue_history: list of dialogue history records, each containing role and content
        Returns:
            the recognized intent, in the format:
            - "Continue chatting"
            - "End chatting"
            - "Play music <song name>" or "Play random music"
            - "Query weather <location>" or "Query weather [current location]"
        """
        pass
