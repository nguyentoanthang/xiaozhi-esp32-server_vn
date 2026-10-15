-- Add the chat history configuration column
ALTER TABLE `ai_agent` 
ADD COLUMN `chat_history_conf` tinyint NOT NULL DEFAULT 0 COMMENT 'Chat history configuration (0 Do not record 1 Text only 2 record text and voice)' AFTER `system_prompt`;

ALTER TABLE `ai_agent_template` 
ADD COLUMN `chat_history_conf` tinyint NOT NULL DEFAULT 0 COMMENT 'Chat history configuration (0 Do not record 1 Text only 2 record text and voice)' AFTER `system_prompt`;