-- Add a new column to the agent voiceprint table
ALTER TABLE ai_agent_voice_print
    ADD COLUMN audio_id VARCHAR(32) NOT NULL COMMENT 'Audio ID';