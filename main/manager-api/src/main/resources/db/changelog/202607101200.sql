-- liquibase formatted sql

-- changeset tykechen:202607101200
ALTER TABLE `ai_agent_snapshot`
    ADD COLUMN `redaction_version` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Snapshot redaction rule version' AFTER `created_at`,
    ADD INDEX `idx_snapshot_redaction_version_id` (`redaction_version`, `id`);

-- rollback ALTER TABLE `ai_agent_snapshot` DROP INDEX `idx_snapshot_redaction_version_id`, DROP COLUMN `redaction_version`;
