-- liquibase formatted sql

-- changeset xiaozhi:202512041515
CREATE TABLE ai_agent_context_provider (
    id VARCHAR(32) NOT NULL COMMENT 'Primary key',
    agent_id VARCHAR(32) NOT NULL COMMENT 'Agent ID',
    context_providers JSON COMMENT 'Context source config',
    creator BIGINT COMMENT 'Creator',
    created_at DATETIME COMMENT 'Creation time',
    updater BIGINT COMMENT 'Updater',
    updated_at DATETIME COMMENT 'Update time',
    PRIMARY KEY (id),
    INDEX idx_agent_id (agent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Agent context source config table';
