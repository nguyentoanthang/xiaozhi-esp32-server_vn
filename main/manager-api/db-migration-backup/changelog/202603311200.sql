-- Change the chat content column type
ALTER TABLE ai_agent_chat_history MODIFY COLUMN content TEXT COMMENT 'Chat content';
