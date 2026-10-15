-- Voice clone table
DROP TABLE IF EXISTS `ai_voice_clone`;
CREATE TABLE `ai_voice_clone` (
    `id` VARCHAR(32) NOT NULL COMMENT 'Unique identifier',
    `name` VARCHAR(64) COMMENT 'Voice name',
    `model_id` VARCHAR(32) COMMENT 'Model ID',
    `voice_id` VARCHAR(32) COMMENT 'Voice ID',
    `user_id` BIGINT COMMENT 'User ID (references the user table)',
    `voice` LONGBLOB COMMENT 'Voice',
    `train_status` TINYINT(1) DEFAULT 0 COMMENT 'Training status: 0 pending, 1 training, 2 succeeded, 3 failed',
    `train_error` VARCHAR(255) COMMENT 'Training error reason',
    `creator` BIGINT COMMENT 'Creator ID',
    `create_date` DATETIME COMMENT 'Creation time',
    PRIMARY KEY (`id`),
    INDEX idx_ai_voice_clone_user_id_model_id_train_status (model_id,user_id, train_status),
    INDEX idx_ai_voice_clone_voice_id (voice_id),
    INDEX idx_ai_voice_clone_user_id (user_id),
    INDEX idx_ai_voice_clone_model_id_voice_id (model_id, voice_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Voice clone table';