ALTER TABLE `ai_tts_voice`
ADD COLUMN `reference_audio` VARCHAR(500) DEFAULT NULL COMMENT 'Reference audio path' AFTER `remark`,
ADD COLUMN `reference_text` VARCHAR(500) DEFAULT NULL COMMENT 'Reference text' AFTER `reference_audio`;
