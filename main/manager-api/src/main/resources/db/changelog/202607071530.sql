-- liquibase formatted sql

-- changeset tykechen:202607071530
CREATE TABLE IF NOT EXISTS `ai_agent_snapshot` (
    `id` VARCHAR(32) NOT NULL COMMENT 'Snapshot ID',
    `agent_id` VARCHAR(32) NOT NULL COMMENT 'Agent ID',
    `user_id` BIGINT DEFAULT NULL COMMENT 'Owning user ID',
    `version_no` INT UNSIGNED NOT NULL COMMENT 'Version number',
    `snapshot_data` JSON NOT NULL DEFAULT (JSON_OBJECT()) COMMENT 'Snapshot data',
    `changed_fields` JSON DEFAULT NULL COMMENT 'Changed fields',
    `source` VARCHAR(32) DEFAULT 'config' COMMENT 'Snapshot source',
    `restore_from_snapshot_id` VARCHAR(32) DEFAULT NULL COMMENT 'Restore-source snapshot ID',
    `restore_from_version_no` INT UNSIGNED DEFAULT NULL COMMENT 'Restore-source version number',
    `creator` BIGINT DEFAULT NULL COMMENT 'Creator',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_agent_version` (`agent_id`, `version_no`),
    INDEX `idx_agent_created_at` (`agent_id`, `created_at`),
    INDEX `idx_snapshot_user_created_at` (`user_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Agent config snapshot table';
