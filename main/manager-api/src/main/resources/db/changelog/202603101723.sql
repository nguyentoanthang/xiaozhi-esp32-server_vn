-- Add a language field to the voice clone table
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_voice_clone' AND COLUMN_NAME = 'languages');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_voice_clone` ADD COLUMN `languages` VARCHAR(50) DEFAULT NULL COMMENT ''Language'' AFTER `voice_id`', 'SELECT ''Column languages already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
