-- Knowledge base table
DROP TABLE IF EXISTS `ai_rag_dataset`;
CREATE TABLE `ai_rag_dataset` (
    `id` VARCHAR(32) NOT NULL COMMENT 'Unique identifier',
    `dataset_id` VARCHAR(64) NOT NULL COMMENT 'Knowledge base ID',
    `rag_model_id` VARCHAR(64) COMMENT 'RAG model config ID',
    `name` VARCHAR(100) NOT NULL COMMENT 'Knowledge base name',
    `description` TEXT COMMENT 'Knowledge base description',
    `status` TINYINT(1) DEFAULT 1 COMMENT 'Status: 0 disabled, 1 enabled',
    `creator` BIGINT COMMENT 'Creator',
    `created_at` DATETIME COMMENT 'Creation time',
    `updater` BIGINT COMMENT 'Updater',
    `updated_at` DATETIME COMMENT 'Update time',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_dataset_id` (`dataset_id`),
    INDEX `idx_ai_rag_dataset_status` (`status`),
    INDEX `idx_ai_rag_dataset_creator` (`creator`),
    INDEX `idx_ai_rag_dataset_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Knowledge base table';