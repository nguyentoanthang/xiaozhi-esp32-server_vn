import uuid
import re
from typing import List, Dict
from datetime import datetime


class Message:
    def __init__(
            self,
            role: str,
            content: str = None,
            uniq_id: str = None,
            tool_calls=None,
            tool_call_id=None,
            is_temporary=False,
    ):
        self.uniq_id = uniq_id if uniq_id is not None else str(uuid.uuid4())
        self.role = role
        self.content = content
        self.tool_calls = tool_calls
        self.tool_call_id = tool_call_id
        self.is_temporary = is_temporary  # Marks temporary messages (e.g. tool-call reminders)


class Dialogue:
    def __init__(self):
        self.dialogue: List[Message] = []
        # Get the current time
        self.current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    def put(self, message: Message):
        self.dialogue.append(message)

    def getMessages(self, m, dialogue):
        if m.tool_calls is not None:
            dialogue.append({"role": m.role, "tool_calls": m.tool_calls})
        elif m.role == "tool":
            dialogue.append(
                {
                    "role": m.role,
                    "tool_call_id": (
                        str(uuid.uuid4()) if m.tool_call_id is None else m.tool_call_id
                    ),
                    "content": m.content,
                }
            )
        else:
            dialogue.append({"role": m.role, "content": m.content})

    def get_llm_dialogue(self) -> List[Dict[str, str]]:
        # Call get_llm_dialogue_with_memory directly, passing None as memory_str
        # This ensures the speaker feature works on every call path
        return self.get_llm_dialogue_with_memory(None)

    def update_system_message(self, new_content: str):
        """Update or add the system message"""
        # Find the first system message
        system_msg = next((msg for msg in self.dialogue if msg.role == "system"), None)
        if system_msg:
            system_msg.content = new_content
        else:
            self.put(Message(role="system", content=new_content))

    def _ensure_tool_calls_complete(self, messages: List[Message]) -> List[Message]:
        """
        Ensure every tool_calls entry has a matching tool response
        Fix dangling tool_calls caused by interruptions, to prevent the LLM API from returning a 400 error
        """
        pending_tool_calls = set()
        result = []

        for msg in messages:
            result.append(msg)

            if msg.role == "assistant" and msg.tool_calls:
                for tc in msg.tool_calls:
                    tc_id = tc.get("id") if isinstance(tc, dict) else getattr(tc, "id", None)
                    if tc_id:
                        pending_tool_calls.add(tc_id)

            elif msg.role == "tool" and msg.tool_call_id:
                pending_tool_calls.discard(msg.tool_call_id)

        for missing_id in pending_tool_calls:
            dummy_tool_msg = Message(
                role="tool",
                content='{"status": "interrupted", "message": "Action cancelled/interrupted"}',
                tool_call_id=missing_id
            )
            result.append(dummy_tool_msg)

        return result

    def get_llm_dialogue_with_memory(
            self, memory_str: str = None,
    ) -> List[Dict[str, str]]:
        # Build the dialogue
        dialogue = []

        # Add the system prompt and memory
        system_message = next(
            (msg for msg in self.dialogue if msg.role == "system"), None
        )

        if system_message:
            full_prompt = system_message.content

            # Replace the time placeholder
            full_prompt = full_prompt.replace(
                "{{current_time}}", datetime.now().strftime("%H:%M")
            )

            # Fill in memory
            if memory_str is not None:
                full_prompt = re.sub(
                    r"<memory>.*?</memory>",
                    f"<memory>\n{memory_str}\n</memory>",
                    full_prompt,
                    flags=re.DOTALL,
                )

            dialogue.append({"role": "system", "content": full_prompt})

        # Part 2: few-shot examples (unchanged within the session)
        non_system_messages = [m for m in self.dialogue if m.role != "system"]
        fewshot_messages = [m for m in non_system_messages if m.is_temporary]
        complete_fewshot = self._ensure_tool_calls_complete(fewshot_messages)
        for m in complete_fewshot:
            self.getMessages(m, dialogue)

        # Part 3: actual dialogue history (excluding few-shot)
        actual_messages = [m for m in non_system_messages if not m.is_temporary]
        complete_actual = self._ensure_tool_calls_complete(actual_messages)
        for m in complete_actual:
            self.getMessages(m, dialogue)

        return dialogue
