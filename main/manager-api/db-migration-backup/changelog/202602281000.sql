-- Tag table
CREATE TABLE IF NOT EXISTS ai_agent_tag (
    id VARCHAR(32) NOT NULL COMMENT 'Primary key',
    tag_name VARCHAR(64) NOT NULL COMMENT 'Tag name',
    sort INT UNSIGNED DEFAULT 0 COMMENT 'Sort order',
    creator BIGINT COMMENT 'Creator',
    created_at DATETIME COMMENT 'Creation time',
    updater BIGINT COMMENT 'Updater',
    updated_at DATETIME COMMENT 'Update time',
    deleted TINYINT DEFAULT 0 COMMENT 'Deletion flag',
    PRIMARY KEY (id),
    UNIQUE KEY uk_tag_name (tag_name),
    INDEX idx_sort (sort)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Agent tag table';

-- Agent tag relation table
CREATE TABLE IF NOT EXISTS ai_agent_tag_relation (
    id VARCHAR(32) NOT NULL COMMENT 'Primary key',
    agent_id VARCHAR(32) NOT NULL COMMENT 'Agent ID',
    tag_id VARCHAR(32) NOT NULL COMMENT 'Tag ID',
    creator BIGINT COMMENT 'Creator',
    created_at DATETIME COMMENT 'Creation time',
    updater BIGINT COMMENT 'Updater',
    updated_at DATETIME COMMENT 'Update time',
    PRIMARY KEY (id),
    UNIQUE KEY uk_agent_tag (agent_id, tag_id),
    INDEX idx_agent_id (agent_id),
    INDEX idx_tag_id (tag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Agent tag relation table';
