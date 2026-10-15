DROP TABLE IF EXISTS ai_agent_voice_print;
create table ai_agent_voice_print (
  id varchar(32) NOT NULL COMMENT 'Voiceprint ID',
  agent_id varchar(32)  NOT NULL COMMENT 'Linked agent ID',
  source_name varchar(50)  NOT NULL COMMENT 'Name of the person the voiceprint belongs to',
  introduce varchar(200) COMMENT 'Description of the person the voiceprint belongs to',
  create_date DATETIME COMMENT 'Created at',
  creator bigint COMMENT 'Created by',
  update_date DATETIME COMMENT 'Updated at',
  updater bigint COMMENT 'Updated by',
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Agent voiceprint table'