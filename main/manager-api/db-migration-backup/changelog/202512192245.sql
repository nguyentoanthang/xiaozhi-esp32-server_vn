-- Add an audio ID index to the agent chat history
ALTER TABLE ai_agent_chat_history ADD INDEX idx_ai_agent_chat_history_audio_id (audio_id);
