-- Rename the memory models

UPDATE `ai_model_config` SET `model_name` = 'Local short-term memory (summarized memory)' WHERE `id` = 'Memory_mem_local_short';
UPDATE `ai_model_provider` SET `name` = 'Local short-term memory (summarized memory)' WHERE `id` = 'SYSTEM_Memory_mem_local_short';

UPDATE `ai_model_config` SET `model_name` = 'Report chat history only (no memory summarization)' WHERE `id` = 'Memory_mem_report_only';
UPDATE `ai_model_provider` SET `name` = 'Report chat history only (no memory summarization)' WHERE `id` = 'SYSTEM_Memory_mem_report_only';
