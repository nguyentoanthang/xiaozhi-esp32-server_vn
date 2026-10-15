-- Add a sort field to the agent tag relation table
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent_tag_relation' AND COLUMN_NAME = 'sort');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_agent_tag_relation` ADD COLUMN `sort` INT UNSIGNED DEFAULT 0 COMMENT ''Sort order''', 'SELECT ''Column sort already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Fix existing data (only runs when the sort field has the default value 0, to avoid overwriting orders already set by users)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent_tag_relation' AND COLUMN_NAME = 'sort');
SET @sql = IF(@col_exists > 0 AND (SELECT COUNT(*) FROM ai_agent_tag_relation WHERE sort = 0) > 0, 
    'UPDATE ai_agent_tag_relation r INNER JOIN (SELECT id, ROW_NUMBER() OVER (PARTITION BY agent_id ORDER BY created_at) AS row_num FROM ai_agent_tag_relation) t ON r.id = t.id SET r.sort = t.row_num', 
    'SELECT ''No need to update or column does not exist'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
