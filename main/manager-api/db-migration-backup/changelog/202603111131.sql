-- Add the parameters returned by RAGFlow (returned when creating/querying a knowledge base)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_rag_dataset' AND COLUMN_NAME = 'tenant_id');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_rag_dataset` ADD COLUMN `tenant_id` varchar(32) DEFAULT NULL COMMENT ''Tenant ID''', 'SELECT ''Column tenant_id already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_rag_dataset' AND COLUMN_NAME = 'avatar');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_rag_dataset` ADD COLUMN `avatar` text DEFAULT NULL COMMENT ''Knowledge base avatar (Base64)''', 'SELECT ''Column avatar already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_rag_dataset' AND COLUMN_NAME = 'embedding_model');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_rag_dataset` ADD COLUMN `embedding_model` varchar(50) DEFAULT NULL COMMENT ''Embedding model name''', 'SELECT ''Column embedding_model already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_rag_dataset' AND COLUMN_NAME = 'permission');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_rag_dataset` ADD COLUMN `permission` varchar(20) DEFAULT ''me'' COMMENT ''Permission setting: me/team''', 'SELECT ''Column permission already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_rag_dataset' AND COLUMN_NAME = 'chunk_method');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_rag_dataset` ADD COLUMN `chunk_method` varchar(50) DEFAULT NULL COMMENT ''Chunking method''', 'SELECT ''Column chunk_method already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_rag_dataset' AND COLUMN_NAME = 'parser_config');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_rag_dataset` ADD COLUMN `parser_config` text DEFAULT NULL COMMENT ''Parser config (JSON)''', 'SELECT ''Column parser_config already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_rag_dataset' AND COLUMN_NAME = 'chunk_count');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_rag_dataset` ADD COLUMN `chunk_count` bigint(20) DEFAULT 0 COMMENT ''Total chunk count''', 'SELECT ''Column chunk_count already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_rag_dataset' AND COLUMN_NAME = 'document_count');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_rag_dataset` ADD COLUMN `document_count` bigint(20) DEFAULT 0 COMMENT ''Total document count''', 'SELECT ''Column document_count already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_rag_dataset' AND COLUMN_NAME = 'token_num');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_rag_dataset` ADD COLUMN `token_num` bigint(20) DEFAULT 0 COMMENT ''Total token count''', 'SELECT ''Column token_num already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Document table (shadow DB for RAGFlow)
-- Keep a copy of the document ID to link the remote RAGFlow document ID with the local ID (only a backup of the metadata link; the actual file content is still stored in RAGFlow)
DROP TABLE IF EXISTS `ai_rag_knowledge_document`;
CREATE TABLE `ai_rag_knowledge_document` (
     `id` varchar(36) NOT NULL COMMENT 'Local unique ID',
     `dataset_id` varchar(36) NOT NULL COMMENT 'Knowledge base ID (references ai_rag_dataset)',
     `document_id` varchar(64) NOT NULL COMMENT 'RAGFlow document ID (remote ID)',
     `name` varchar(255) DEFAULT NULL COMMENT 'Document name',
     `size` bigint(20) DEFAULT NULL COMMENT 'File size (bytes)',
     `type` varchar(20) DEFAULT NULL COMMENT 'File type',
     `chunk_method` varchar(50) DEFAULT NULL COMMENT 'Chunking method',
     `parser_config` text COMMENT 'Parse config (JSON)',
     `status` varchar(10) DEFAULT '1' COMMENT 'Availability status (1: enabled, 0: disabled)',
     `run` varchar(32) DEFAULT 'UNSTART' COMMENT 'Run status (UNSTART/RUNNING/CANCEL/DONE/FAIL)',
     `progress` double DEFAULT '0' COMMENT 'Parsing progress (0.0 ~ 1.0)',
     `thumbnail` mediumtext COMMENT 'Thumbnail (Base64 or URL)',
     `process_duration` double DEFAULT '0' COMMENT 'Parsing duration (unit: seconds)',
     `meta_fields` text COMMENT 'Custom metadata (JSON)',
     `source_type` varchar(32) DEFAULT 'local' COMMENT 'Source type (local, s3, url, etc.)',
     `error` text COMMENT 'Error message',
     `chunk_count` int(11) DEFAULT '0' COMMENT 'Chunk count',
     `token_count` bigint(20) DEFAULT '0' COMMENT 'Token count',
     `enabled` tinyint(1) DEFAULT '1' COMMENT 'Enabled status',
     `creator` bigint(20) DEFAULT NULL COMMENT 'Creator',
     `created_at` datetime DEFAULT NULL COMMENT 'Creation time',
     `updated_at` datetime DEFAULT NULL COMMENT 'Update time',
     `last_sync_at` datetime DEFAULT NULL COMMENT 'Last sync time',
     PRIMARY KEY (`id`),
     UNIQUE KEY `uk_doc_id` (`document_id`),
     KEY `idx_dataset_id` (`dataset_id`),
     KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Knowledge base document table';