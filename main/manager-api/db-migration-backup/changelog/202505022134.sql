-- Initialize agent chat history
DROP TABLE IF EXISTS ai_chat_history;
DROP TABLE IF EXISTS ai_chat_message;
DROP TABLE IF EXISTS ai_agent_chat_history;
CREATE TABLE ai_agent_chat_history
(
    id          BIGINT AUTO_INCREMENT COMMENT 'Primary key ID' PRIMARY KEY,
    mac_address VARCHAR(50) COMMENT 'MAC address',
    agent_id VARCHAR(32) COMMENT 'Agent id',
    session_id  VARCHAR(50) COMMENT 'session ID',
    chat_type   TINYINT(3) COMMENT 'Message type: 1-User, 2-Agent',
    content     VARCHAR(1024) COMMENT 'Chat content',
    audio_id    VARCHAR(32) COMMENT 'Audio ID',
    created_at  DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) NOT NULL COMMENT 'Created at',
    updated_at  DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) NOT NULL ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'Updated at',
    INDEX idx_ai_agent_chat_history_mac (mac_address),
    INDEX idx_ai_agent_chat_history_session_id (session_id),
    INDEX idx_ai_agent_chat_history_agent_id (agent_id),
    INDEX idx_ai_agent_chat_history_agent_session_created (agent_id, session_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT 'Agent chat history table';

DROP TABLE IF EXISTS ai_agent_chat_audio;
CREATE TABLE ai_agent_chat_audio
(
    id          VARCHAR(32) COMMENT 'Primary key ID' PRIMARY KEY,
    audio       LONGBLOB COMMENT 'Audio opus Data'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT 'Agent chat audio data table'; 