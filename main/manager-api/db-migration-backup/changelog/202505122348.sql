-- Add the summary memory column
ALTER TABLE `ai_agent`
ADD COLUMN `summary_memory` text COMMENT 'Summary memory' AFTER `system_prompt`;

ALTER TABLE `ai_agent_template`
ADD COLUMN `summary_memory` text COMMENT 'Summary memory' AFTER `system_prompt`;
