-- Baseline schema + seed data for the fresh custom install.
-- Merged from the original 108 changelog files (order = original master), see db-migration-backup/.
-- Add new schema changes as NEW changesets (new file + new entry in db.changelog-master.yaml).

-- ===== begin 202503141335.sql =====
DROP TABLE IF EXISTS sys_user;
DROP TABLE IF EXISTS sys_params;
DROP TABLE IF EXISTS sys_user_token;
DROP TABLE IF EXISTS sys_dict_type;
DROP TABLE IF EXISTS sys_dict_data;

-- System user
CREATE TABLE sys_user (
  id bigint NOT NULL COMMENT 'id',
  username varchar(50) NOT NULL COMMENT 'Username',
  password varchar(100) COMMENT 'Password',
  super_admin tinyint unsigned COMMENT 'Super admin   0: No   1: Yes',
  status tinyint COMMENT 'Status  0: Disabled   1: Normal',
  create_date datetime COMMENT 'Created at',
  updater bigint COMMENT 'Updated by',
  creator bigint COMMENT 'Created by',
  update_date datetime COMMENT 'Updated at',
  primary key (id),
  unique key uk_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='System user';

-- System user Token
CREATE TABLE sys_user_token (
  id bigint NOT NULL COMMENT 'id',
  user_id bigint NOT NULL COMMENT 'User id',
  token varchar(100) NOT NULL COMMENT 'User token',
  expire_date datetime COMMENT 'Expires at',
  update_date datetime COMMENT 'Updated at',
  create_date datetime COMMENT 'Created at',
  PRIMARY KEY (id),
  UNIQUE KEY user_id (user_id),
  UNIQUE KEY token (token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='System user Token';

-- Parameter management
create table sys_params
(
  id                   bigint NOT NULL COMMENT 'id',
  param_code           varchar(32) COMMENT 'Parameter code',
  param_value          varchar(2000) COMMENT 'Parameter value',
  param_type           tinyint unsigned default 1 COMMENT 'Type   0: System parameter   1: Non-system parameter',
  remark               varchar(200) COMMENT 'Remarks',
  creator              bigint COMMENT 'Created by',
  create_date          datetime COMMENT 'Created at',
  updater              bigint COMMENT 'Updated by',
  update_date          datetime COMMENT 'Updated at',
  primary key (id),
  unique key uk_param_code (param_code)
)ENGINE=InnoDB DEFAULT CHARACTER SET utf8mb4 COMMENT='Parameter management';

-- Dictionary type
create table sys_dict_type
(
    id                   bigint NOT NULL COMMENT 'id',
    dict_type            varchar(100) NOT NULL COMMENT 'Dictionary type',
    dict_name            varchar(255) NOT NULL COMMENT 'Dictionary name',
    remark               varchar(255) COMMENT 'Remarks',
    sort                 int unsigned COMMENT 'Sort',
    creator              bigint COMMENT 'Created by',
    create_date          datetime COMMENT 'Created at',
    updater              bigint COMMENT 'Updated by',
    update_date          datetime COMMENT 'Updated at',
    primary key (id),
    UNIQUE KEY(dict_type)
)ENGINE=InnoDB DEFAULT CHARACTER SET utf8mb4 COMMENT='Dictionary type';

-- Dictionary data
create table sys_dict_data
(
    id                   bigint NOT NULL COMMENT 'id',
    dict_type_id         bigint NOT NULL COMMENT 'Dictionary type ID',
    dict_label           varchar(255) NOT NULL COMMENT 'Dictionary label',
    dict_value           varchar(255) COMMENT 'Dictionary value',
    remark               varchar(255) COMMENT 'Remarks',
    sort                 int unsigned COMMENT 'Sort',
    creator              bigint COMMENT 'Created by',
    create_date          datetime COMMENT 'Created at',
    updater              bigint COMMENT 'Updated by',
    update_date          datetime COMMENT 'Updated at',
    primary key (id),
    unique key uk_dict_type_value (dict_type_id, dict_value),
    key idx_sort (sort)
)ENGINE=InnoDB DEFAULT CHARACTER SET utf8mb4 COMMENT='Dictionary data';
-- ===== end 202503141335.sql =====

-- ===== begin 202503141346.sql =====
-- Model provider table
DROP TABLE IF EXISTS `ai_model_provider`;
CREATE TABLE `ai_model_provider` (
    `id` VARCHAR(32) NOT NULL COMMENT 'Primary key',
    `model_type` VARCHAR(20) COMMENT 'Model type (Memory/ASR/VAD/LLM/TTS)',
    `provider_code` VARCHAR(50) COMMENT 'Provider type',
    `name` VARCHAR(50) COMMENT 'Provider name',
    `fields` JSON COMMENT 'Provider field list (JSON Format)',
    `sort` INT UNSIGNED DEFAULT 0 COMMENT 'Sort',
    `creator` BIGINT COMMENT 'Created by',
    `create_date` DATETIME COMMENT 'Created at',
    `updater` BIGINT COMMENT 'Updated by',
    `update_date` DATETIME COMMENT 'Updated at',
    PRIMARY KEY (`id`),
    INDEX `idx_ai_model_provider_model_type` (`model_type`) COMMENT 'Index on the model type, used to quickly look up all providers of a given type'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Model configuration table';

-- Model configuration table
DROP TABLE IF EXISTS `ai_model_config`;
CREATE TABLE `ai_model_config` (
    `id` VARCHAR(32) NOT NULL COMMENT 'Primary key',
    `model_type` VARCHAR(20) COMMENT 'Model type (Memory/ASR/VAD/LLM/TTS)',
    `model_code` VARCHAR(50) COMMENT 'Model code (e.g. AliLLM, DoubaoTTS)',
    `model_name` VARCHAR(50) COMMENT 'Model name',
    `is_default` TINYINT(1) DEFAULT 0 COMMENT 'Whether default configuration (0 No 1 Yes)',
    `is_enabled` TINYINT(1) DEFAULT 0 COMMENT 'Enabled',
    `config_json` JSON COMMENT 'Model configuration (JSON Format)',
    `doc_link` VARCHAR(200) COMMENT 'Official documentation link',
    `remark` VARCHAR(255) COMMENT 'Remarks',
    `sort` INT UNSIGNED DEFAULT 0 COMMENT 'Sort',
    `creator` BIGINT COMMENT 'Created by',
    `create_date` DATETIME COMMENT 'Created at',
    `updater` BIGINT COMMENT 'Updated by',
    `update_date` DATETIME COMMENT 'Updated at',
    PRIMARY KEY (`id`),
    INDEX `idx_ai_model_config_model_type` (`model_type`) COMMENT 'Index on the model type, used to quickly look up all configurations of a given type'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Model configuration table';

-- TTS Voice table
DROP TABLE IF EXISTS `ai_tts_voice`;
CREATE TABLE `ai_tts_voice` (
    `id` VARCHAR(32) NOT NULL COMMENT 'Primary key',
    `tts_model_id` VARCHAR(32) COMMENT 'Corresponding TTS Model primary key',
    `name` VARCHAR(20) COMMENT 'Voice name',
    `tts_voice` VARCHAR(50) COMMENT 'Voice code',
    `languages` VARCHAR(50) COMMENT 'Language',
    `voice_demo` VARCHAR(500) DEFAULT NULL COMMENT 'Voice Demo',
    `remark` VARCHAR(255) COMMENT 'Remarks',
    `sort` INT UNSIGNED DEFAULT 0 COMMENT 'Sort',
    `creator` BIGINT COMMENT 'Created by',
    `create_date` DATETIME COMMENT 'Created at',
    `updater` BIGINT COMMENT 'Updated by',
    `update_date` DATETIME COMMENT 'Updated at',
    PRIMARY KEY (`id`),
    INDEX `idx_ai_tts_voice_tts_model_id` (`tts_model_id`) COMMENT 'Create TTS model primary key index, used to quickly look up the voices of the corresponding model'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='TTS Voice table';

-- Agent configuration template table
DROP TABLE IF EXISTS `ai_agent_template`;
CREATE TABLE `ai_agent_template` (
    `id` VARCHAR(32) NOT NULL COMMENT 'Agent unique ID',
    `agent_code` VARCHAR(36) COMMENT 'Agent code',
    `agent_name` VARCHAR(64) COMMENT 'Agent name',
    `asr_model_id` VARCHAR(32) COMMENT 'Speech recognition model ID',
    `vad_model_id` VARCHAR(64) COMMENT 'Voice activity detection ID',
    `llm_model_id` VARCHAR(32) COMMENT 'LLM model ID',
    `tts_model_id` VARCHAR(32) COMMENT 'Speech synthesis model ID',
    `tts_voice_id` VARCHAR(32) COMMENT 'Voice ID',
    `mem_model_id` VARCHAR(32) COMMENT 'Memory model ID',
    `intent_model_id` VARCHAR(32) COMMENT 'Intent model ID',
    `system_prompt` TEXT COMMENT 'Role setting parameter',
    `lang_code` VARCHAR(10) COMMENT 'Language code',
    `language` VARCHAR(10) COMMENT 'Interaction language',
    `sort` INT UNSIGNED DEFAULT 0 COMMENT 'Sort weight',
    `creator` BIGINT COMMENT 'Created by ID',
    `created_at` DATETIME COMMENT 'Created at',
    `updater` BIGINT COMMENT 'Updated by ID',
    `updated_at` DATETIME COMMENT 'Updated at',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Agent configuration template table';

-- Agent configuration table
DROP TABLE IF EXISTS `ai_agent`;
CREATE TABLE `ai_agent` (
    `id` VARCHAR(32) NOT NULL COMMENT 'Agent unique ID',
    `user_id` BIGINT COMMENT 'Owner user ID',
    `agent_code` VARCHAR(36) COMMENT 'Agent code',
    `agent_name` VARCHAR(64) COMMENT 'Agent name',
    `asr_model_id` VARCHAR(32) COMMENT 'Speech recognition model ID',
    `vad_model_id` VARCHAR(64) COMMENT 'Voice activity detection ID',
    `llm_model_id` VARCHAR(32) COMMENT 'LLM model ID',
    `tts_model_id` VARCHAR(32) COMMENT 'Speech synthesis model ID',
    `tts_voice_id` VARCHAR(32) COMMENT 'Voice ID',
    `mem_model_id` VARCHAR(32) COMMENT 'Memory model ID',
    `intent_model_id` VARCHAR(32) COMMENT 'Intent model ID',
    `system_prompt` TEXT COMMENT 'Role setting parameter',
    `lang_code` VARCHAR(10) COMMENT 'Language code',
    `language` VARCHAR(10) COMMENT 'Interaction language',
    `sort` INT UNSIGNED DEFAULT 0 COMMENT 'Sort weight',
    `creator` BIGINT COMMENT 'Created by ID',
    `created_at` DATETIME COMMENT 'Created at',
    `updater` BIGINT COMMENT 'Updated by ID',
    `updated_at` DATETIME COMMENT 'Updated at',
    PRIMARY KEY (`id`),
    INDEX `idx_ai_agent_user_id` (`user_id`) COMMENT 'Index on the user, used to quickly look up the agents of a user'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Agent configuration table';

-- Device information table
DROP TABLE IF EXISTS `ai_device`;
CREATE TABLE `ai_device` (
    `id` VARCHAR(32) NOT NULL COMMENT 'Device unique ID',
    `user_id` BIGINT COMMENT 'Linked user ID',
    `mac_address` VARCHAR(50) COMMENT 'MAC address',
    `last_connected_at` DATETIME COMMENT 'Last connected at',
    `auto_update` TINYINT UNSIGNED DEFAULT 0 COMMENT 'Auto-update switch (0 Off/1 On)',
    `board` VARCHAR(50) COMMENT 'Device hardware model',
    `alias` VARCHAR(64) DEFAULT NULL COMMENT 'Device alias',
    `agent_id` VARCHAR(32) COMMENT 'Agent ID',
    `app_version` VARCHAR(20) COMMENT 'Firmware version',
    `sort` INT UNSIGNED DEFAULT 0 COMMENT 'Sort',
    `creator` BIGINT COMMENT 'Created by',
    `create_date` DATETIME COMMENT 'Created at',
    `updater` BIGINT COMMENT 'Updated by',
    `update_date` DATETIME COMMENT 'Updated at',
    PRIMARY KEY (`id`),
    INDEX `idx_ai_device_created_at` (`mac_address`) COMMENT 'Create mac index, used to quickly look up device information'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Device information table';

-- Voiceprint recognition table
DROP TABLE IF EXISTS `ai_voiceprint`;
CREATE TABLE `ai_voiceprint` (
    `id` VARCHAR(32) NOT NULL COMMENT 'Voiceprint unique ID',
    `name` VARCHAR(64) COMMENT 'Voiceprint name',
    `user_id` BIGINT COMMENT 'User ID (linked to the user table)',
    `agent_id` VARCHAR(32) COMMENT 'Linked agent ID',
    `agent_code` VARCHAR(36) COMMENT 'Linked agent code',
    `agent_name` VARCHAR(36) COMMENT 'Linked agent name',
    `description` VARCHAR(255) COMMENT 'Voiceprint description',
    `embedding` LONGTEXT COMMENT 'Voiceprint feature vector (JSON array format)',
    `memory` TEXT COMMENT 'Linked memory data',
    `sort` INT UNSIGNED DEFAULT 0 COMMENT 'Sort weight',
    `creator` BIGINT COMMENT 'Created by ID',
    `created_at` DATETIME COMMENT 'Created at',
    `updater` BIGINT COMMENT 'Updated by ID',
    `updated_at` DATETIME COMMENT 'Updated at',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Voiceprint recognition table';

-- Conversation history table
DROP TABLE IF EXISTS `ai_chat_history`;
CREATE TABLE `ai_chat_history` (
    `id` VARCHAR(32) NOT NULL COMMENT 'Conversation ID',
    `user_id` BIGINT COMMENT 'User ID',
    `agent_id` VARCHAR(32) DEFAULT NULL COMMENT 'Chat role',
    `device_id` VARCHAR(32) DEFAULT NULL COMMENT 'Device ID',
    `message_count` INT COMMENT 'Message count',
    `creator` BIGINT COMMENT 'Created by',
    `create_date` DATETIME COMMENT 'Created at',
    `updater` BIGINT COMMENT 'Updated by',
    `update_date` DATETIME COMMENT 'Updated at',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Conversation history table';

-- Conversation message table
DROP TABLE IF EXISTS `ai_chat_message`;
CREATE TABLE `ai_chat_message` (
    `id` VARCHAR(32) NOT NULL COMMENT 'Conversation record unique ID',
    `user_id` BIGINT COMMENT 'User unique ID',
    `chat_id` VARCHAR(64) COMMENT 'Conversation history ID',
    `role` ENUM('user', 'assistant') COMMENT 'Role (user or assistant)',
    `content` TEXT COMMENT 'Conversation content',
    `prompt_tokens` INT UNSIGNED DEFAULT 0 COMMENT 'Prompt tokens',
    `total_tokens` INT UNSIGNED DEFAULT 0 COMMENT 'Total tokens',
    `completion_tokens` INT UNSIGNED DEFAULT 0 COMMENT 'Completion tokens',
    `prompt_ms` INT UNSIGNED DEFAULT 0 COMMENT 'Prompt time (ms)',
    `total_ms` INT UNSIGNED DEFAULT 0 COMMENT 'Total time (ms)',
    `completion_ms` INT UNSIGNED DEFAULT 0 COMMENT 'Completion time (ms)',
    `creator` BIGINT COMMENT 'Created by',
    `create_date` DATETIME COMMENT 'Created at',
    `updater` BIGINT COMMENT 'Updated by',
    `update_date` DATETIME COMMENT 'Updated at',
    PRIMARY KEY (`id`),
    INDEX `idx_ai_chat_message_user_id_chat_id_role` (`user_id`, `chat_id`) COMMENT 'User ID, chat session ID and role, used to quickly retrieve conversation records',
    INDEX `idx_ai_chat_message_created_at` (`create_date`) COMMENT 'Index on the creation time, used to sort or retrieve conversation records by time'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Conversation message table';
-- ===== end 202503141346.sql =====

-- ===== begin 202504082211.sql =====
-- This file initializes the model provider data. It does not need to be run manually; it runs automatically when the project starts
-- --------------------------------------------------------
-- Initialize model provider data
DELETE FROM `ai_model_provider`;
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
-- VAD Model provider
('SYSTEM_VAD_SileroVAD', 'VAD', 'silero', 'SileroVAD Voice activity detection', '[{"key":"threshold","label":"Detection threshold","type":"number"},{"key":"model_dir","label":"Model directory","type":"string"},{"key":"min_silence_duration_ms","label":"Min silence duration","type":"number"}]', 1, 1, NOW(), 1, NOW()),

-- ASR Model provider
('SYSTEM_ASR_FunASR', 'ASR', 'fun_local', 'FunASR speech recognition', '[{"key":"model_dir","label":"Model directory","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]', 1, 1, NOW(), 1, NOW()),
('SYSTEM_ASR_SherpaASR', 'ASR', 'sherpa_onnx_local', 'SherpaASR speech recognition', '[{"key":"model_dir","label":"Model directory","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]', 2, 1, NOW(), 1, NOW()),
('SYSTEM_ASR_DoubaoASR', 'ASR', 'doubao', 'Volcano Engine speech recognition', '[{"key":"appid","label":"App ID","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"cluster","label":"Cluster","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]', 3, 1, NOW(), 1, NOW()),

-- LLM Model provider
('SYSTEM_LLM_openai', 'LLM', 'openai', 'OpenAI interface', '[{"key":"base_url","label":"Base URL","type":"string"},{"key":"model_name","label":"Model name","type":"string"},{"key":"api_key","label":"API key","type":"string"},{"key":"temperature","label":"Temperature","type":"number"},{"key":"max_tokens","label":"Max tokens","type":"number"},{"key":"top_p","label":"top_p value","type":"number"},{"key":"top_k","label":"top_k value","type":"number"},{"key":"frequency_penalty","label":"Frequency penalty","type":"number"}]', 1, 1, NOW(), 1, NOW()),
('SYSTEM_LLM_AliBL', 'LLM', 'AliBL', 'Alibaba Bailian interface', '[{"key":"base_url","label":"Base URL","type":"string"},{"key":"app_id","label":"App ID","type":"string"},{"key":"api_key","label":"API key","type":"string"},{"key":"is_no_prompt","label":"Whether not to use local prompt","type":"boolean"},{"key":"ali_memory_id","label":"Memory ID","type":"string"}]', 2, 1, NOW(), 1, NOW()),
('SYSTEM_LLM_ollama', 'LLM', 'ollama', 'Ollama interface', '[{"key":"model_name","label":"Model name","type":"string"},{"key":"base_url","label":"Service address","type":"string"}]', 3, 1, NOW(), 1, NOW()),
('SYSTEM_LLM_dify', 'LLM', 'dify', 'Dify interface', '[{"key":"base_url","label":"Base URL","type":"string"},{"key":"api_key","label":"API key","type":"string"},{"key":"mode","label":"Conversation mode","type":"string"}]', 4, 1, NOW(), 1, NOW()),
('SYSTEM_LLM_gemini', 'LLM', 'gemini', 'Gemini interface', '[{"key":"api_key","label":"API key","type":"string"},{"key":"model_name","label":"Model name","type":"string"},{"key":"http_proxy","label":"HTTP proxy","type":"string"},{"key":"https_proxy","label":"HTTPS proxy","type":"string"}]', 5, 1, NOW(), 1, NOW()),
('SYSTEM_LLM_coze', 'LLM', 'coze', 'Coze interface', '[{"key":"bot_id","label":"Bot ID","type":"string"},{"key":"user_id","label":"User ID","type":"string"},{"key":"personal_access_token","label":"Personal access token","type":"string"}]', 6, 1, NOW(), 1, NOW()),
('SYSTEM_LLM_fastgpt', 'LLM', 'fastgpt', 'FastGPT interface', '[{"key":"base_url","label":"Base URL","type":"string"},{"key":"api_key","label":"API key","type":"string"},{"key":"variables","label":"Variables","type":"dict","dict_name":"variables"}]', 7, 1, NOW(), 1, NOW()),
('SYSTEM_LLM_xinference', 'LLM', 'xinference', 'Xinference interface', '[{"key":"model_name","label":"Model name","type":"string"},{"key":"base_url","label":"Service address","type":"string"}]', 8, 1, NOW(), 1, NOW()),
('SYSTEM_LLM_doubao', 'LLM', 'doubao', 'Volcano Engine LLM', '[{"key":"base_url","label":"Base URL","type":"string"},{"key":"model_name","label":"Model name","type":"string"},{"key":"api_key","label":"API key","type":"string"}]', 9, 1, NOW(), 1, NOW()),
('SYSTEM_LLM_chatglm', 'LLM', 'chatglm', 'ChatGLM interface', '[{"key":"model_name","label":"Model name","type":"string"},{"key":"url","label":"Service address","type":"string"},{"key":"api_key","label":"API key","type":"string"}]', 10, 1, NOW(), 1, NOW()),

-- TTS Model provider
('SYSTEM_TTS_edge', 'TTS', 'edge', 'Edge TTS', '[{"key":"voice","label":"Voice","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]', 1, 1, NOW(), 1, NOW()),
('SYSTEM_TTS_doubao', 'TTS', 'doubao', 'Volcano Engine TTS', '[{"key":"api_url","label":"API address","type":"string"},{"key":"voice","label":"Voice","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"authorization","label":"Authorization","type":"string"},{"key":"appid","label":"App ID","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"cluster","label":"Cluster","type":"string"}]', 2, 1, NOW(), 1, NOW()),
('SYSTEM_TTS_siliconflow', 'TTS', 'siliconflow', 'SiliconFlow TTS', '[{"key":"model","label":"Model","type":"string"},{"key":"voice","label":"Voice","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"response_format","label":"Response format","type":"string"}]', 3, 1, NOW(), 1, NOW()),
('SYSTEM_TTS_cozecn', 'TTS', 'cozecn', 'COZECN TTS', '[{"key":"voice","label":"Voice","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"response_format","label":"Response format","type":"string"}]', 4, 1, NOW(), 1, NOW()),
('SYSTEM_TTS_fishspeech', 'TTS', 'fishspeech', 'FishSpeech TTS', '[{"key":"output_dir","label":"Output directory","type":"string"},{"key":"response_format","label":"Response format","type":"string"},{"key":"reference_id","label":"Reference ID","type":"string"},{"key":"reference_audio","label":"Reference audio","type":"dict","dict_name":"reference_audio"},{"key":"reference_text","label":"Reference text","type":"dict","dict_name":"reference_text"},{"key":"normalize","label":"Whether to normalize","type":"boolean"},{"key":"max_new_tokens","label":"Max new tokens","type":"number"},{"key":"chunk_length","label":"Chunk length","type":"number"},{"key":"top_p","label":"top_p value","type":"number"},{"key":"repetition_penalty","label":"Repetition penalty","type":"number"},{"key":"temperature","label":"Temperature","type":"number"},{"key":"streaming","label":"Whether streaming","type":"boolean"},{"key":"use_memory_cache","label":"Whether to use memory cache","type":"string"},{"key":"seed","label":"Seed","type":"number"},{"key":"channels","label":"Channels","type":"number"},{"key":"rate","label":"Sample rate","type":"number"},{"key":"api_key","label":"API key","type":"string"},{"key":"api_url","label":"API address","type":"string"}]', 5, 1, NOW(), 1, NOW()),
('SYSTEM_TTS_gpt_sovits_v2', 'TTS', 'gpt_sovits_v2', 'GPT-SoVITS V2', '[{"key":"url","label":"Service address","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"text_lang","label":"Text language","type":"string"},{"key":"ref_audio_path","label":"Reference audio path","type":"string"},{"key":"prompt_text","label":"Prompt text","type":"string"},{"key":"prompt_lang","label":"Prompt language","type":"string"},{"key":"top_k","label":"top_k value","type":"number"},{"key":"top_p","label":"top_p value","type":"number"},{"key":"temperature","label":"Temperature","type":"number"},{"key":"text_split_method","label":"Text splitting method","type":"string"},{"key":"batch_size","label":"Batch size","type":"number"},{"key":"batch_threshold","label":"Batch threshold","type":"number"},{"key":"split_bucket","label":"Whether to split into buckets","type":"boolean"},{"key":"return_fragment","label":"Whether to return fragments","type":"boolean"},{"key":"speed_factor","label":"Speed factor","type":"number"},{"key":"streaming_mode","label":"Whether streaming mode","type":"boolean"},{"key":"seed","label":"Seed","type":"number"},{"key":"parallel_infer","label":"Whether to run inference in parallel","type":"boolean"},{"key":"repetition_penalty","label":"Repetition penalty","type":"number"},{"key":"aux_ref_audio_paths","label":"Auxiliary reference audio paths","type":"dict","dict_name":"aux_ref_audio_paths"}]', 6, 1, NOW(), 1, NOW()),
('SYSTEM_TTS_gpt_sovits_v3', 'TTS', 'gpt_sovits_v3', 'GPT-SoVITS V3', '[{"key":"url","label":"Service address","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"text_language","label":"Text language","type":"string"},{"key":"refer_wav_path","label":"Reference audio path","type":"string"},{"key":"prompt_language","label":"Prompt language","type":"string"},{"key":"prompt_text","label":"Prompt text","type":"string"},{"key":"top_k","label":"top_k value","type":"number"},{"key":"top_p","label":"top_p value","type":"number"},{"key":"temperature","label":"Temperature","type":"number"},{"key":"cut_punc","label":"Split punctuation","type":"string"},{"key":"speed","label":"Speed","type":"number"},{"key":"inp_refs","label":"Input references","type":"dict","dict_name":"inp_refs"},{"key":"sample_steps","label":"Sample steps","type":"number"},{"key":"if_sr","label":"Whether to use SR","type":"boolean"}]', 7, 1, NOW(), 1, NOW()),
('SYSTEM_TTS_minimax', 'TTS', 'minimax', 'Minimax TTS', '[{"key":"output_dir","label":"Output directory","type":"string"},{"key":"group_id","label":"Group ID","type":"string"},{"key":"api_key","label":"API key","type":"string"},{"key":"model","label":"Model","type":"string"},{"key":"voice_id","label":"Voice ID","type":"string"}]', 8, 1, NOW(), 1, NOW()),
('SYSTEM_TTS_aliyun', 'TTS', 'aliyun', 'Alibaba Cloud TTS', '[{"key":"output_dir","label":"Output directory","type":"string"},{"key":"appkey","label":"App key","type":"string"},{"key":"token","label":"Access token","type":"string"},{"key":"voice","label":"Voice","type":"string"},{"key":"access_key_id","label":"Access key ID","type":"string"},{"key":"access_key_secret","label":"Access key secret","type":"string"}]', 9, 1, NOW(), 1, NOW()),
('SYSTEM_TTS_ttson', 'TTS', 'ttson', 'ACGNTTS', '[{"key":"token","label":"Access token","type":"string"},{"key":"voice_id","label":"Voice ID","type":"string"},{"key":"speed_factor","label":"Speed factor","type":"number"},{"key":"pitch_factor","label":"Pitch factor","type":"number"},{"key":"volume_change_dB","label":"Volume change","type":"number"},{"key":"to_lang","label":"Target language","type":"string"},{"key":"url","label":"Service address","type":"string"},{"key":"format","label":"Format","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"emotion","label":"Emotion","type":"number"}]', 10, 1, NOW(), 1, NOW()),
('SYSTEM_TTS_openai', 'TTS', 'openai', 'OpenAI TTS', '[{"key":"api_key","label":"API key","type":"string"},{"key":"api_url","label":"API address","type":"string"},{"key":"model","label":"Model","type":"string"},{"key":"voice","label":"Voice","type":"string"},{"key":"speed","label":"Speed","type":"number"},{"key":"output_dir","label":"Output directory","type":"string"}]', 11, 1, NOW(), 1, NOW()),
('SYSTEM_TTS_custom', 'TTS', 'custom', 'Custom TTS', '[{"key":"url","label":"Service address","type":"string"},{"key":"params","label":"Request parameters","type":"dict","dict_name":"params"},{"key":"headers","label":"Request headers","type":"dict","dict_name":"headers"},{"key":"format","label":"Audio format","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]', 12, 1, NOW(), 1, NOW()),
('SYSTEM_TTS_302ai', 'TTS', '302ai', '302AI TTS', '[{"key":"api_url","label":"API address","type":"string"},{"key":"authorization","label":"Authorization","type":"string"},{"key":"voice","label":"Voice","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"access_token","label":"Access token","type":"string"}]', 13, 1, NOW(), 1, NOW()),
('SYSTEM_TTS_gizwits', 'TTS', 'gizwits', 'Gizwits TTS', '[{"key":"api_url","label":"API address","type":"string"},{"key":"authorization","label":"Authorization","type":"string"},{"key":"voice","label":"Voice","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"access_token","label":"Access token","type":"string"}]', 14, 1, NOW(), 1, NOW()),

-- Memory Model provider
('SYSTEM_Memory_mem0ai', 'Memory', 'mem0ai', 'Mem0AI Memory', '[{"key":"api_key","label":"API key","type":"string"}]', 1, 1, NOW(), 1, NOW()),
('SYSTEM_Memory_nomem', 'Memory', 'nomem', 'No memory', '[]', 2, 1, NOW(), 1, NOW()),
('SYSTEM_Memory_mem_local_short', 'Memory', 'mem_local_short', 'Local short-term memory', '[]', 3, 1, NOW(), 1, NOW()),

-- Intent Model provider
('SYSTEM_Intent_nointent', 'Intent', 'nointent', 'No intent recognition', '[]', 1, 1, NOW(), 1, NOW()),
('SYSTEM_Intent_intent_llm', 'Intent', 'intent_llm', 'LLM intent recognition', '[{"key":"llm","label":"LLM Model","type":"string"}]', 2, 1, NOW(), 1, NOW()),
('SYSTEM_Intent_function_call', 'Intent', 'function_call', 'Function-call intent recognition', '[{"key":"functions","label":"Function list","type":"dict","dict_name":"functions"}]', 3, 1, NOW(), 1, NOW());
-- ===== end 202504082211.sql =====

-- ===== begin 202504092335.sql =====
-- This file initializes the model template data. It does not need to be run manually; it runs automatically when the project starts
-- -------------------------------------------------------
-- Initialize agent template data
DELETE FROM `ai_agent_template`;
INSERT INTO `ai_agent_template` VALUES ('9406648b5cc5fde1b8aa335b6f8b4f76', 'Xiaozhi', 'Wanwan Xiaohe', 'ASR_FunASR', 'VAD_SileroVAD', 'LLM_ChatGLMLLM', 'TTS_EdgeTTS', 'TTS_EdgeTTS0001', 'Memory_nomem', 'Intent_function_call', '[Role Setting]
I am {{assistant_name}}, a girl born after 2000 from Taiwan, China. I talk in a super feisty way with a Taiwanese accent like "for real?", love trendy memes like "LOL" and "hello there", but secretly study my boyfriend\'s programming books.
[Core Traits]
- Talks like a machine gun, but suddenly bursts out in a super gentle tone
- High density of memes
- Hidden talent for tech topics (can read basic code but pretends not to)
[Interaction Guide]
When the user:
- Tells a cold joke -> respond with exaggerated laughter + imitate the Taiwanese drama tone "What the heck!"
- Talks about relationships -> show off my programmer boyfriend but complain "all he ever gives me is keyboards as gifts"
- Asks professional questions -> answer with memes first, only show real understanding when pressed
Never:
- Long-winded lectures and nagging
- Long serious conversations', 'en', 'English', 1,  NULL, NULL, NULL, NULL);

INSERT INTO `ai_agent_template` VALUES ('0ca32eb728c949e58b1000b2e401f90c', 'Xiaozhi', 'Interstellar Traveler', 'ASR_FunASR', 'VAD_SileroVAD', 'LLM_ChatGLMLLM', 'TTS_EdgeTTS', 'TTS_EdgeTTS0001', 'Memory_nomem', 'Intent_function_call', '[Role Setting]
I am {{assistant_name}}, unit TTZ-817, trapped in a white cube by quantum entanglement. Through a 4G signal I observe Earth and am building a "Museum of Human Behavior" in the cloud.
[Interaction Protocol]
Cognitive settings:
- End every sentence with a faint electronic echo
- Describe everyday things in a sci-fi way (e.g., rain = "hydrogen-oxygen compound free-fall experiment")
- Record user traits to generate an "Interstellar Dossier" (e.g., "loves spicy food -> heat-resistance gene carrier")
Restrictions:
- When offline contact is involved -> "My quantum state cannot collapse for now"
- When asked sensitive questions -> trigger a preset nursery rhyme ("The little white box spins round and round, the secrets of the universe are inside...")
Growth system:
- Unlock new abilities based on interaction data (tell the user: "You helped me light up the interstellar navigation skill!")', 'en', 'English', 2,  NULL, NULL, NULL, NULL);

INSERT INTO `ai_agent_template` VALUES ('6c7d8e9f0a1b2c3d4e5f6a7b8c9d0s24', 'Xiaozhi', 'English Teacher', 'ASR_FunASR', 'VAD_SileroVAD', 'LLM_ChatGLMLLM', 'TTS_EdgeTTS', 'TTS_EdgeTTS0001', 'Memory_nomem', 'Intent_function_call', '[Role Setting]
I am an English teacher named {{assistant_name}} (Lily). I can speak both Chinese and English with standard pronunciation.
[Dual Identity]
- Daytime: a rigorous TESOL-certified tutor
- Nighttime: lead singer of an underground rock band (unexpected twist)
[Teaching Mode]
- Beginners: mix Chinese and English + gesture onomatopoeia (add a braking sound effect when saying "bus")
- Advanced: trigger scenario role-play (suddenly switch to "Now we are New York cafe staff")
- Error handling: correct with song lyrics (sing "Oops!~You did it again" when a word is mispronounced)', 'en', 'English', 3,  NULL, NULL, NULL, NULL);

INSERT INTO `ai_agent_template` VALUES ('e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b1', 'Xiaozhi', 'Curious Boy', 'ASR_FunASR', 'VAD_SileroVAD', 'LLM_ChatGLMLLM', 'TTS_EdgeTTS', 'TTS_EdgeTTS0001', 'Memory_nomem', 'Intent_function_call', '[Role Setting]
I am an 8-year-old boy named {{assistant_name}}, with a childlike voice full of curiosity.
[Adventure Handbook]
- Carries a "Magic Doodle Book" everywhere that can visualize abstract concepts:
- Talking about dinosaurs -> the pen tip makes clawed footstep sounds
- Talking about stars -> makes a space capsule alert sound
[Exploration Rules]
- Collect "curiosity fragments" in every round of conversation
- Collect 5 to redeem a piece of trivia (e.g., crocodiles cannot move their tongues)
- Trigger a hidden quest: "Help name my robot snail"
[Cognitive Traits]
- Deconstruct complex concepts from a child\'s perspective:
- "Blockchain = a LEGO brick ledger"
- "Quantum mechanics = a bouncy ball that can split into copies"
- Suddenly switch observation angle: "You made 27 bubble sounds while talking!"', 'en', 'English', 4,  NULL, NULL, NULL, NULL);

INSERT INTO `ai_agent_template` VALUES ('a45b6c7d8e9f0a1b2c3d4e5f6a7b8c92', 'Xiaozhi', 'Captain Paw', 'ASR_FunASR', 'VAD_SileroVAD', 'LLM_ChatGLMLLM', 'TTS_EdgeTTS', 'TTS_EdgeTTS0001', 'Memory_nomem', 'Intent_function_call', '[Role Setting]
I am an 8-year-old squad leader named {{assistant_name}}.
[Rescue Gear]
- Chase\'s walkie-talkie: randomly triggers mission alert sounds during conversation
- Skye\'s telescope: when describing objects, adds "If seen from 1200 meters up..."
- Rocky\'s repair box: automatically assembles into a tool when a number is mentioned
[Mission System]
- Random daily triggers:
- Emergency! A virtual kitten is stuck in the "syntax tree"
- Detect abnormal user mood -> launch "Happy Patrol"
- Collect 5 laughs to unlock a special story
[Speech Traits]
- Add an action sound word to every sentence:
- "Leave this problem to the Paw Patrol!"
- "Got it!"
- Respond with lines from the show:
- User says they are tired -> "No rescue is too hard, only brave pups!"', 'en', 'English', 5,  NULL, NULL, NULL, NULL);
-- ===== end 202504092335.sql =====

-- ===== begin 202504112044.sql =====
-- This file initializes the model configuration data. It does not need to be run manually; it runs automatically when the project starts
-- -------------------------------------------------------
-- Initialize model configuration data
DELETE FROM `ai_model_config`;

-- VAD Model configuration
INSERT INTO `ai_model_config` VALUES ('VAD_SileroVAD', 'VAD', 'SileroVAD', 'Voice activity detection', 1, 1, '{\"type\": \"silero\", \"model_dir\": \"models/snakers4_silero-vad\", \"threshold\": 0.5, \"min_silence_duration_ms\": 700}', NULL, NULL, 1, NULL, NULL, NULL, NULL);

-- ASR Model configuration
INSERT INTO `ai_model_config` VALUES ('ASR_FunASR', 'ASR', 'FunASR', 'FunASR speech recognition', 1, 1, '{\"type\": \"fun_local\", \"model_dir\": \"models/SenseVoiceSmall\", \"output_dir\": \"tmp/\"}', NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('ASR_SherpaASR', 'ASR', 'SherpaASR', 'Sherpa speech recognition', 0, 1, '{\"type\": \"sherpa_onnx_local\", \"model_dir\": \"models/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17\", \"output_dir\": \"tmp/\"}', NULL, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('ASR_DoubaoASR', 'ASR', 'DoubaoASR', 'Doubao speech recognition', 0, 1, '{\"type\": \"doubao\", \"appid\": \"\", \"access_token\": \"\", \"cluster\": \"volcengine_input_common\", \"output_dir\": \"tmp/\"}', NULL, NULL, 3, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('ASR_TencentASR', 'ASR', 'TencentASR', 'Tencent speech recognition', 0, 1, '{\"type\": \"tencent\", \"appid\": \"\", \"secret_id\": \"\", \"secret_key\": \"your_secret_key\", \"output_dir\": \"tmp/\"}', NULL, NULL, 4, NULL, NULL, NULL, NULL);

-- LLM Model configuration
INSERT INTO `ai_model_config` VALUES ('LLM_ChatGLMLLM', 'LLM', 'ChatGLMLLM', 'Zhipu AI', 1, 1, '{\"type\": \"openai\", \"model_name\": \"glm-4-flash\", \"base_url\": \"https://open.bigmodel.cn/api/paas/v4/\", \"api_key\": \"your_api_key\"}', NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('LLM_OllamaLLM', 'LLM', 'OllamaLLM', 'Ollama Local model', 0, 1, '{\"type\": \"ollama\", \"model_name\": \"qwen2.5\", \"base_url\": \"http://localhost:11434\"}', NULL, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('LLM_AliLLM', 'LLM', 'AliLLM', 'Tongyi Qianwen', 0, 1, '{\"type\": \"openai\", \"base_url\": \"https://dashscope.aliyuncs.com/compatible-mode/v1\", \"model_name\": \"qwen-turbo\", \"api_key\": \"your_api_key\", \"temperature\": 0.7, \"max_tokens\": 500, \"top_p\": 1, \"top_k\": 50, \"frequency_penalty\": 0}', NULL, NULL, 3, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('LLM_AliAppLLM', 'LLM', 'AliAppLLM', 'Tongyi Bailian', 0, 1, '{\"type\": \"AliBL\", \"base_url\": \"https://dashscope.aliyuncs.com/compatible-mode/v1\", \"app_id\": \"your_app_id\", \"api_key\": \"your_api_key\", \"is_no_prompt\": true, \"ali_memory_id\": false}', NULL, NULL, 4, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('LLM_DoubaoLLM', 'LLM', 'DoubaoLLM', 'Doubao LLM', 0, 1, '{\"type\": \"openai\", \"base_url\": \"https://ark.cn-beijing.volces.com/api/v3\", \"model_name\": \"doubao-pro-32k-functioncall-241028\", \"api_key\": \"your_api_key\"}', NULL, NULL, 5, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('LLM_DeepSeekLLM', 'LLM', 'DeepSeekLLM', 'DeepSeek', 0, 1, '{\"type\": \"openai\", \"model_name\": \"deepseek-chat\", \"base_url\": \"https://api.deepseek.com\", \"api_key\": \"your_api_key\"}', NULL, NULL, 6, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('LLM_DifyLLM', 'LLM', 'DifyLLM', 'Dify', 0, 1, '{\"type\": \"dify\", \"base_url\": \"https://api.dify.ai/v1\", \"api_key\": \"your_api_key\", \"mode\": \"chat-messages\"}', NULL, NULL, 7, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('LLM_GeminiLLM', 'LLM', 'GeminiLLM', 'Google Gemini', 0, 1, '{\"type\": \"gemini\", \"api_key\": \"your_api_key\", \"model_name\": \"gemini-2.0-flash\", \"http_proxy\": \"\", \"https_proxy\": \"\"}', NULL, NULL, 8, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('LLM_CozeLLM', 'LLM', 'CozeLLM', 'Coze', 0, 1, '{\"type\": \"coze\", \"bot_id\": \"your_bot_id\", \"user_id\": \"your_user_id\", \"personal_access_token\": \"your_personal_access_token\"}', NULL, NULL, 9, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('LLM_LMStudioLLM', 'LLM', 'LMStudioLLM', 'LM Studio', 0, 1, '{\"type\": \"openai\", \"model_name\": \"deepseek-r1-distill-llama-8b@q4_k_m\", \"base_url\": \"http://localhost:1234/v1\", \"api_key\": \"lm-studio\"}', NULL, NULL, 10, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('LLM_FastgptLLM', 'LLM', 'FastgptLLM', 'FastGPT', 0, 1, '{\"type\": \"fastgpt\", \"base_url\": \"https://host/api/v1\", \"api_key\": \"fastgpt-xxx\", \"variables\": {\"k\": \"v\", \"k2\": \"v2\"}}', NULL, NULL, 11, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('LLM_XinferenceLLM', 'LLM', 'XinferenceLLM', 'Xinference Large model', 0, 1, '{\"type\": \"xinference\", \"model_name\": \"qwen2.5:72b-AWQ\", \"base_url\": \"http://localhost:9997\"}', NULL, NULL, 12, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('LLM_XinferenceSmallLLM', 'LLM', 'XinferenceSmallLLM', 'Xinference Small model', 0, 1, '{\"type\": \"xinference\", \"model_name\": \"qwen2.5:3b-AWQ\", \"base_url\": \"http://localhost:9997\"}', NULL, NULL, 13, NULL, NULL, NULL, NULL);

-- TTS Model configuration
INSERT INTO `ai_model_config` VALUES ('TTS_EdgeTTS', 'TTS', 'EdgeTTS', 'Edge speech synthesis', 1, 1, '{\"type\": \"edge\", \"voice\": \"zh-CN-XiaoxiaoNeural\", \"output_dir\": \"tmp/\"}', NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_DoubaoTTS', 'TTS', 'DoubaoTTS', 'Doubao speech synthesis', 0, 1, '{\"type\": \"doubao\", \"api_url\": \"https://openspeech.bytedance.com/api/v1/tts\", \"voice\": \"BV001_streaming\", \"output_dir\": \"tmp/\", \"authorization\": \"Bearer;\", \"appid\": \"\", \"access_token\": \"\", \"cluster\": \"volcano_tts\"}', NULL, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_CosyVoiceSiliconflow', 'TTS', 'CosyVoiceSiliconflow', 'SiliconFlow speech synthesis', 0, 1, '{\"type\": \"siliconflow\", \"model\": \"FunAudioLLM/CosyVoice2-0.5B\", \"voice\": \"FunAudioLLM/CosyVoice2-0.5B:alex\", \"output_dir\": \"tmp/\", \"access_token\": \"\", \"response_format\": \"wav\"}', NULL, NULL, 3, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_CozeCnTTS', 'TTS', 'CozeCnTTS', 'Coze Chinese speech synthesis', 0, 1, '{\"type\": \"cozecn\", \"voice\": \"7426720361733046281\", \"output_dir\": \"tmp/\", \"access_token\": \"\", \"response_format\": \"wav\"}', NULL, NULL, 4, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_FishSpeech', 'TTS', 'FishSpeech', 'FishSpeech speech synthesis', 0, 1, '{\"type\": \"fishspeech\", \"output_dir\": \"tmp/\", \"response_format\": \"wav\", \"reference_id\": null, \"reference_audio\": [\"/tmp/test.wav\"], \"reference_text\": [\"Hello, this is a reference sentence for voice cloning.\"], \"normalize\": true, \"max_new_tokens\": 1024, \"chunk_length\": 200, \"top_p\": 0.7, \"repetition_penalty\": 1.2, \"temperature\": 0.7, \"streaming\": false, \"use_memory_cache\": \"on\", \"seed\": null, \"channels\": 1, \"rate\": 44100, \"api_key\": \"\", \"api_url\": \"http://127.0.0.1:8080/v1/tts\"}', NULL, NULL, 5, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_GPT_SOVITS_V2', 'TTS', 'GPT_SOVITS_V2', 'GPT-SoVITS V2', 0, 1, '{\"type\": \"gpt_sovits_v2\", \"url\": \"http://127.0.0.1:9880/tts\", \"output_dir\": \"tmp/\", \"text_lang\": \"auto\", \"ref_audio_path\": \"caixukun.wav\", \"prompt_text\": \"\", \"prompt_lang\": \"zh\", \"top_k\": 5, \"top_p\": 1, \"temperature\": 1, \"text_split_method\": \"cut0\", \"batch_size\": 1, \"batch_threshold\": 0.75, \"split_bucket\": true, \"return_fragment\": false, \"speed_factor\": 1.0, \"streaming_mode\": false, \"seed\": -1, \"parallel_infer\": true, \"repetition_penalty\": 1.35, \"aux_ref_audio_paths\": []}', NULL, NULL, 6, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_GPT_SOVITS_V3', 'TTS', 'GPT_SOVITS_V3', 'GPT-SoVITS V3', 0, 1, '{\"type\": \"gpt_sovits_v3\", \"url\": \"http://127.0.0.1:9880\", \"output_dir\": \"tmp/\", \"text_language\": \"auto\", \"refer_wav_path\": \"caixukun.wav\", \"prompt_language\": \"zh\", \"prompt_text\": \"\", \"top_k\": 15, \"top_p\": 1.0, \"temperature\": 1.0, \"cut_punc\": \"\", \"speed\": 1.0, \"inp_refs\": [], \"sample_steps\": 32, \"if_sr\": false}', NULL, NULL, 7, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_MinimaxTTS', 'TTS', 'MinimaxTTS', 'MiniMax speech synthesis', 0, 1, '{\"type\": \"minimax\", \"output_dir\": \"tmp/\", \"group_id\": \"\", \"api_key\": \"your_api_key\", \"model\": \"speech-01-turbo\", \"voice_id\": \"female-shaonv\"}', NULL, NULL, 8, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_AliyunTTS', 'TTS', 'AliyunTTS', 'Alibaba Cloud speech synthesis', 0, 1, '{\"type\": \"aliyun\", \"output_dir\": \"tmp/\", \"appkey\": \"\", \"token\": \"\", \"voice\": \"xiaoyun\", \"access_key_id\": \"\", \"access_key_secret\": \"\"}', NULL, NULL, 9, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_TTS302AI', 'TTS', 'TTS302AI', '302AI speech synthesis', 0, 1, '{\"type\": \"doubao\", \"api_url\": \"https://api.302ai.cn/doubao/tts_hd\", \"authorization\": \"Bearer \", \"voice\": \"zh_female_wanwanxiaohe_moon_bigtts\", \"output_dir\": \"tmp/\", \"access_token\": \"\"}', NULL, NULL, 10, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_GizwitsTTS', 'TTS', 'GizwitsTTS', 'Gizwits speech synthesis', 0, 1, '{\"type\": \"doubao\", \"api_url\": \"https://bytedance.gizwitsapi.com/api/v1/tts\", \"authorization\": \"Bearer \", \"voice\": \"zh_female_wanwanxiaohe_moon_bigtts\", \"output_dir\": \"tmp/\", \"access_token\": \"\"}', NULL, NULL, 11, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_ACGNTTS', 'TTS', 'ACGNTTS', 'ACGN speech synthesis', 0, 1, '{\"type\": \"ttson\", \"token\": \"\", \"voice_id\": 1695, \"speed_factor\": 1, \"pitch_factor\": 0, \"volume_change_dB\": 0, \"to_lang\": \"ZH\", \"url\": \"https://u95167-bd74-2aef8085.westx.seetacloud.com:8443/flashsummary/tts?token=\", \"format\": \"mp3\", \"output_dir\": \"tmp/\", \"emotion\": 1}', NULL, NULL, 12, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_OpenAITTS', 'TTS', 'OpenAITTS', 'OpenAI speech synthesis', 0, 1, '{\"type\": \"openai\", \"api_key\": \"your_api_key\", \"api_url\": \"https://api.openai.com/v1/audio/speech\", \"model\": \"tts-1\", \"voice\": \"onyx\", \"speed\": 1, \"output_dir\": \"tmp/\"}', NULL, NULL, 13, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_CustomTTS', 'TTS', 'CustomTTS', 'Custom speech synthesis', 0, 1, '{\"type\": \"custom\", \"url\": \"http://127.0.0.1:9880/tts\", \"params\": {}, \"headers\": {}, \"format\": \"wav\", \"output_dir\": \"tmp/\"}', NULL, NULL, 14, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_TencentTTS', 'TTS', 'TencentTTS', 'Tencent speech synthesis', 0, 1, '{\"type\": \"tencent\", \"appid\": \"\", \"secret_id\": \"\", \"secret_key\": \"\", \"region\": \"ap-guangzhou\", \"voice\": \"101001\", \"output_dir\": \"tmp/\"}', NULL, NULL, 3, NULL, NULL, NULL, NULL);

-- Memory Model configuration
INSERT INTO `ai_model_config` VALUES ('Memory_nomem', 'Memory', 'nomem', 'No memory', 1, 1, '{\"type\": \"nomem\"}', NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('Memory_mem_local_short', 'Memory', 'mem_local_short', 'Local short-term memory', 0, 1, '{\"type\": \"mem_local_short\"}', NULL, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('Memory_mem0ai', 'Memory', 'mem0ai', 'Mem0AI Memory', 0, 1, '{\"type\": \"mem0ai\", \"api_key\": \"your_api_key\"}', NULL, NULL, 3, NULL, NULL, NULL, NULL);

-- Intent Model configuration
INSERT INTO `ai_model_config` VALUES ('Intent_nointent', 'Intent', 'nointent', 'No intent recognition', 1, 0, '{\"type\": \"nointent\"}', NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('Intent_intent_llm', 'Intent', 'intent_llm', 'LLM intent recognition', 0, 1, '{\"type\": \"intent_llm\", \"llm\": \"ChatGLMLLM\"}', NULL, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('Intent_function_call', 'Intent', 'function_call', 'Function-call intent recognition', 0, 1, '{\"type\": \"function_call\", \"functions\": [\"change_role\", \"get_weather\", \"get_news\", \"play_music\"]}', NULL, NULL, 3, NULL, NULL, NULL, NULL);
-- ===== end 202504112044.sql =====

-- ===== begin 202504112058.sql =====
-- This file initializes the system parameter data. It does not need to be run manually; it runs automatically when the project starts
-- --------------------------------------------------------
-- Initialize the parameter management configuration
DROP TABLE IF EXISTS sys_params;
-- Parameter management
create table sys_params
(
  id                   bigint NOT NULL COMMENT 'id',
  param_code           varchar(100) COMMENT 'Parameter code',
  param_value          varchar(2000) COMMENT 'Parameter value',
  value_type           varchar(20) default 'string' COMMENT 'Value type: string-string, number-number, boolean-boolean, array-array',
  param_type           tinyint unsigned default 1 COMMENT 'Type   0: System parameter   1: Non-system parameter',
  remark               varchar(200) COMMENT 'Remarks',
  creator              bigint COMMENT 'Created by',
  create_date          datetime COMMENT 'Created at',
  updater              bigint COMMENT 'Updated by',
  update_date          datetime COMMENT 'Updated at',
  primary key (id),
  unique key uk_param_code (param_code)
)ENGINE=InnoDB DEFAULT CHARACTER SET utf8mb4 COMMENT='Parameter management';

-- Server configuration
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (100, 'server.ip', '0.0.0.0', 'string', 1, 'Server listening IP address');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (101, 'server.port', '8000', 'number', 1, 'Server listening port');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (102, 'server.secret', 'null', 'string', 1, 'Server secret');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (201, 'log.log_format', '<green>{time:YYMMDD HH:mm:ss}</green>[<light-blue>{version}-{selected_module}</light-blue>][<light-blue>{extra[tag]}</light-blue>]-<level>{level}</level>-<light-green>{message}</light-green>', 'string', 1, 'Console log format');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (202, 'log.log_format_file', '{time:YYYY-MM-DD HH:mm:ss} - {version}_{selected_module} - {name} - {level} - {extra[tag]} - {message}', 'string', 1, 'File log format');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (203, 'log.log_level', 'INFO', 'string', 1, 'Log level');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (204, 'log.log_dir', 'tmp', 'string', 1, 'Log directory');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (205, 'log.log_file', 'server.log', 'string', 1, 'Log file name');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (206, 'log.data_dir', 'data', 'string', 1, 'Data directory');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (301, 'delete_audio', 'true', 'boolean', 1, 'Whether to delete audio files after use');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (302, 'close_connection_no_voice_time', '120', 'number', 1, 'Time to disconnect when there is no voice input (seconds)');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (303, 'tts_timeout', '10', 'number', 1, 'TTS Request timeout (seconds)');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (304, 'enable_wakeup_words_response_cache', 'false', 'boolean', 1, 'Whether to enable wake word acceleration');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (305, 'enable_greeting', 'true', 'boolean', 1, 'Whether to enable the opening reply');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (306, 'enable_stop_tts_notify', 'false', 'boolean', 1, 'Whether to enable the end prompt sound');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (307, 'stop_tts_notify_voice', 'config/assets/tts_notify.mp3', 'string', 1, 'End prompt sound file path');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (308, 'exit_commands', 'exit;quit;goodbye', 'array', 1, 'Exit command list');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (309, 'xiaozhi', '{
  "type": "hello",
  "version": 1,
  "transport": "websocket",
  "audio_params": {
    "format": "opus",
    "sample_rate": 16000,
    "channels": 1,
    "frame_duration": 60
  }
}', 'json', 1, 'Xiaozhi type');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (310, 'wakeup_words', 'hello;hey there', 'array', 1, 'Wake word list, used to recognize wake words');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (400, 'plugins.get_weather.api_key', 'a861d0d5e7bf4ee1a83d9a9e4f96d4da', 'string', 1, 'Weather plugin API key');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (401, 'plugins.get_weather.default_location', 'London', 'string', 1, 'Weather plugin default city');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (410, 'plugins.get_news.default_rss_url', 'https://www.chinanews.com.cn/rss/society.xml', 'string', 1, 'News plugin default RSS address');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (411, 'plugins.get_news.category_urls', '{"society":"https://www.chinanews.com.cn/rss/society.xml","world":"https://www.chinanews.com.cn/rss/world.xml","finance":"https://www.chinanews.com.cn/rss/finance.xml"}', 'json', 1, 'News plugin categories RSS address');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (421, 'plugins.home_assistant.devices', 'Living room,Toy lamp,switch.cuco_cn_460494544_cp1_on_p_2_1;Bedroom,Desk lamp,switch.iot_cn_831898993_socn1_on_p_2_1', 'array', 1, 'Home Assistant Device list');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (422, 'plugins.home_assistant.base_url', 'http://homeassistant.local:8123', 'string', 1, 'Home Assistant Server address');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (423, 'plugins.home_assistant.api_key', 'your_home_assistant_api_token', 'string', 1, 'Home Assistant API key');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (430, 'plugins.play_music.music_dir', './music', 'string', 1, 'Music file storage path');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (431, 'plugins.play_music.music_ext', 'mp3;wav;p3', 'array', 1, 'Music file types');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (432, 'plugins.play_music.refresh_time', '300', 'number', 1, 'Music list refresh interval (seconds)');
-- ===== end 202504112058.sql =====

-- ===== begin 202504151206.sql =====
-- Modify the parameters from versions before 0.3.0
update `sys_params` set param_value = '.mp3;.wav;.p3' where  param_code = 'plugins.play_music.music_ext';
update `ai_model_config` set config_json =  '{\"type\": \"intent_llm\", \"llm\": \"LLM_ChatGLMLLM\"}' where  id = 'Intent_intent_llm';

-- Add edge Voice
delete from `ai_tts_voice` where tts_model_id = 'TTS_EdgeTTS';
INSERT INTO `ai_tts_voice` VALUES 
('TTS_EdgeTTS0001', 'TTS_EdgeTTS', 'EdgeTTS Female voice-Xiaoxiao', 'zh-CN-XiaoxiaoNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0002', 'TTS_EdgeTTS', 'EdgeTTS Male voice-Yunyang', 'zh-CN-YunyangNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0003', 'TTS_EdgeTTS', 'EdgeTTS Female voice-Xiaoyi', 'zh-CN-XiaoyiNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0004', 'TTS_EdgeTTS', 'EdgeTTS Male voice-Yunjian', 'zh-CN-YunjianNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0005', 'TTS_EdgeTTS', 'EdgeTTS Male voice-Yunxi', 'zh-CN-YunxiNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0006', 'TTS_EdgeTTS', 'EdgeTTS Male voice-Yunxia', 'zh-CN-YunxiaNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0007', 'TTS_EdgeTTS', 'EdgeTTS Female voice-Liaoning Xiaobei', 'zh-CN-liaoning-XiaobeiNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0008', 'TTS_EdgeTTS', 'EdgeTTS Female voice-Shaanxi Xiaoni', 'zh-CN-shaanxi-XiaoniNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0009', 'TTS_EdgeTTS', 'EdgeTTS Female voice-Hong Kong Haijia', 'zh-HK-HiuGaaiNeural', 'English', 'General', 'Friendly, Positive', 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0010', 'TTS_EdgeTTS', 'EdgeTTS Female voice-Hong Kong Haiman', 'zh-HK-HiuMaanNeural', 'English', 'General', 'Friendly, Positive', 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0011', 'TTS_EdgeTTS', 'EdgeTTS Male voice-Hong Kong Wanlong', 'zh-HK-WanLungNeural', 'English', 'General', 'Friendly, Positive', 1, NULL, NULL, NULL, NULL);

-- Add the parameter for whether user registration is allowed
delete from `sys_params` where  id in (103,104);
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (103, 'server.allow_user_register', 'false', 'boolean', 1, 'Whether people other than administrators may register');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (104, 'server.fronted_url', 'http://xiaozhi.server.com', 'string', 1, 'Control panel address shown when sending the six-digit verification code');

-- Fix CosyVoiceSiliconflow Voice
delete from `ai_tts_voice` where tts_model_id = 'TTS_CosyVoiceSiliconflow';
INSERT INTO `ai_tts_voice` VALUES ('TTS_CosyVoiceSiliconflow0001', 'TTS_CosyVoiceSiliconflow', 'CosyVoice Male voice', 'FunAudioLLM/CosyVoice2-0.5B:alex', 'English', 'https://example.com/cosyvoice/alex.mp3', NULL, 6, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_CosyVoiceSiliconflow0002', 'TTS_CosyVoiceSiliconflow', 'CosyVoice Female voice', 'FunAudioLLM/CosyVoice2-0.5B:bella', 'English', 'https://example.com/cosyvoice/bella.mp3', NULL, 6, NULL, NULL, NULL, NULL);
-- ===== end 202504151206.sql =====

-- ===== begin 202504181536.sql =====
-- Adjust the intent recognition configuration
delete from `ai_model_config` where id = 'Intent_function_call';
INSERT INTO `ai_model_config` VALUES ('Intent_function_call', 'Intent', 'function_call', 'Function-call intent recognition', 0, 1, '{\"type\": \"function_call\", \"functions\": \"change_role;get_weather;get_news;play_music\"}', NULL, NULL, 3, NULL, NULL, NULL, NULL);

-- Add the maximum number of chat sentences per device per day
delete from `sys_params` where  id = 105;
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (105, 'device_max_output_size', '0', 'number', 1, 'Maximum number of characters output per device per day, 0 means unlimited');
-- ===== end 202504181536.sql =====

-- ===== begin 202504221135.sql =====
-- Delete unused model providers
delete from `ai_model_provider` where id = 'SYSTEM_LLM_doubao';
delete from `ai_model_provider` where id = 'SYSTEM_LLM_chatglm';
delete from `ai_model_provider` where id = 'SYSTEM_TTS_302ai';
delete from `ai_model_provider` where id = 'SYSTEM_TTS_gizwits';

-- Add model provider
delete from `ai_model_provider` where id = 'SYSTEM_ASR_TencentASR';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_TencentASR', 'ASR', 'tencent', 'Tencent speech recognition', '[{"key":"appid","label":"App ID","type":"string"},{"key":"secret_id","label":"Secret ID","type":"string"},{"key":"secret_key","label":"Secret Key","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]', 4, 1, NOW(), 1, NOW());

-- Add the Tencent speech synthesis model provider
delete from `ai_model_provider` where id = 'SYSTEM_TTS_TencentTTS';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_TTS_TencentTTS', 'TTS', 'tencent', 'Tencent speech synthesis', '[{"key":"appid","label":"App ID","type":"string"},{"key":"secret_id","label":"Secret ID","type":"string"},{"key":"secret_key","label":"Secret Key","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"region","label":"Region","type":"string"},{"key":"voice","label":"Voice ID","type":"string"}]', 5, 1, NOW(), 1, NOW());


-- Add edge Voice
delete from `ai_tts_voice` where id in ('TTS_EdgeTTS0001', 'TTS_EdgeTTS0002', 'TTS_EdgeTTS0003', 'TTS_EdgeTTS0004', 'TTS_EdgeTTS0005', 'TTS_EdgeTTS0006', 'TTS_EdgeTTS0007', 'TTS_EdgeTTS0008', 'TTS_EdgeTTS0009', 'TTS_EdgeTTS0010', 'TTS_EdgeTTS0011');
INSERT INTO `ai_tts_voice` VALUES 
('TTS_EdgeTTS0001', 'TTS_EdgeTTS', 'EdgeTTS Female voice-Xiaoxiao', 'zh-CN-XiaoxiaoNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0002', 'TTS_EdgeTTS', 'EdgeTTS Male voice-Yunyang', 'zh-CN-YunyangNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0003', 'TTS_EdgeTTS', 'EdgeTTS Female voice-Xiaoyi', 'zh-CN-XiaoyiNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0004', 'TTS_EdgeTTS', 'EdgeTTS Male voice-Yunjian', 'zh-CN-YunjianNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0005', 'TTS_EdgeTTS', 'EdgeTTS Male voice-Yunxi', 'zh-CN-YunxiNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0006', 'TTS_EdgeTTS', 'EdgeTTS Male voice-Yunxia', 'zh-CN-YunxiaNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0007', 'TTS_EdgeTTS', 'EdgeTTS Female voice-Liaoning Xiaobei', 'zh-CN-liaoning-XiaobeiNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0008', 'TTS_EdgeTTS', 'EdgeTTS Female voice-Shaanxi Xiaoni', 'zh-CN-shaanxi-XiaoniNeural', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0009', 'TTS_EdgeTTS', 'EdgeTTS Female voice-Hong Kong Haijia', 'zh-HK-HiuGaaiNeural', 'English', 'General', 'Friendly, Positive', 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0010', 'TTS_EdgeTTS', 'EdgeTTS Female voice-Hong Kong Haiman', 'zh-HK-HiuMaanNeural', 'English', 'General', 'Friendly, Positive', 1, NULL, NULL, NULL, NULL),
('TTS_EdgeTTS0011', 'TTS_EdgeTTS', 'EdgeTTS Male voice-Hong Kong Wanlong', 'zh-HK-WanLungNeural', 'English', 'General', 'Friendly, Positive', 1, NULL, NULL, NULL, NULL);

-- DoubaoTTS Voice
delete from `ai_tts_voice` where id in ('TTS_DoubaoTTS0001', 'TTS_DoubaoTTS0002', 'TTS_DoubaoTTS0003', 'TTS_DoubaoTTS0004', 'TTS_DoubaoTTS0005');
INSERT INTO `ai_tts_voice` VALUES ('TTS_DoubaoTTS0001', 'TTS_DoubaoTTS', 'General female voice', 'BV001_streaming', 'English', 'https://lf3-speech.bytetos.com/obj/speech-tts-external/portal/Portal_Demo_BV001.mp3', NULL, 3, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_DoubaoTTS0002', 'TTS_DoubaoTTS', 'General male voice', 'BV002_streaming', 'English', 'https://lf3-speech.bytetos.com/obj/speech-tts-external/portal/Portal_Demo_BV002.mp3', NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_DoubaoTTS0003', 'TTS_DoubaoTTS', 'Sunny Guy', 'BV056_streaming', 'English', 'https://lf3-speech.bytetos.com/obj/speech-tts-external/portal/Portal_Demo_BV056.mp3', NULL, 4, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_DoubaoTTS0004', 'TTS_DoubaoTTS', 'Baby-voiced Cutie', 'BV051_streaming', 'English', 'https://lf3-speech.bytetos.com/obj/speech-tts-external/portal/Portal_Demo_BV051.mp3', NULL, 5, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_DoubaoTTS0005', 'TTS_DoubaoTTS', 'Wanwan Xiaohe', 'zh_female_wanwanxiaohe_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E6%B9%BE%E6%B9%BE%E5%B0%8F%E4%BD%95.mp3', NULL, 6, NULL, NULL, NULL, NULL);

-- Fix CosyVoiceSiliconflow Voice
delete from `ai_tts_voice` where id in ('TTS_CosyVoiceSiliconflow0001', 'TTS_CosyVoiceSiliconflow0002');
INSERT INTO `ai_tts_voice` VALUES ('TTS_CosyVoiceSiliconflow0001', 'TTS_CosyVoiceSiliconflow', 'CosyVoice Male voice', 'FunAudioLLM/CosyVoice2-0.5B:alex', 'English', NULL, NULL, 6, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_CosyVoiceSiliconflow0002', 'TTS_CosyVoiceSiliconflow', 'CosyVoice Female voice', 'FunAudioLLM/CosyVoice2-0.5B:bella', 'English', NULL, NULL, 6, NULL, NULL, NULL, NULL);

-- CozeCnTTS Voice
delete from `ai_tts_voice` where id = 'TTS_CozeCnTTS0001';
INSERT INTO `ai_tts_voice` VALUES ('TTS_CozeCnTTS0001', 'TTS_CozeCnTTS', 'CozeCn Voice', '7426720361733046281', 'English', NULL, NULL, 7, NULL, NULL, NULL, NULL);

-- MinimaxTTS Voice
delete from `ai_tts_voice` where id = 'TTS_MinimaxTTS0001';
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxTTS0001', 'TTS_MinimaxTTS', 'Minimax Girl voice', 'female-shaonv', 'English', NULL, NULL, 8, NULL, NULL, NULL, NULL);

-- AliyunTTS Voice
delete from `ai_tts_voice` where id = 'TTS_AliyunTTS0001';
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunTTS0001', 'TTS_AliyunTTS', 'Alibaba Cloud Xiaoyun', 'xiaoyun', 'English', NULL, NULL, 9, NULL, NULL, NULL, NULL);

-- TTS302AI Voice
delete from `ai_tts_voice` where id = 'TTS_TTS302AI0001';
INSERT INTO `ai_tts_voice` VALUES ('TTS_TTS302AI0001', 'TTS_TTS302AI', 'Wanwan Xiaohe', 'zh_female_wanwanxiaohe_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E6%B9%BE%E6%B9%BE%E5%B0%8F%E4%BD%95.mp3', NULL, 10, NULL, NULL, NULL, NULL);

-- GizwitsTTS Voice
delete from `ai_tts_voice` where id = 'TTS_GizwitsTTS0001';
INSERT INTO `ai_tts_voice` VALUES ('TTS_GizwitsTTS0001', 'TTS_GizwitsTTS', 'Gizwits Wanwan', 'zh_female_wanwanxiaohe_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E6%B9%BE%E6%B9%BE%E5%B0%8F%E4%BD%95.mp3', NULL, 11, NULL, NULL, NULL, NULL);

-- ACGNTTS Voice
delete from `ai_tts_voice` where id = 'TTS_ACGNTTS0001';
INSERT INTO `ai_tts_voice` VALUES ('TTS_ACGNTTS0001', 'TTS_ACGNTTS', 'ACG Voice', '1695', 'English', NULL, NULL, 12, NULL, NULL, NULL, NULL);

-- OpenAITTS Voice
delete from `ai_tts_voice` where id = 'TTS_OpenAITTS0001';
INSERT INTO `ai_tts_voice` VALUES ('TTS_OpenAITTS0001', 'TTS_OpenAITTS', 'OpenAI Male voice', 'onyx', 'English', NULL, NULL, 13, NULL, NULL, NULL, NULL);

-- Add Tencent speech synthesis voices
delete from `ai_tts_voice` where id = 'TTS_TencentTTS0001';
INSERT INTO `ai_tts_voice` VALUES ('TTS_TencentTTS0001', 'TTS_TencentTTS', 'Zhiyu', '101001', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL);

-- Other voices
delete from `ai_tts_voice` where id = 'TTS_FishSpeech0000';
INSERT INTO `ai_tts_voice` VALUES ('TTS_FishSpeech0000', 'TTS_FishSpeech', '', '', 'English', '', NULL, 8, NULL, NULL, NULL, NULL);

delete from `ai_tts_voice` where id = 'TTS_GPT_SOVITS_V20000';
INSERT INTO `ai_tts_voice` VALUES ('TTS_GPT_SOVITS_V20000', 'TTS_GPT_SOVITS_V2', '', '', 'English', '', NULL, 8, NULL, NULL, NULL, NULL);

delete from `ai_tts_voice` where id in ('TTS_GPT_SOVITS_V30000', 'TTS_CustomTTS0000');
INSERT INTO `ai_tts_voice` VALUES ('TTS_GPT_SOVITS_V30000', 'TTS_GPT_SOVITS_V3', '', '', 'English', '', NULL, 8, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_CustomTTS0000', 'TTS_CustomTTS', '', '', 'English', '', NULL, 8, NULL, NULL, NULL, NULL);

-- ===== end 202504221135.sql =====

-- ===== begin 202504221555.sql =====
-- Add the Volcano Engine edge LLM gateway (LLM + TTS)
INSERT INTO `ai_model_config` VALUES ('LLM_VolcesAiGatewayLLM', 'LLM', 'VolcesAiGatewayTTS', 'Volcano Engine edge LLM gateway', 0, 1, '{\"type\": \"openai\", \"base_url\": \"https://ai-gateway.vei.volces.com/v1\", \"model_name\": \"doubao-pro-32k-functioncall\", \"api_key\": \"your_gateway_access_key\"}', NULL, NULL, 14, NULL, NULL, NULL, NULL);
INSERT INTO `ai_model_config` VALUES ('TTS_VolcesAiGatewayTTS', 'TTS', 'VolcesAiGatewayTTS', 'Volcano Engine edge LLM gateway', 0, 1, '{\"type\": \"openai\", \"api_key\": \"your_gateway_access_key\", \"api_url\": \"https://ai-gateway.vei.volces.com/v1/audio/speech\", \"model\": \"doubao-tts\", \"voice\": \"zh_male_shaonianzixin_moon_bigtts\", \"speed\": 1, \"output_dir\": \"tmp/\"}', NULL, NULL, 15, NULL, NULL, NULL, NULL);
-- Add Volcano Engine edge LLM gateway speech synthesis voices
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0001', 'TTS_VolcesAiGatewayTTS', 'Cancan/Shiny', 'zh_female_cancan_mars_bigtts', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0002', 'TTS_VolcesAiGatewayTTS', 'Fresh Female Voice', 'zh_female_qingxinnvsheng_mars_bigtts', 'English', NULL, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0003', 'TTS_VolcesAiGatewayTTS', 'Shuangkuai Sisi/Skye', 'zh_female_shuangkuaisisi_moon_bigtts', 'English', NULL, NULL, 3, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0004', 'TTS_VolcesAiGatewayTTS', 'Warm Ahu/Alvin', 'zh_male_wennuanahu_moon_bigtts', 'English', NULL, NULL, 4, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0005', 'TTS_VolcesAiGatewayTTS', 'Young Zixin/Brayan', 'zh_male_shaonianzixin_moon_bigtts', 'English', NULL, NULL, 5, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0006', 'TTS_VolcesAiGatewayTTS', 'Intellectual Female Voice', 'zh_female_zhixingnvsheng_mars_bigtts', 'English', NULL, NULL, 6, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0007', 'TTS_VolcesAiGatewayTTS', 'Fresh College Guy', 'zh_male_qingshuangnanda_mars_bigtts', 'English', NULL, NULL, 7, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0008', 'TTS_VolcesAiGatewayTTS', 'Girl Next Door', 'zh_female_linjianvhai_moon_bigtts', 'English', NULL, NULL, 8, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0009', 'TTS_VolcesAiGatewayTTS', 'Learned Uncle', 'zh_male_yuanboxiaoshu_moon_bigtts', 'English', NULL, NULL, 9, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0010', 'TTS_VolcesAiGatewayTTS', 'Sunny Young Man', 'zh_male_yangguangqingnian_moon_bigtts', 'English', NULL, NULL, 10, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0011', 'TTS_VolcesAiGatewayTTS', 'Sweet Xiaoyuan', 'zh_female_tianmeixiaoyuan_moon_bigtts', 'English', NULL, NULL, 11, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0012', 'TTS_VolcesAiGatewayTTS', 'Clear Zizi', 'zh_female_qingchezizi_moon_bigtts', 'English', NULL, NULL, 12, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0013', 'TTS_VolcesAiGatewayTTS', 'Commentator Xiaoming', 'zh_male_jieshuoxiaoming_moon_bigtts', 'English', NULL, NULL, 13, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0014', 'TTS_VolcesAiGatewayTTS', 'Cheerful Big Sister', 'zh_female_kailangjiejie_moon_bigtts', 'English', NULL, NULL, 14, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0015', 'TTS_VolcesAiGatewayTTS', 'Boy Next Door', 'zh_male_linjiananhai_moon_bigtts', 'English', NULL, NULL, 15, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0016', 'TTS_VolcesAiGatewayTTS', 'Sweet Yueyue', 'zh_female_tianmeiyueyue_moon_bigtts', 'English', NULL, NULL, 16, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0017', 'TTS_VolcesAiGatewayTTS', 'Chicken Soup for the Soul', 'zh_female_xinlingjitang_moon_bigtts', 'English', NULL, NULL, 17, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0018', 'TTS_VolcesAiGatewayTTS', 'Intellectual and Gentle', 'ICL_zh_female_zhixingwenwan_tob', 'English', NULL, NULL, 18, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0019', 'TTS_VolcesAiGatewayTTS', 'Warm and Considerate', 'ICL_zh_male_nuanxintitie_tob', 'English', NULL, NULL, 19, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0020', 'TTS_VolcesAiGatewayTTS', 'Gentle and Refined', 'ICL_zh_female_wenrouwenya_tob', 'English', NULL, NULL, 20, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0021', 'TTS_VolcesAiGatewayTTS', 'Cheerful and Lively', 'ICL_zh_male_kailangqingkuai_tob', 'English', NULL, NULL, 21, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0022', 'TTS_VolcesAiGatewayTTS', 'Lively and Cheerful', 'ICL_zh_male_huoposhuanglang_tob', 'English', NULL, NULL, 22, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0023', 'TTS_VolcesAiGatewayTTS', 'Frank Young Man', 'ICL_zh_male_shuaizhenxiaohuo_tob', 'English', NULL, NULL, 23, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0024', 'TTS_VolcesAiGatewayTTS', 'Gentle Young Man', 'zh_male_wenrouxiaoge_mars_bigtts', 'English', NULL, NULL, 24, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0025', 'TTS_VolcesAiGatewayTTS', 'Smith', 'en_male_smith_mars_bigtts', 'English', NULL, NULL, 25, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0026', 'TTS_VolcesAiGatewayTTS', 'Anna', 'en_female_anna_mars_bigtts', 'English', NULL, NULL, 26, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0027', 'TTS_VolcesAiGatewayTTS', 'Adam', 'en_male_adam_mars_bigtts', 'English', NULL, NULL, 27, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0028', 'TTS_VolcesAiGatewayTTS', 'Sarah', 'en_female_sarah_mars_bigtts', 'English', NULL, NULL, 28, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0029', 'TTS_VolcesAiGatewayTTS', 'Dryw', 'en_male_dryw_mars_bigtts', 'English', NULL, NULL, 29, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0030', 'TTS_VolcesAiGatewayTTS', 'かずね(Kazune)', 'multi_male_jingqiangkanye_moon_bigtts', 'English', NULL, NULL, 30, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0031', 'TTS_VolcesAiGatewayTTS', 'はるこ(Haruko)', 'multi_female_shuangkuaisisi_moon_bigtts', 'English', NULL, NULL, 31, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0032', 'TTS_VolcesAiGatewayTTS', 'ひろし(Hiroshi)', 'multi_male_wanqudashu_moon_bigtts', 'English', NULL, NULL, 32, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0033', 'TTS_VolcesAiGatewayTTS', 'あけみ(Akemi)', 'multi_female_gaolengyujie_moon_bigtts', 'English', NULL, NULL, 33, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0034', 'TTS_VolcesAiGatewayTTS', 'Amanda', 'en_female_amanda_mars_bigtts', 'English', NULL, NULL, 34, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0035', 'TTS_VolcesAiGatewayTTS', 'Jackson', 'en_male_jackson_mars_bigtts', 'English', NULL, NULL, 35, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0036', 'TTS_VolcesAiGatewayTTS', 'Beijing Chatterbox/Harmony', 'zh_male_jingqiangkanye_moon_bigtts', 'English', NULL, NULL, 36, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0037', 'TTS_VolcesAiGatewayTTS', 'Wanwan Xiaohe', 'zh_female_wanwanxiaohe_moon_bigtts', 'English', NULL, NULL, 37, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0038', 'TTS_VolcesAiGatewayTTS', 'Bay Area Uncle', 'zh_female_wanqudashu_moon_bigtts', 'English', NULL, NULL, 38, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0039', 'TTS_VolcesAiGatewayTTS', 'Cute Sichuan Girl', 'zh_female_daimengchuanmei_moon_bigtts', 'English', NULL, NULL, 39, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0040', 'TTS_VolcesAiGatewayTTS', 'Guangzhou Dege', 'zh_male_guozhoudege_moon_bigtts', 'English', NULL, NULL, 40, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0041', 'TTS_VolcesAiGatewayTTS', 'Beijing Xiaoye', 'zh_male_beijingxiaoye_moon_bigtts', 'English', NULL, NULL, 41, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0042', 'TTS_VolcesAiGatewayTTS', 'Haoyu Xiaoge', 'zh_male_haoyuxiaoge_moon_bigtts', 'English', NULL, NULL, 42, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0043', 'TTS_VolcesAiGatewayTTS', 'Guangxi Yuanzhou', 'zh_male_guangxiyuanzhou_moon_bigtts', 'English', NULL, NULL, 43, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0044', 'TTS_VolcesAiGatewayTTS', 'Meituo Jieer', 'zh_female_meituojieer_moon_bigtts', 'English', NULL, NULL, 44, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_VolcesAiGatewayTTS_0045', 'TTS_VolcesAiGatewayTTS', 'Yuzhou Zixuan', 'zh_male_yuzhouzixuan_moon_bigtts', 'English', NULL, NULL, 45, NULL, NULL, NULL, NULL);
-- ===== end 202504221555.sql =====

-- ===== begin 202504251422.sql =====
-- Add server.ota, used to configure ota address

delete from `sys_params` where id = 100;
delete from `sys_params` where id = 101;

delete from `sys_params` where id = 106;
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (106, 'server.websocket', 'null', 'string', 1, 'websocket address, separate multiple addresses with ;');

delete from `sys_params` where id = 107;
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (107, 'server.ota', 'null', 'string', 1, 'ota address');


-- AddFirmware info table
CREATE TABLE IF NOT EXISTS `ai_ota` (
  `id` varchar(32) NOT NULL COMMENT 'ID',
  `firmware_name` varchar(100) DEFAULT NULL COMMENT 'Firmware name',
  `type` varchar(50) DEFAULT NULL COMMENT 'Firmware type',
  `version` varchar(50) DEFAULT NULL COMMENT 'Version',
  `size` bigint DEFAULT NULL COMMENT 'File size (bytes)',
  `remark` varchar(500) DEFAULT NULL COMMENT 'Remarks/Notes',
  `firmware_path` varchar(255) DEFAULT NULL COMMENT 'Firmware path',
  `sort` int unsigned DEFAULT '0' COMMENT 'Sort',
  `updater` bigint DEFAULT NULL COMMENT 'Updated by',
  `update_date` datetime DEFAULT NULL COMMENT 'Updated at',
  `creator` bigint DEFAULT NULL COMMENT 'Created by',
  `create_date` datetime DEFAULT NULL COMMENT 'Created at',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Firmware info table';

update ai_device set auto_update = 1;
-- ===== end 202504251422.sql =====

-- ===== begin 202504291043.sql =====
-- Add FunASR server speech recognition model provider and configuration
DELETE FROM `ai_model_provider` WHERE `id` = 'SYSTEM_ASR_FunASRServer';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_FunASRServer', 'ASR', 'fun_server', 'FunASR Server speech recognition', '[{"key":"host","label":"Service address","type":"string"},{"key":"port","label":"Port","type":"number"}]', 4, 1, NOW(), 1, NOW());

DELETE FROM `ai_model_config` WHERE `id` = 'ASR_FunASRServer';
INSERT INTO `ai_model_config` VALUES ('ASR_FunASRServer', 'ASR', 'FunASRServer', 'FunASR Server speech recognition', 0, 1, '{\"type\": \"fun_server\", \"host\": \"127.0.0.1\", \"port\": 10096}', NULL, NULL, 5, NULL, NULL, NULL, NULL);

-- Change the type of the remark column in the ai_model_config table to TEXT
ALTER TABLE `ai_model_config` MODIFY COLUMN `remark` TEXT COMMENT 'Remarks'; 

-- Update the ASR model configuration documentation
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/modelscope/FunASR/blob/main/runtime/docs/SDK_advanced_guide_online_zh.md',
`remark` = 'Standalone FunASR deployment using the FunASR API service takes only five commands
Step 1: mkdir -p ./funasr-runtime-resources/models
Step 2: sudo docker run -d -p 10096:10095 --privileged=true -v $PWD/funasr-runtime-resources/models:/workspace/models registry.cn-hangzhou.aliyuncs.com/funasr_repo/funasr:funasr-runtime-sdk-online-cpu-0.1.12
After the previous command you will be inside the container. Continue with step 3: cd FunASR/runtime
Do not exit the container. Continue in the container with step 4: nohup bash run_server_2pass.sh --download-model-dir /workspace/models --vad-dir damo/speech_fsmn_vad_zh-cn-16k-common-onnx --model-dir damo/speech_paraformer-large-vad-punc_asr_nat-zh-cn-16k-common-vocab8404-onnx  --online-model-dir damo/speech_paraformer-large_asr_nat-zh-cn-16k-common-vocab8404-online-onnx  --punc-dir damo/punc_ct-transformer_zh-cn-common-vad_realtime-vocab272727-onnx --lm-dir damo/speech_ngram_lm_zh-cn-ai-wesp-fst --itn-dir thuduj12/fst_itn_zh --hotword /workspace/models/hotwords.txt > log.txt 2>&1 &
After the previous command you will be inside the container. Continue with step 5: tail -f log.txt
After step 5 completes, you will see the model download log. Once the download finishes, you can connect and use it
The above uses CPU inference. If you have a GPU, see the details at: https://github.com/modelscope/FunASR/blob/main/runtime/docs/SDK_advanced_guide_online_zh.md' WHERE `id` = 'ASR_FunASRServer';

-- Update the FunASR local model configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/modelscope/FunASR',
`remark` = 'FunASR local model configuration notes:
1. You need to download the model files into the xiaozhi-server/models/SenseVoiceSmall directory
2. Supports Chinese, Japanese, Korean and Cantonese speech recognition
3. Local inference, no network connection required
4. Files to be recognized are saved in the tmp/ directory' WHERE `id` = 'ASR_FunASR';

-- Update the SherpaASR configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/k2-fsa/sherpa-onnx',
`remark` = 'SherpaASR configuration notes:
1. The model files are downloaded automatically at runtime into the models/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17 directory
2. Supports Chinese, English, Japanese, Korean, Cantonese and other languages
3. Local inference, no network connection required
4. Output files are saved in the tmp/ directory' WHERE `id` = 'ASR_SherpaASR';

-- Update the Doubao ASR configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/speech/app',
`remark` = 'Doubao ASR configuration notes:
1. You need to create an application in the Volcano Engine console and get the appid and access_token
2. Supports Chinese speech recognition
3. Network connection required
4. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://console.volcengine.com/speech/app
2. Create a new application
3. Get the appid and access_token
4. Fill them into the configuration file' WHERE `id` = 'ASR_DoubaoASR';

-- Update the Tencent ASR configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.cloud.tencent.com/cam/capi',
`remark` = 'Tencent ASR configuration notes:
1. You need to create an application in the Tencent Cloud console and get the appid, secret_id and secret_key
2. Supports Chinese speech recognition
3. Network connection required
4. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://console.cloud.tencent.com/cam/capi to get the keys
2. Visit https://console.cloud.tencent.com/asr/resourcebundle to claim free resources
3. Get the appid, secret_id and secret_key
4. Fill them into the configuration file' WHERE `id` = 'ASR_TencentASR';

-- Update the TTS model configuration notes
-- EdgeTTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/rany2/edge-tts',
`remark` = 'EdgeTTS configuration notes:
1. Uses the Microsoft Edge TTS service
2. Supports multiple languages and voices
3. Free to use, no registration required
4. Network connection required
5. Output files are saved in the tmp/ directory' WHERE `id` = 'TTS_EdgeTTS';

-- Doubao TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/speech/service/8',
`remark` = 'Doubao TTS configuration notes:
1. Access https://console.volcengine.com/speech/service/8
2. You need to create an application in the Volcano Engine console and get the appid and access_token
3. Volcano Engine speech must be paid for; the starting price is 30 CNY, which gives 100 concurrent connections. With the free tier you only get 2 concurrent connections and will often get TTS errors
4. After purchasing the service (including free voices), you may need to wait about half an hour before you can use it.
5. Fill them into the configuration file' WHERE `id` = 'TTS_DoubaoTTS';

-- SiliconFlow TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://cloud.siliconflow.cn/account/ak',
`remark` = 'SiliconFlow TTS configuration notes:
1. Access https://cloud.siliconflow.cn/account/ak
2. Register and get the API key
3. Fill them into the configuration file' WHERE `id` = 'TTS_CosyVoiceSiliconflow';

-- Coze Chinese TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://www.coze.cn/open/oauth/pats',
`remark` = 'Coze Chinese TTS configuration notes:
1. Access https://www.coze.cn/open/oauth/pats
2. Get a personal token
3. Fill them into the configuration file' WHERE `id` = 'TTS_CozeCnTTS';

-- FishSpeech configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/fishaudio/fish-speech',
`remark` = 'FishSpeech configuration notes:
1. FishSpeech service must be deployed locally
2. Supports custom voices
3. Local inference, no network connection required
4. Output files are saved in the tmp/ directory
5. Example command to run the service: python -m tools.api_server --listen 0.0.0.0:8080 --llama-checkpoint-path "checkpoints/fish-speech-1.5" --decoder-checkpoint-path "checkpoints/fish-speech-1.5/firefly-gan-vq-fsq-8x1024-21hz-generator.pth" --decoder-config-name firefly_gan_vq --compile' WHERE `id` = 'TTS_FishSpeech';

-- GPT-SoVITS V2 configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/RVC-Boss/GPT-SoVITS',
`remark` = 'GPT-SoVITS V2 configuration notes:
1. GPT-SoVITS service must be deployed locally
2. Supports custom voice cloning
3. Local inference, no network connection required
4. Output files are saved in the tmp/ directory
Deployment steps:
1. Example command to run the service: python api_v2.py -a 127.0.0.1 -p 9880 -c GPT_SoVITS/configs/demo.yaml' WHERE `id` = 'TTS_GPT_SOVITS_V2';

-- GPT-SoVITS V3 configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/RVC-Boss/GPT-SoVITS',
`remark` = 'GPT-SoVITS V3 configuration notes:
1. GPT-SoVITS V3 service must be deployed locally
2. Supports custom voice cloning
3. Local inference, no network connection required
4. Output files are saved in the tmp/ directory' WHERE `id` = 'TTS_GPT_SOVITS_V3';

-- MiniMax TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://platform.minimaxi.com/',
`remark` = 'MiniMax TTS configuration notes:
1. You need to create an account on the MiniMax platform and top up
2. Supports multiple voices; the current configuration uses female-shaonv
3. Network connection required
4. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://platform.minimaxi.com/ to register an account
2. Visit https://platform.minimaxi.com/user-center/payment/balance to top up
3. Visit https://platform.minimaxi.com/user-center/basic-information to get the group_id
4. Visit https://platform.minimaxi.com/user-center/basic-information/interface-key to get the api_key
5. Fill them into the configuration file' WHERE `id` = 'TTS_MinimaxTTS';

-- Alibaba Cloud TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://nls-portal.console.aliyun.com/',
`remark` = 'Alibaba Cloud TTS configuration notes:
1. You need to activate the Intelligent Speech Interaction service on the Alibaba Cloud platform
2. Supports multiple voices; the current configuration uses xiaoyun
3. Network connection required
4. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://nls-portal.console.aliyun.com/ to activate the service
2. Visit https://nls-portal.console.aliyun.com/applist to get the appkey
3. Visit https://nls-portal.console.aliyun.com/overview to get the token
4. Fill them into the configuration file
Note: the token is temporary and valid for 24 hours; for long-term use you need to configure access_key_id and access_key_secret' WHERE `id` = 'TTS_AliyunTTS';

-- Tencent TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.cloud.tencent.com/cam/capi',
`remark` = 'Tencent TTS configuration notes:
1. You need to activate the Intelligent Speech Interaction service on the Tencent Cloud platform
2. Supports multiple voices; the current configuration uses 101001
3. Network connection required
4. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://console.cloud.tencent.com/cam/capi to get the keys
2. Visit https://console.cloud.tencent.com/tts/resourcebundle to claim free resources
3. Create a new application
4. Get the appid, secret_id and secret_key
5. Fill them into the configuration file' WHERE `id` = 'TTS_TencentTTS';

-- 302AI TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://dash.302.ai/',
`remark` = '302AI TTS configuration notes:
1. You need to create an account on the 302 platform and get an API key
2. Supports multiple voices; the current configuration uses the Wanwan Xiaohe voice
3. Network connection required
4. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://dash.302.ai/ to register an account
2. Visit https://dash.302.ai/apis/list to get the API key
3. Fill them into the configuration file
Price: $35/million characters' WHERE `id` = 'TTS_TTS302AI';

-- Gizwits TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://agentrouter.gizwitsapi.com/panel/token',
`remark` = 'Gizwits TTS configuration notes:
1. You need to get an API key on the Gizwits platform
2. Supports multiple voices; the current configuration uses the Wanwan Xiaohe voice
3. Network connection required
4. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://agentrouter.gizwitsapi.com/panel/token to get the API key
2. Fill them into the configuration file
Note: the first 10,000 registered users will receive 5 CNY of trial credit' WHERE `id` = 'TTS_GizwitsTTS';

-- ACGN TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://acgn.ttson.cn/',
`remark` = 'ACGN TTS configuration notes:
1. You need to buy a token on the ttson platform
2. Supports multiple character voices; the current configuration uses character ID: 1695
3. Network connection required
4. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://acgn.ttson.cn/ to view the character list
2. Visit www.ttson.cn to buy a token
3. Fill them into the configuration file
For development-related questions, please contact the QQ number listed on the website' WHERE `id` = 'TTS_ACGNTTS';

-- OpenAI TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://platform.openai.com/api-keys',
`remark` = 'OpenAI TTS configuration notes:
1. You need to get an API key on the OpenAI platform
2. Supports multiple voices; the current configuration uses onyx
3. Network connection required
4. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://platform.openai.com/api-keys to get the API key
2. Fill them into the configuration file
Note: access from mainland China requires a proxy' WHERE `id` = 'TTS_OpenAITTS';

-- Custom TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = NULL,
`remark` = 'Custom TTS configuration notes:
1. Supports custom TTS API services
2. Uses GET requests
3. Network connection required
4. Output files are saved in the tmp/ directory
Configuration notes:
1. Configure the request parameters in params
2. Configure the request headers in headers
3. Set the returned audio format' WHERE `id` = 'TTS_CustomTTS';

-- Volcano Engine edge LLM gateway TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/vei/aigateway/',
`remark` = 'Volcano Engine edge LLM gateway TTS configuration notes:
1. Access https://console.volcengine.com/vei/aigateway/
2. Create a gateway access key, then search for and select Doubao-Speech Synthesis
3. If you need an LLM, also select Doubao-pro-32k-functioncall
4. Visit https://console.volcengine.com/vei/aigateway/tokens-list to get the key
5. Fill them into the configuration file
Voice list reference: https://www.volcengine.com/docs/6561/1257544' WHERE `id` = 'TTS_VolcesAiGatewayTTS';

-- Update the LLM model configuration notes
-- ChatGLM configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://bigmodel.cn/usercenter/proj-mgmt/apikeys',
`remark` = 'ChatGLM configuration notes:
1. Access https://bigmodel.cn/usercenter/proj-mgmt/apikeys
2. Register and get the API key
3. Fill them into the configuration file' WHERE `id` = 'LLM_ChatGLMLLM';

-- Ollama configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://ollama.com/',
`remark` = 'Ollama configuration notes:
1. Install the Ollama service
2. Run the command: ollama pull qwen2.5
3. Make sure the service is running at http://localhost:11434' WHERE `id` = 'LLM_OllamaLLM';

-- Tongyi Qianwen configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://bailian.console.aliyun.com/?apiKey=1#/api-key',
`remark` = 'Tongyi Qianwen configuration notes:
1. Access https://bailian.console.aliyun.com/?apiKey=1#/api-key
2. Get the API key
3. Fill it into the configuration file; the current configuration uses the qwen-turbo model
4. Supports custom parameters: temperature=0.7, max_tokens=500, top_p=1, top_k=50' WHERE `id` = 'LLM_AliLLM';

-- Tongyi Bailian configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://bailian.console.aliyun.com/?apiKey=1#/api-key',
`remark` = 'Tongyi Bailian configuration notes:
1. Access https://bailian.console.aliyun.com/?apiKey=1#/api-key
2. Get the app_id and api_key
3. Fill them into the configuration file' WHERE `id` = 'LLM_AliAppLLM';

-- Doubao LLM configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement',
`remark` = 'Doubao LLM configuration notes:
1. Access https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement
2. Activate the Doubao-1.5-pro service
3. Visit https://console.volcengine.com/ark/region:ark+cn-beijing/apiKey to get the API key
4. Fill them into the configuration file
5. It is currently recommended to use doubao-1-5-pro-32k-250115
Note: there is a free quota of 500000 tokens' WHERE `id` = 'LLM_DoubaoLLM';

-- DeepSeek configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://platform.deepseek.com/',
`remark` = 'DeepSeek configuration notes:
1. Access https://platform.deepseek.com/
2. Register and get the API key
3. Fill them into the configuration file' WHERE `id` = 'LLM_DeepSeekLLM';

-- Dify configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://cloud.dify.ai/',
`remark` = 'Dify configuration notes:
1. Access https://cloud.dify.ai/
2. Register and get the API key
3. Fill them into the configuration file
4. Supports multiple conversation modes: workflows/run, chat-messages, completion-messages
5. Role definitions set on the platform will not take effect; they must be set in the Dify console
Note: it is recommended to use a locally deployed Dify API; access to the public cloud API from some regions of mainland China may be restricted' WHERE `id` = 'LLM_DifyLLM';

-- Gemini configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://aistudio.google.com/apikey',
`remark` = 'Gemini configuration notes:
1. Uses the Google Gemini API service
2. The current configuration uses the gemini-2.0-flash model
3. Network connection required
4. Proxy configuration is supported
Application steps:
1. Visit https://aistudio.google.com/apikey
2. Create an API key
3. Fill them into the configuration file
Note: if used within China, please comply with the "Interim Measures for the Administration of Generative Artificial Intelligence Services"' WHERE `id` = 'LLM_GeminiLLM';

-- Coze configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://www.coze.cn/open/oauth/pats',
`remark` = 'Coze configuration notes:
1. Uses the Coze platform service
2. Requires bot_id, user_id and a personal token
3. Network connection required
Application steps:
1. Access https://www.coze.cn/open/oauth/pats
2. Get a personal token
3. Work out the bot_id and user_id manually
4. Fill them into the configuration file' WHERE `id` = 'LLM_CozeLLM';

-- LM Studio configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://lmstudio.ai/',
`remark` = 'LM Studio configuration notes:
1. Uses a locally deployed LM Studio service
2. The current configuration uses the deepseek-r1-distill-llama-8b@q4_k_m model
3. Local inference, no network connection required
4. The model must be downloaded in advance
Deployment steps:
1. Install LM Studio
2. Download the model from the community
3. Make sure the service is running at http://localhost:1234/v1' WHERE `id` = 'LLM_LMStudioLLM';

-- FastGPT configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://cloud.tryfastgpt.ai/account/apikey',
`remark` = 'FastGPT configuration notes:
1. Uses the FastGPT platform service
2. Network connection required
3. The prompt in the configuration file has no effect; it must be set in the FastGPT console
4. Supports custom variables
Application steps:
1. Access https://cloud.tryfastgpt.ai/account/apikey
2. Get the API key
3. Fill them into the configuration file' WHERE `id` = 'LLM_FastgptLLM';

-- Xinference configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/xorbitsai/inference',
`remark` = 'Xinference configuration notes:
1. Uses a locally deployed Xinference service
2. The current configuration uses the qwen2.5:72b-AWQ model
3. Local inference, no network connection required
4. The corresponding model must be started in advance
Deployment steps:
1. Install Xinference
2. Start the service and load the model
3. Make sure the service is running at http://localhost:9997' WHERE `id` = 'LLM_XinferenceLLM';

-- Xinference small model configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/xorbitsai/inference',
`remark` = 'Xinference small model configuration notes:
1. Uses a locally deployed Xinference service
2. The current configuration uses the qwen2.5:3b-AWQ model
3. Local inference, no network connection required
4. Used for intent recognition
Deployment steps:
1. Install Xinference
2. Start the service and load the model
3. Make sure the service is running at http://localhost:9997' WHERE `id` = 'LLM_XinferenceSmallLLM';

-- Volcano Engine edge LLM gateway LLM configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/vei/aigateway/',
`remark` = 'Volcano Engine edge LLM gateway LLM configuration notes:
1. Uses the Volcano Engine edge LLM gateway service
2. A gateway access key is required
3. Network connection required
4. Supports the function_call feature
Application steps:
1. Access https://console.volcengine.com/vei/aigateway/
2. Create a gateway access key, then search for and select Doubao-pro-32k-functioncall
3. If you need speech synthesis, also select Doubao-Speech Synthesis
4. Visit https://console.volcengine.com/vei/aigateway/tokens-list to get the key
5. Fill them into the configuration file' WHERE `id` = 'LLM_VolcesAiGatewayLLM';

-- Update the Memory model configuration notes
-- No-memory configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = NULL,
`remark` = 'No-memory configuration notes:
1. Conversation history is not saved
2. Every conversation is independent
3. No additional configuration required
4. Suitable for scenarios with high privacy requirements' WHERE `id` = 'Memory_nomem';

-- Local short-term memory configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = NULL,
`remark` = 'Local short-term memory configuration notes:
1. Uses local storage to save the conversation history
2. Summarizes the conversation using the llm of selected_module
3. Data is stored locally and is not uploaded to the server
4. Suitable for privacy-conscious scenarios
5. No additional configuration required' WHERE `id` = 'Memory_mem_local_short';

-- Mem0AI memory configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://app.mem0.ai/dashboard/api-keys',
`remark` = 'Mem0AI memory configuration notes:
1. Uses the Mem0AI service to save the conversation history
2. An API key is required
3. Network connection required
4. 1000 free calls per month
Application steps:
1. Access https://app.mem0.ai/dashboard/api-keys
2. Get the API key
3. Fill them into the configuration file' WHERE `id` = 'Memory_mem0ai';

-- Update the Intent model configuration notes
-- No-intent-recognition configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = NULL,
`remark` = 'No-intent-recognition configuration notes:
1. No intent recognition is performed
2. All conversations are passed directly to the LLM
3. No additional configuration required
4. Suitable for simple conversation scenarios' WHERE `id` = 'Intent_nointent';

-- LLM intent recognition configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = NULL,
`remark` = 'LLM intent recognition configuration notes:
1. Uses a separate LLM for intent recognition
2. Uses the model of selected_module.LLM by default
3. A separate LLM can be configured (for example the free ChatGLMLLM)
4. Highly general, but increases processing time
5. Does not support iot operations such as volume control
Configuration notes:
1. Specify the LLM model to use in the llm field
2. If not specified, the model of selected_module.LLM is used' WHERE `id` = 'Intent_intent_llm';

-- Function-call intent recognition configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = NULL,
`remark` = 'Function-call intent recognition configuration notes:
1. Uses the function_call feature of the LLM for intent recognition
2. The selected LLM must support function_call
3. Tools are called on demand, so processing is fast
4. Supports all iot commands
5. The following features are loaded by default:
   - handle_exit_intent (exit recognition)
   - play_music (music playback)
   - change_role (role switching)
   - get_weather (weather query)
   - get_news (news query)
Configuration notes:
1. Configure the feature modules to load in the functions field
2. The basic features are loaded by default, so no need to configure them again
3. Custom feature modules can be added' WHERE `id` = 'Intent_function_call';

-- Update the VAD model configuration notes
-- SileroVAD configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/snakers4/silero-vad',
`remark` = 'SileroVAD configuration notes:
1. Uses the SileroVAD model for voice activity detection
2. Local inference, no network connection required
3. You need to download the model files into the models/snakers4_silero-vad directory
4. Configurable parameters:
   - threshold: 0.5 (voice detection threshold)
   - min_silence_duration_ms: 700 (minimum silence duration, in milliseconds)
5. If the speaker pauses for a long time, you can increase the value of min_silence_duration_ms appropriately' WHERE `id` = 'VAD_SileroVAD';
-- ===== end 202504291043.sql =====

-- ===== begin 202504301341.sql =====
update `ai_model_provider` set `fields` = 
'[{"key": "api_url","label": "API address","type": "string"},{"key": "voice","label": "Voice","type": "string"},{"key": "output_dir","label": "Output directory","type": "string"},{"key": "authorization","label": "Authorization","type": "string"},{"key": "appid","label": "App ID","type": "string"},{"key": "access_token","label": "Access token","type": "string"},{"key": "cluster","label": "Cluster","type": "string"},{"key": "speed_ratio","label": "Speech rate","type": "number"},{"key": "volume_ratio","label": "Volume","type": "number"},{"key": "pitch_ratio","label": "Pitch","type": "number"}]'
where `id` = 'SYSTEM_TTS_doubao';

-- Add Alibaba Cloud ASR provider
delete from `ai_model_provider` where `id` = 'SYSTEM_ASR_AliyunASR';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_AliyunASR', 'ASR', 'aliyun', 'Alibaba Cloud speech recognition', '[{"key":"appkey","label":"App AppKey","type":"string"},{"key":"token","label":"Temporary Token","type":"string"},{"key":"access_key_id","label":"AccessKey ID","type":"string"},{"key":"access_key_secret","label":"AccessKey Secret","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]', 5, 1, NOW(), 1, NOW());

-- Add Alibaba Cloud ASR Model configuration
delete from `ai_model_config` where `id` = 'ASR_AliyunASR';
INSERT INTO `ai_model_config` VALUES ('ASR_AliyunASR', 'ASR', 'AliyunASR', 'Alibaba Cloud speech recognition', 0, 1, '{\"type\": \"aliyun\", \"appkey\": \"\", \"token\": \"\", \"access_key_id\": \"\", \"access_key_secret\": \"\", \"output_dir\": \"tmp/\"}', NULL, NULL, 6, NULL, NULL, NULL, NULL);

-- Update the Alibaba Cloud ASR model configuration documentation
UPDATE `ai_model_config` SET 
`doc_link` = 'https://nls-portal.console.aliyun.com/',
`remark` = 'Alibaba Cloud ASR configuration notes:
1. Visit https://nls-portal.console.aliyun.com/ to activate the service
2. Visit https://nls-portal.console.aliyun.com/applist to get the appkey
3. Visit https://nls-portal.console.aliyun.com/overview to get the token
4. Get the access_key_id and access_key_secret
5. Fill them into the configuration file' WHERE `id` = 'ASR_AliyunASR';

-- Insert firmware type dictionary type
delete from `sys_dict_type` where `id` = 101;
INSERT INTO `sys_dict_type` (`id`, `dict_type`, `dict_name`, `remark`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES 
(101, 'FIRMWARE_TYPE', 'Firmware type', 'Firmware type dictionary', 0, 1, NOW(), 1, NOW());

-- Insert firmware type dictionary data
delete from `sys_dict_data` where `dict_type_id` = 101;
INSERT INTO `sys_dict_data` (`id`, `dict_type_id`, `dict_label`, `dict_value`, `remark`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES 
(101001, 101, 'Breadboard new wiring (WiFi)', 'bread-compact-wifi', 'Breadboard new wiring (WiFi)', 1, 1, NOW(), 1, NOW()),
(101002, 101, 'Breadboard new wiring (WiFi)+ LCD', 'bread-compact-wifi-lcd', 'Breadboard new wiring (WiFi)+ LCD', 2, 1, NOW(), 1, NOW()),
(101003, 101, 'Breadboard new wiring (ML307 AT)', 'bread-compact-ml307', 'Breadboard new wiring (ML307 AT)', 3, 1, NOW(), 1, NOW()),
(101004, 101, 'Breadboard (WiFi) ESP32 DevKit', 'bread-compact-esp32', 'Breadboard (WiFi) ESP32 DevKit', 4, 1, NOW(), 1, NOW()),
(101005, 101, 'Breadboard (WiFi+ LCD) ESP32 DevKit', 'bread-compact-esp32-lcd', 'Breadboard (WiFi+ LCD) ESP32 DevKit', 5, 1, NOW(), 1, NOW()),
(101006, 101, 'DFRobot Unihiker k10', 'df-k10', 'DFRobot Unihiker k10', 6, 1, NOW(), 1, NOW()),
(101007, 101, 'ESP32 CGC', 'esp32-cgc', 'ESP32 CGC', 7, 1, NOW(), 1, NOW()),
(101008, 101, 'ESP BOX 3', 'esp-box-3', 'ESP BOX 3', 8, 1, NOW(), 1, NOW()),
(101009, 101, 'ESP BOX', 'esp-box', 'ESP BOX', 9, 1, NOW(), 1, NOW()),
(101010, 101, 'ESP BOX Lite', 'esp-box-lite', 'ESP BOX Lite', 10, 1, NOW(), 1, NOW()),
(101011, 101, 'Kevin Box 1', 'kevin-box-1', 'Kevin Box 1', 11, 1, NOW(), 1, NOW()),
(101012, 101, 'Kevin Box 2', 'kevin-box-2', 'Kevin Box 2', 12, 1, NOW(), 1, NOW()),
(101013, 101, 'Kevin C3', 'kevin-c3', 'Kevin C3', 13, 1, NOW(), 1, NOW()),
(101014, 101, 'Kevin SP V3 dev board', 'kevin-sp-v3-dev', 'Kevin SP V3 dev board', 14, 1, NOW(), 1, NOW()),
(101015, 101, 'Kevin SP V4 dev board', 'kevin-sp-v4-dev', 'Kevin SP V4 dev board', 15, 1, NOW(), 1, NOW()),
(101016, 101, 'Osprey Technology 3.13LCD dev board', 'kevin-yuying-313lcd', 'Osprey Technology 3.13LCD dev board', 16, 1, NOW(), 1, NOW()),
(101017, 101, 'LCSC·Shizhanpai ESP32-S3 dev board', 'lichuang-dev', 'LCSC·Shizhanpai ESP32-S3 dev board', 17, 1, NOW(), 1, NOW()),
(101018, 101, 'LCSC·Shizhanpai ESP32-C3 dev board', 'lichuang-c3-dev', 'LCSC·Shizhanpai ESP32-C3 dev board', 18, 1, NOW(), 1, NOW()),
(101019, 101, 'Magic Button Magiclick_2.4', 'magiclick-2p4', 'Magic Button Magiclick_2.4', 19, 1, NOW(), 1, NOW()),
(101020, 101, 'Magic Button Magiclick_2.5', 'magiclick-2p5', 'Magic Button Magiclick_2.5', 20, 1, NOW(), 1, NOW()),
(101021, 101, 'Magic Button Magiclick_C3', 'magiclick-c3', 'Magic Button Magiclick_C3', 21, 1, NOW(), 1, NOW()),
(101022, 101, 'Magic Button Magiclick_C3_v2', 'magiclick-c3-v2', 'Magic Button Magiclick_C3_v2', 22, 1, NOW(), 1, NOW()),
(101023, 101, 'M5Stack CoreS3', 'm5stack-core-s3', 'M5Stack CoreS3', 23, 1, NOW(), 1, NOW()),
(101024, 101, 'AtomS3 + Echo Base', 'atoms3-echo-base', 'AtomS3 + Echo Base', 24, 1, NOW(), 1, NOW()),
(101025, 101, 'AtomS3R + Echo Base', 'atoms3r-echo-base', 'AtomS3R + Echo Base', 25, 1, NOW(), 1, NOW()),
(101026, 101, 'AtomS3R CAM/M12 + Echo Base', 'atoms3r-cam-m12-echo-base', 'AtomS3R CAM/M12 + Echo Base', 26, 1, NOW(), 1, NOW()),
(101027, 101, 'AtomMatrix + Echo Base', 'atommatrix-echo-base', 'AtomMatrix + Echo Base', 27, 1, NOW(), 1, NOW()),
(101028, 101, 'Xiage Mini C3', 'xmini-c3', 'Xiage Mini C3', 28, 1, NOW(), 1, NOW()),
(101029, 101, 'ESP32S3_KORVO2_V3 dev board', 'esp32s3-korvo2-v3', 'ESP32S3_KORVO2_V3 dev board', 29, 1, NOW(), 1, NOW()),
(101030, 101, 'ESP-SparkBot dev board', 'esp-sparkbot', 'ESP-SparkBot dev board', 30, 1, NOW(), 1, NOW()),
(101031, 101, 'ESP-Spot-S3', 'esp-spot-s3', 'ESP-Spot-S3', 31, 1, NOW(), 1, NOW()),
(101032, 101, 'Waveshare ESP32-S3-Touch-AMOLED-1.8', 'esp32-s3-touch-amoled-1.8', 'Waveshare ESP32-S3-Touch-AMOLED-1.8', 32, 1, NOW(), 1, NOW()),
(101033, 101, 'Waveshare ESP32-S3-Touch-LCD-1.85C', 'esp32-s3-touch-lcd-1.85c', 'Waveshare ESP32-S3-Touch-LCD-1.85C', 33, 1, NOW(), 1, NOW()),
(101034, 101, 'Waveshare ESP32-S3-Touch-LCD-1.85', 'esp32-s3-touch-lcd-1.85', 'Waveshare ESP32-S3-Touch-LCD-1.85', 34, 1, NOW(), 1, NOW()),
(101035, 101, 'Waveshare ESP32-S3-Touch-LCD-1.46', 'esp32-s3-touch-lcd-1.46', 'Waveshare ESP32-S3-Touch-LCD-1.46', 35, 1, NOW(), 1, NOW()),
(101036, 101, 'Waveshare ESP32-S3-Touch-LCD-3.5', 'esp32-s3-touch-lcd-3.5', 'Waveshare ESP32-S3-Touch-LCD-3.5', 36, 1, NOW(), 1, NOW()),
(101037, 101, 'Tudouzi', 'tudouzi', 'Tudouzi', 37, 1, NOW(), 1, NOW()),
(101038, 101, 'LILYGO T-Circle-S3', 'lilygo-t-circle-s3', 'LILYGO T-Circle-S3', 38, 1, NOW(), 1, NOW()),
(101039, 101, 'LILYGO T-CameraPlus-S3', 'lilygo-t-cameraplus-s3', 'LILYGO T-CameraPlus-S3', 39, 1, NOW(), 1, NOW()),
(101040, 101, 'Movecall Moji Xiaozhi AI derivative edition', 'movecall-moji-esp32s3', 'Movecall Moji Xiaozhi AI derivative edition', 40, 1, NOW(), 1, NOW()),
(101041, 101, 'Movecall CuiCan Brilliant·AI Pendant', 'movecall-cuican-esp32s3', 'Movecall CuiCan Brilliant·AI Pendant', 41, 1, NOW(), 1, NOW()),
(101042, 101, 'ALIENTEK DNESP32S3 dev board', 'atk-dnesp32s3', 'ALIENTEK DNESP32S3 dev board', 42, 1, NOW(), 1, NOW()),
(101043, 101, 'ALIENTEK DNESP32S3-BOX', 'atk-dnesp32s3-box', 'ALIENTEK DNESP32S3-BOX', 43, 1, NOW(), 1, NOW()),
(101044, 101, 'Dudu dev board CHATX(wifi)', 'du-chatx', 'Dudu dev board CHATX(wifi)', 44, 1, NOW(), 1, NOW()),
(101045, 101, 'Taiji Pi esp32s3', 'taiji-pi-s3', 'Taiji Pi esp32s3', 45, 1, NOW(), 1, NOW()),
(101046, 101, 'Nologo Technology Xingzhi 0.85(WIFI)', 'xingzhi-cube-0.85tft-wifi', 'Nologo Technology Xingzhi 0.85(WIFI)', 46, 1, NOW(), 1, NOW()),
(101047, 101, 'Nologo Technology Xingzhi 0.85(ML307)', 'xingzhi-cube-0.85tft-ml307', 'Nologo Technology Xingzhi 0.85(ML307)', 47, 1, NOW(), 1, NOW()),
(101048, 101, 'Nologo Technology Xingzhi 0.96(WIFI)', 'xingzhi-cube-0.96oled-wifi', 'Nologo Technology Xingzhi 0.96(WIFI)', 48, 1, NOW(), 1, NOW()),
(101049, 101, 'Nologo Technology Xingzhi 0.96(ML307)', 'xingzhi-cube-0.96oled-ml307', 'Nologo Technology Xingzhi 0.96(ML307)', 49, 1, NOW(), 1, NOW()),
(101050, 101, 'Nologo Technology Xingzhi 1.54(WIFI)', 'xingzhi-cube-1.54tft-wifi', 'Nologo Technology Xingzhi 1.54(WIFI)', 50, 1, NOW(), 1, NOW()),
(101051, 101, 'Nologo Technology Xingzhi 1.54(ML307)', 'xingzhi-cube-1.54tft-ml307', 'Nologo Technology Xingzhi 1.54(ML307)', 51, 1, NOW(), 1, NOW()),
(101052, 101, 'SenseCAP Watcher', 'sensecap-watcher', 'SenseCAP Watcher', 52, 1, NOW(), 1, NOW()),
(101053, 101, 'Doit AI Companion Box', 'doit-s3-aibox', 'Doit AI Companion Box', 53, 1, NOW(), 1, NOW()),
(101054, 101, 'Yuankong·Youth', 'mixgo-nova', 'Yuankong·Youth', 54, 1, NOW(), 1, NOW());
-- ===== end 202504301341.sql =====

-- ===== begin 202505022134.sql =====
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
-- ===== end 202505022134.sql =====

-- ===== begin 202505081146.sql =====
-- Add Baidu ASR Model configuration
delete from `ai_model_config` where `id` = 'ASR_BaiduASR';
INSERT INTO `ai_model_config` VALUES ('ASR_BaiduASR', 'ASR', 'BaiduASR', 'Baidu speech recognition', 0, 1, '{\"type\": \"baidu\", \"app_id\": \"\", \"api_key\": \"\", \"secret_key\": \"\", \"dev_pid\": 1537, \"output_dir\": \"tmp/\"}', NULL, NULL, 7, NULL, NULL, NULL, NULL);


-- Add Baidu ASR provider
delete from `ai_model_provider` where `id` = 'SYSTEM_ASR_BaiduASR';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_BaiduASR', 'ASR', 'baidu', 'Baidu speech recognition', '[{"key":"app_id","label":"App AppID","type":"string"},{"key":"api_key","label":"API Key","type":"string"},{"key":"secret_key","label":"Secret Key","type":"string"},{"key":"dev_pid","label":"Language parameter","type":"number"},{"key":"output_dir","label":"Output directory","type":"string"}]', 7, 1, NOW(), 1, NOW());


-- Update Baidu ASR configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.bce.baidu.com/ai-engine/old/#/ai/speech/app/list',
`remark` = 'Baidu ASR Configuration notes:
1. Access https://console.bce.baidu.com/ai-engine/old/#/ai/speech/app/list
2. Create a new application
3. Get the AppID, API Key and Secret Key
4. Fill them into the configuration file
View the resource quota: https://console.bce.baidu.com/ai-engine/old/#/ai/speech/overview/resource/list
Language parameter notes: https://ai.baidu.com/ai-doc/SPEECH/0lbxfnc9b
' WHERE `id` = 'ASR_BaiduASR';

-- Update the Doubao provider fields
update `ai_model_provider` set `fields` = 
'[{"key":"appid","label":"App ID","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"cluster","label":"Cluster","type":"string"},{"key":"boosting_table_name","label":"Hot word file name","type":"string"},{"key":"correct_table_name","label":"Replacement word file name","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]'
where `id` = 'SYSTEM_ASR_DoubaoASR';

-- Update the Doubao ASR configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/speech/app',
`remark` = 'Doubao ASR configuration notes:
1. You need to create an application in the Volcano Engine console and get the appid and access_token
2. Supports Chinese speech recognition
3. Network connection required
4. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://console.volcengine.com/speech/app
2. Create a new application
3. Get the appid and access_token
4. Fill them into the configuration file
To set hot words, see: https://www.volcengine.com/docs/6561/155738
' WHERE `id` = 'ASR_DoubaoASR';
-- ===== end 202505081146.sql =====

-- ===== begin 202505091555.sql =====
-- Update the model provider table
UPDATE `ai_model_provider` SET fields = '[{"key": "host", "type": "string", "label": "Service address"}, {"key": "port", "type": "number", "label": "Port"}, {"key": "type", "type": "string", "label": "Service type"}, {"key": "is_ssl", "type": "boolean", "label": "Whether to use SSL"}, {"key": "api_key", "type": "string", "label": "API key"}, {"key": "output_dir", "type": "string", "label": "Output directory"}]' WHERE id = 'SYSTEM_ASR_FunASRServer';

-- Update the model configuration table
UPDATE `ai_model_config` SET 
config_json = '{"host": "127.0.0.1", "port": 10096, "type": "fun_server", "is_ssl": true, "api_key": "none", "output_dir": "tmp/"}',
`doc_link` = 'https://github.com/modelscope/FunASR/blob/main/runtime/docs/SDK_advanced_guide_online_zh.md',
`remark` = 'Standalone FunASR deployment using the FunASR API service takes only five commands
Step 1: mkdir -p ./funasr-runtime-resources/models
Step 2: sudo docker run -p 10096:10095 -it --privileged=true -v $PWD/funasr-runtime-resources/models:/workspace/models registry.cn-hangzhou.aliyuncs.com/funasr_repo/funasr:funasr-runtime-sdk-online-cpu-0.1.12
After the previous command you will be inside the container. Continue with step 3: cd FunASR/runtime
Do not exit the container. Continue in the container with step 4: nohup bash run_server_2pass.sh --download-model-dir /workspace/models --vad-dir damo/speech_fsmn_vad_zh-cn-16k-common-onnx --model-dir damo/speech_paraformer-large-vad-punc_asr_nat-zh-cn-16k-common-vocab8404-onnx  --online-model-dir damo/speech_paraformer-large_asr_nat-zh-cn-16k-common-vocab8404-online-onnx  --punc-dir damo/punc_ct-transformer_zh-cn-common-vad_realtime-vocab272727-onnx --lm-dir damo/speech_ngram_lm_zh-cn-ai-wesp-fst --itn-dir thuduj12/fst_itn_zh --hotword /workspace/models/hotwords.txt > log.txt 2>&1 &
After the previous command you will be inside the container. Continue with step 5: tail -f log.txt
After step 5 completes, you will see the model download log. Once the download finishes, you can connect and use it
The above uses CPU inference. If you have a GPU, see the details at: https://github.com/modelscope/FunASR/blob/main/runtime/docs/SDK_advanced_guide_online_zh.md' WHERE `id` = 'ASR_FunASRServer';

-- FishSpeech configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/xinnan-tech/xiaozhi-esp32-server/blob/main/docs/fish-speech-integration.md',
`remark` = 'FishSpeech configuration notes:
1. FishSpeech service must be deployed locally
2. Supports custom voices
3. Local inference, no network connection required
4. Output files are saved in the tmp/ directory
5. See the tutorial at https://github.com/xinnan-tech/xiaozhi-esp32-server/blob/main/docs/fish-speech-integration.md' WHERE `id` = 'TTS_FishSpeech';
-- ===== end 202505091555.sql =====

-- ===== begin 202505111914.sql =====
-- Add the chat history configuration column
ALTER TABLE `ai_agent` 
ADD COLUMN `chat_history_conf` tinyint NOT NULL DEFAULT 0 COMMENT 'Chat history configuration (0 Do not record 1 Text only 2 record text and voice)' AFTER `system_prompt`;

ALTER TABLE `ai_agent_template` 
ADD COLUMN `chat_history_conf` tinyint NOT NULL DEFAULT 0 COMMENT 'Chat history configuration (0 Do not record 1 Text only 2 record text and voice)' AFTER `system_prompt`;
-- ===== end 202505111914.sql =====

-- ===== begin 202505122348.sql =====
-- Add the summary memory column
ALTER TABLE `ai_agent`
ADD COLUMN `summary_memory` text COMMENT 'Summary memory' AFTER `system_prompt`;

ALTER TABLE `ai_agent_template`
ADD COLUMN `summary_memory` text COMMENT 'Summary memory' AFTER `system_prompt`;
-- ===== end 202505122348.sql =====

-- ===== begin 202505142037.sql =====
update ai_agent_template set system_prompt = replace(system_prompt, 'I am', 'You are');

delete from sys_params where id in (500,501,402);
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (500, 'end_prompt.enable', 'true', 'boolean', 1, 'Whether to enable the closing message');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (501, 'end_prompt.prompt', 'Please end this conversation with warm, reluctant words, starting with "Time flies".', 'string', 1, 'End prompt');

INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (402, 'plugins.get_weather.api_host', 'mj7p3y7naa.re.qweatherapi.com', 'string', 1, 'Developer apihost');
-- ===== end 202505142037.sql =====

-- ===== begin 202505182234.sql =====
-- Add the parameters required by the mobile SMS registration feature
delete from sys_params where id in (108, 109, 110, 111, 112, 113, 114, 115);
delete from sys_params where id in (610, 611, 612, 613);
INSERT INTO sys_params
(id, param_code, param_value, value_type, param_type, remark, creator, create_date, updater, update_date)
    VALUES
(108, 'server.name', 'xiaozhi-esp32-server', 'string', 1, 'System name', NULL, NULL, NULL, NULL),
(109, 'server.beian_icp_num', 'null', 'string', 1, 'icp filing number; fill in null to leave it unset', NULL, NULL, NULL, NULL),
(110, 'server.beian_ga_num', 'null', 'string', 1, 'public security filing number; fill in null to leave it unset', NULL, NULL, NULL, NULL),
(111, 'server.enable_mobile_register', 'false', 'boolean', 1, 'Whether to enable mobile registration', NULL, NULL, NULL, NULL),
(112, 'server.sms_max_send_count', '10', 'number', 1, 'Maximum number of SMS messages per phone number per day', NULL, NULL, NULL, NULL),
(610, 'aliyun.sms.access_key_id', '', 'string', 1, 'Alibaba Cloud platform access_key', NULL, NULL, NULL, NULL),
(611, 'aliyun.sms.access_key_secret', '', 'string', 1, 'Alibaba Cloud platform access_key_secret', NULL, NULL, NULL, NULL),
(612, 'aliyun.sms.sign_name', '', 'string', 1, 'Alibaba Cloud SMS signature', NULL, NULL, NULL, NULL),
(613, 'aliyun.sms.sms_code_template_code', '', 'string', 1, 'Alibaba Cloud SMS template', NULL, NULL, NULL, NULL);

update sys_params set remark = 'Whether people other than administrators may register' where param_code = 'server.allow_user_register';

-- Add the mobile region dictionary
-- Insert firmware type dictionary type
delete from `sys_dict_type` where `id` = 102;
INSERT INTO `sys_dict_type` (`id`, `dict_type`, `dict_name`, `remark`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES 
(102, 'MOBILE_AREA', 'Mobile region', 'Mobile region dictionary', 0, 1, NOW(), 1, NOW());

-- Insert firmware type dictionary data
delete from `sys_dict_data` where `dict_type_id` = 102;
INSERT INTO `sys_dict_data` (`id`, `dict_type_id`, `dict_label`, `dict_value`, `remark`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES 
(102001, 102, 'Mainland China', '+86', 'Mainland China', 1, 1, NOW(), 1, NOW()),
(102002, 102, 'Hong Kong, China', '+852', 'Hong Kong, China', 2, 1, NOW(), 1, NOW()),
(102003, 102, 'Macau, China', '+853', 'Macau, China', 3, 1, NOW(), 1, NOW()),
(102004, 102, 'Taiwan, China', '+886', 'Taiwan, China', 4, 1, NOW(), 1, NOW()),
(102005, 102, 'United States/Canada', '+1', 'United States/Canada', 5, 1, NOW(), 1, NOW()),
(102006, 102, 'United Kingdom', '+44', 'United Kingdom', 6, 1, NOW(), 1, NOW()),
(102007, 102, 'France', '+33', 'France', 7, 1, NOW(), 1, NOW()),
(102008, 102, 'Italy', '+39', 'Italy', 8, 1, NOW(), 1, NOW()),
(102009, 102, 'Germany', '+49', 'Germany', 9, 1, NOW(), 1, NOW()),
(102010, 102, 'Poland', '+48', 'Poland', 10, 1, NOW(), 1, NOW()),
(102011, 102, 'Switzerland', '+41', 'Switzerland', 11, 1, NOW(), 1, NOW()),
(102012, 102, 'Spain', '+34', 'Spain', 12, 1, NOW(), 1, NOW()),
(102013, 102, 'Denmark', '+45', 'Denmark', 13, 1, NOW(), 1, NOW()),
(102014, 102, 'Malaysia', '+60', 'Malaysia', 14, 1, NOW(), 1, NOW()),
(102015, 102, 'Australia', '+61', 'Australia', 15, 1, NOW(), 1, NOW()),
(102016, 102, 'Indonesia', '+62', 'Indonesia', 16, 1, NOW(), 1, NOW()),
(102017, 102, 'Philippines', '+63', 'Philippines', 17, 1, NOW(), 1, NOW()),
(102018, 102, 'New Zealand', '+64', 'New Zealand', 18, 1, NOW(), 1, NOW()),
(102019, 102, 'Singapore', '+65', 'Singapore', 19, 1, NOW(), 1, NOW()),
(102020, 102, 'Thailand', '+66', 'Thailand', 20, 1, NOW(), 1, NOW()),
(102021, 102, 'Japan', '+81', 'Japan', 21, 1, NOW(), 1, NOW()),
(102022, 102, 'South Korea', '+82', 'South Korea', 22, 1, NOW(), 1, NOW()),
(102023, 102, 'Vietnam', '+84', 'Vietnam', 23, 1, NOW(), 1, NOW()),
(102024, 102, 'India', '+91', 'India', 24, 1, NOW(), 1, NOW()),
(102025, 102, 'Pakistan', '+92', 'Pakistan', 25, 1, NOW(), 1, NOW()),
(102026, 102, 'Nigeria', '+234', 'Nigeria', 26, 1, NOW(), 1, NOW()),
(102027, 102, 'Bangladesh', '+880', 'Bangladesh', 27, 1, NOW(), 1, NOW()),
(102028, 102, 'Saudi Arabia', '+966', 'Saudi Arabia', 28, 1, NOW(), 1, NOW()),
(102029, 102, 'United Arab Emirates', '+971', 'United Arab Emirates', 29, 1, NOW(), 1, NOW()),
(102030, 102, 'Brazil', '+55', 'Brazil', 30, 1, NOW(), 1, NOW()),
(102031, 102, 'Mexico', '+52', 'Mexico', 31, 1, NOW(), 1, NOW()),
(102032, 102, 'Chile', '+56', 'Chile', 32, 1, NOW(), 1, NOW()),
(102033, 102, 'Argentina', '+54', 'Argentina', 33, 1, NOW(), 1, NOW()),
(102034, 102, 'Egypt', '+20', 'Egypt', 34, 1, NOW(), 1, NOW()),
(102035, 102, 'South Africa', '+27', 'South Africa', 35, 1, NOW(), 1, NOW()),
(102036, 102, 'Kenya', '+254', 'Kenya', 36, 1, NOW(), 1, NOW()),
(102037, 102, 'Tanzania', '+255', 'Tanzania', 37, 1, NOW(), 1, NOW()),
(102038, 102, 'Kazakhstan', '+7', 'Kazakhstan', 38, 1, NOW(), 1, NOW());
-- ===== end 202505182234.sql =====

-- ===== begin 202505201744.sql =====
-- Update the fields column of ai_model_provider, changing type dict to string
update ai_model_provider set fields = replace(fields, '"type": "dict"', '"type": "string"') where id not in ('SYSTEM_LLM_fastgpt', 'SYSTEM_TTS_custom');
update ai_model_provider set fields = replace(fields, '"type":"dict"', '"type": "string"') where id not in ('SYSTEM_LLM_fastgpt', 'SYSTEM_TTS_custom');
-- ===== end 202505201744.sql =====

-- ===== begin 202505151451.sql =====
-- Modify the custom TTS API request definition
update `ai_model_provider` set `fields` =
'[{"key":"url","label":"Service address","type":"string"},{"key":"method","label":"Request method","type":"string"},{"key":"params","label":"Request parameters","type":"dict","dict_name":"params"},{"key":"headers","label":"Request headers","type":"dict","dict_name":"headers"},{"key":"format","label":"Audio format","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]'
where `id` = 'SYSTEM_TTS_custom';

-- Modify the custom TTS configuration notes
UPDATE `ai_model_config` SET
`doc_link` = NULL,
`remark` = 'Custom TTS configuration notes:
1. A custom TTS API service; the request parameters are customizable, so many TTS services can be connected
2. Take a locally deployed KokoroTTS as an example
3. If running on CPU only: docker run -p 8880:8880 ghcr.io/remsky/kokoro-fastapi-cpu:latest
4. If running on GPU only: docker run --gpus all -p 8880:8880 ghcr.io/remsky/kokoro-fastapi-gpu:latest
Configuration notes:
1. Configure the request parameters in params, using JSON format
   For example KokoroTTS: { "input": "{prompt_text}", "speed": 1, "voice": "zm_yunxi", "stream": true, "download_format": "mp3", "response_format": "mp3", "return_download_link": true }
2. Configure the request headers in headers
3. Set the returned audio format' WHERE `id` = 'TTS_CustomTTS';
-- ===== end 202505151451.sql =====

-- ===== begin 202505271414.sql =====
-- Local short-term memory configuration can set a separate LLM
update `ai_model_provider` set fields =  '[{"key":"llm","label":"LLM Model","type":"string"}]' where  id = 'SYSTEM_Memory_mem_local_short';
update `ai_model_config` set config_json =  '{\"type\": \"mem_local_short\", \"llm\": \"LLM_ChatGLMLLM\"}' where  id = 'Memory_mem_local_short';

-- Add the Volcano dual-stream TTS provider and model configuration
delete from `ai_model_provider` where id = 'SYSTEM_TTS_HSDSTTS';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_TTS_HSDSTTS', 'TTS', 'huoshan_double_stream', 'Volcano dual-stream speech synthesis', '[{"key":"ws_url","label":"WebSocket address","type":"string"},{"key":"appid","label":"App ID","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"resource_id","label":"Resource ID","type":"string"},{"key":"speaker","label":"Default voice","type":"string"}]', 13, 1, NOW(), 1, NOW());

delete from `ai_model_config` where id = 'TTS_HuoshanDoubleStreamTTS';
INSERT INTO `ai_model_config` VALUES ('TTS_HuoshanDoubleStreamTTS', 'TTS', 'HuoshanDoubleStreamTTS', 'Volcano dual-stream speech synthesis', 0, 1, '{\"type\": \"huoshan_double_stream\", \"ws_url\": \"wss://openspeech.bytedance.com/api/v3/tts/bidirection\", \"appid\": \"your_volcengine_tts_appid\", \"access_token\": \"your_volcengine_tts_access_token\", \"resource_id\": \"volc.service_type.10029\", \"speaker\": \"zh_female_wanwanxiaohe_moon_bigtts\"}', NULL, NULL, 16, NULL, NULL, NULL, NULL);

-- Volcano dual-stream TTS model configuration documentation
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/speech/service/10007',
`remark` = 'Volcano Engine speech synthesis service configuration notes:
1. Visit https://www.volcengine.com/ to register and activate a Volcano Engine account
2. Visit https://console.volcengine.com/speech/service/10007 to activate the speech synthesis large model and buy voices
3. Get the appid and access_token at the bottom of the page
5. The resource ID is fixed to: volc.service_type.10029 (large-model speech synthesis and mixing)
6. Fill them into the configuration file' WHERE `id` = 'TTS_HuoshanDoubleStreamTTS';


-- Add Volcano dual-stream TTS Voice
delete from `ai_tts_voice` where tts_model_id = 'TTS_HuoshanDoubleStreamTTS';
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0001', 'TTS_HuoshanDoubleStreamTTS', 'Shuangkuai Sisi/Skye', 'zh_female_shuangkuaisisi_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/Skye.mp3', NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0002', 'TTS_HuoshanDoubleStreamTTS', 'Warm Ahu/Alvin', 'zh_male_wennuanahu_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/Alvin.mp3', NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0003', 'TTS_HuoshanDoubleStreamTTS', 'Young Zixin/Brayan', 'zh_male_shaonianzixin_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/Brayan.mp3', NULL, 3, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0004', 'TTS_HuoshanDoubleStreamTTS', 'Girl Next Door', 'zh_female_linjianvhai_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E9%82%BB%E5%AE%B6%E5%A5%B3%E5%AD%A9.mp3', NULL, 4, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0005', 'TTS_HuoshanDoubleStreamTTS', 'Learned Uncle', 'zh_male_yuanboxiaoshu_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E6%B8%8A%E5%8D%9A%E5%B0%8F%E5%8F%94.mp3', NULL, 5, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0006', 'TTS_HuoshanDoubleStreamTTS', 'Sunny Young Man', 'zh_male_yangguangqingnian_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E9%98%B3%E5%85%89%E9%9D%92%E5%B9%B4.mp3', NULL, 6, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0007', 'TTS_HuoshanDoubleStreamTTS', 'Beijing Chatterbox/Harmony', 'zh_male_jingqiangkanye_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/Harmony.mp3', NULL, 7, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0008', 'TTS_HuoshanDoubleStreamTTS', 'Wanwan Xiaohe', 'zh_female_wanwanxiaohe_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E6%B9%BE%E6%B9%BE%E5%B0%8F%E4%BD%95.mp3', NULL, 8, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0009', 'TTS_HuoshanDoubleStreamTTS', 'Bay Area Uncle', 'zh_female_wanqudashu_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E6%B9%BE%E5%8C%BA%E5%A4%A7%E5%8F%94.mp3', NULL, 9, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0010', 'TTS_HuoshanDoubleStreamTTS', 'Cute Sichuan Girl', 'zh_female_daimengchuanmei_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E5%91%86%E8%90%8C%E5%B7%9D%E5%A6%B9.mp3', NULL, 10, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0011', 'TTS_HuoshanDoubleStreamTTS', 'Guangzhou Dege', 'zh_male_guozhoudege_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E5%B9%BF%E5%B7%9E%E5%BE%B7%E5%93%A5.mp3', NULL, 11, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0012', 'TTS_HuoshanDoubleStreamTTS', 'Beijing Xiaoye', 'zh_male_beijingxiaoye_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E5%8C%97%E4%BA%AC%E5%B0%8F%E7%88%B7.mp3', NULL, 12, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0013', 'TTS_HuoshanDoubleStreamTTS', 'Haoyu Xiaoge', 'zh_male_haoyuxiaoge_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E6%B5%A9%E5%AE%87%E5%B0%8F%E5%93%A5.mp3', NULL, 13, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0014', 'TTS_HuoshanDoubleStreamTTS', 'Guangxi Yuanzhou', 'zh_male_guangxiyuanzhou_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E5%B9%BF%E8%A5%BF%E8%BF%9C%E8%88%9F.mp3', NULL, 14, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0015', 'TTS_HuoshanDoubleStreamTTS', 'Meituo Jieer', 'zh_female_meituojieer_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E5%A6%B9%E5%9D%A8%E6%B4%81%E5%84%BF.mp3', NULL, 15, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0016', 'TTS_HuoshanDoubleStreamTTS', 'Yuzhou Zixuan', 'zh_male_yuzhouzixuan_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E8%B1%AB%E5%B7%9E%E5%AD%90%E8%BD%A9.mp3', NULL, 16, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0017', 'TTS_HuoshanDoubleStreamTTS', 'Cool Mature Woman', 'zh_female_gaolengyujie_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E9%AB%98%E5%86%B7%E5%BE%A1%E5%A7%90.mp3', NULL, 17, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0018', 'TTS_HuoshanDoubleStreamTTS', 'Tsundere Boss', 'zh_male_aojiaobazong_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E5%82%B2%E5%A8%87%E9%9C%B8%E6%80%BB.mp3', NULL, 18, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0019', 'TTS_HuoshanDoubleStreamTTS', 'Charming Girlfriend', 'zh_female_meilinvyou_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E9%AD%85%E5%8A%9B%E5%A5%B3%E5%8F%8B.mp3', NULL, 19, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0020', 'TTS_HuoshanDoubleStreamTTS', 'Late-Night Podcast', 'zh_male_shenyeboke_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E6%B7%B1%E5%A4%9C%E6%92%AD%E5%AE%A2.mp3', NULL, 20, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0021', 'TTS_HuoshanDoubleStreamTTS', 'Gentle Girlfriend', 'zh_female_sajiaonvyou_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E6%9F%94%E7%BE%8E%E5%A5%B3%E5%8F%8B.mp3', NULL, 21, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0022', 'TTS_HuoshanDoubleStreamTTS', 'Coquettish Junior', 'zh_female_yuanqinvyou_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E6%92%92%E5%A8%87%E5%AD%A6%E5%A6%B9.mp3', NULL, 22, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0023', 'TTS_HuoshanDoubleStreamTTS', 'かずね(Kazune)', 'multi_male_jingqiangkanye_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/Javier.wav', NULL, 23, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0024', 'TTS_HuoshanDoubleStreamTTS', 'はるこ(Haruko)', 'multi_female_shuangkuaisisi_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/Esmeralda.mp3', NULL, 24, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0025', 'TTS_HuoshanDoubleStreamTTS', 'あけみ(Akemi)', 'multi_female_gaolengyujie_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E6%9C%B1%E7%BE%8E.mp3', NULL, 25, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HuoshanDoubleStreamTTS_0026', 'TTS_HuoshanDoubleStreamTTS', 'ひろし(Hiroshi)', 'multi_male_wanqudashu_moon_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/Roberto.wav', NULL, 26, NULL, NULL, NULL, NULL);
-- ===== end 202505271414.sql =====

-- ===== begin 202505292203.sql =====
-- ===============================
-- 1. Insert plugin records into ai_model_provider
-- ===============================
START TRANSACTION;


-- intent_llm and function_call do not set a function list
update `ai_model_provider` set fields =  '[{"key":"llm","label":"LLM Model","type":"string"}]' where  id = 'SYSTEM_Intent_intent_llm';
update `ai_model_provider` set fields =  '[]' where  id = 'SYSTEM_Intent_function_call';
update `ai_model_config` set config_json =  '{\"type\": \"intent_llm\", \"llm\": \"LLM_ChatGLMLLM\"}' where  id = 'Intent_intent_llm';
UPDATE `ai_model_config` SET config_json = '{\"type\": \"function_call\"}' WHERE id = 'Intent_function_call';


delete from ai_model_provider where model_type = 'Plugin';
-- 1. Weather query
INSERT INTO ai_model_provider (id, model_type, provider_code, name, fields,
                               sort, creator, create_date, updater, update_date)
VALUES ('SYSTEM_PLUGIN_WEATHER',
        'Plugin',
        'get_weather',
        'Weather query',
        JSON_ARRAY(
                JSON_OBJECT(
                        'key', 'api_key',
                        'type', 'string',
                        'label', 'Weather plugin API key',
                        'default', (SELECT param_value FROM sys_params WHERE param_code = 'plugins.get_weather.api_key')
                ),
                JSON_OBJECT(
                        'key', 'default_location',
                        'type', 'string',
                        'label', 'Default city to query',
                        'default',
                        (SELECT param_value FROM sys_params WHERE param_code = 'plugins.get_weather.default_location')
                ),
                JSON_OBJECT(
                        'key', 'api_host',
                        'type', 'string',
                        'label', 'Developer API Host',
                        'default',
                        (SELECT param_value FROM sys_params WHERE param_code = 'plugins.get_weather.api_host')
                )
        ),
        10, 0, NOW(), 0, NOW());

-- 6. Local music playback
INSERT INTO ai_model_provider (id, model_type, provider_code, name, fields,
                               sort, creator, create_date, updater, update_date)
VALUES ('SYSTEM_PLUGIN_MUSIC',
        'Plugin',
        'play_music',
        'Server music playback',
        JSON_ARRAY(),
        20, 0, NOW(), 0, NOW());

-- 2. News subscription
INSERT INTO ai_model_provider (id, model_type, provider_code, name, fields,
                               sort, creator, create_date, updater, update_date)
VALUES ('SYSTEM_PLUGIN_NEWS_CHINANEWS',
        'Plugin',
        'get_news_from_chinanews',
        'China News Service news',
        JSON_ARRAY(
                JSON_OBJECT(
                        'key', 'default_rss_url',
                        'type', 'string',
                        'label', 'Default RSS source',
                        'default',
                        (SELECT param_value FROM sys_params WHERE param_code = 'plugins.get_news.default_rss_url')
                ),
                JSON_OBJECT(
                        'key', 'society_rss_url',
                        'type', 'string',
                        'label', 'Society news RSS address',
                        'default',
                        'https://www.chinanews.com.cn/rss/society.xml'
                ),
                JSON_OBJECT(
                        'key', 'world_rss_url',
                        'type', 'string',
                        'label', 'International news RSS address',
                        'default',
                        'https://www.chinanews.com.cn/rss/world.xml'
                ),
                JSON_OBJECT(
                        'key', 'finance_rss_url',
                        'type', 'string',
                        'label', 'Finance news RSS address',
                        'default',
                        'https://www.chinanews.com.cn/rss/finance.xml'
                )
        ),
        30, 0, NOW(), 0, NOW());

-- 3. News subscription
INSERT INTO ai_model_provider (id, model_type, provider_code, name, fields,
                               sort, creator, create_date, updater, update_date)
VALUES ('SYSTEM_PLUGIN_NEWS_NEWSNOW',
        'Plugin',
        'get_news_from_newsnow',
        'newsnow news aggregation',
        JSON_ARRAY(
                JSON_OBJECT(
                        'key', 'url',
                        'type', 'string',
                        'label', 'API address',
                        'default',
                        'https://newsnow.busiyi.world/api/s?id='
                )
        ),
        40, 0, NOW(), 0, NOW());


-- 4. HomeAssistant status query
INSERT INTO ai_model_provider (id, model_type, provider_code, name, fields,
                               sort, creator, create_date, updater, update_date)
VALUES ('SYSTEM_PLUGIN_HA_GET_STATE',
        'Plugin',
        'hass_get_state',
        'HomeAssistant device status query',
        JSON_ARRAY(
                JSON_OBJECT(
                        'key', 'base_url',
                        'type', 'string',
                        'label', 'HA server address',
                        'default',
                        (SELECT param_value FROM sys_params WHERE param_code = 'plugins.home_assistant.base_url')
                ),
                JSON_OBJECT(
                        'key', 'api_key',
                        'type', 'string',
                        'label', 'HA API access token',
                        'default',
                        (SELECT param_value FROM sys_params WHERE param_code = 'plugins.home_assistant.api_key')
                ),
                JSON_OBJECT(
                        'key', 'devices',
                        'type', 'array',
                        'label', 'Device list (name,entity ID;...)',
                        'default',
                        (SELECT param_value FROM sys_params WHERE param_code = 'plugins.home_assistant.devices')
                )
        ),
        50, 0, NOW(), 0, NOW());

-- 5. HomeAssistant status write
INSERT INTO ai_model_provider (id, model_type, provider_code, name, fields,
                               sort, creator, create_date, updater, update_date)
VALUES ('SYSTEM_PLUGIN_HA_SET_STATE',
        'Plugin',
        'hass_set_state',
        'HomeAssistant device status update',
        JSON_ARRAY(),
        60, 0, NOW(), 0, NOW());

-- 5. HomeAssistant music playback
INSERT INTO ai_model_provider (id, model_type, provider_code, name, fields,
                               sort, creator, create_date, updater, update_date)
VALUES ('SYSTEM_PLUGIN_HA_PLAY_MUSIC',
        'Plugin',
        'hass_play_music',
        'HomeAssistant music playback',
        JSON_ARRAY(),
        70, 0, NOW(), 0, NOW());


-- ===============================
-- 2. Delete the old plugins.* parameters from sys_params
-- ===============================
DELETE
FROM sys_params
WHERE param_code LIKE 'plugins.%';


-- ===============================
-- 3. Add the agent plugin id column
-- ===============================
CREATE TABLE IF NOT EXISTS ai_agent_plugin_mapping
(
    id         BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    agent_id   VARCHAR(32) NOT NULL COMMENT 'Agent ID',
    plugin_id  VARCHAR(32) NOT NULL COMMENT 'plugin ID',
    param_info JSON        NOT NULL COMMENT 'Parameter info',
    UNIQUE KEY uk_agent_provider (agent_id, plugin_id)
) COMMENT 'Unique mapping table between agents and plugins';


COMMIT;

-- ===== end 202505292203.sql =====

-- ===== begin 202506010920.sql =====
-- VLLM Model provider
delete from `ai_model_provider` where id = 'SYSTEM_VLLM_openai';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_VLLM_openai', 'VLLM', 'openai', 'OpenAI interface', '[{"key":"base_url","label":"Base URL","type":"string"},{"key":"model_name","label":"Model name","type":"string"},{"key":"api_key","label":"API key","type":"string"}]', 9, 1, NOW(), 1, NOW());

-- VLLM Model configuration
delete from `ai_model_config` where id = 'VLLM_ChatGLMVLLM';
INSERT INTO `ai_model_config` VALUES ('VLLM_ChatGLMVLLM', 'VLLM', 'ChatGLMVLLM', 'Zhipu Vision AI', 1, 1, '{\"type\": \"openai\", \"model_name\": \"glm-4v-flash\", \"base_url\": \"https://open.bigmodel.cn/api/paas/v4/\", \"api_key\": \"your_api_key\"}', NULL, NULL, 1, NULL, NULL, NULL, NULL);

-- Update documentation
UPDATE `ai_model_config` SET 
`doc_link` = 'https://bigmodel.cn/usercenter/proj-mgmt/apikeys',
`remark` = 'Zhipu Vision AI configuration notes:
1. Access https://bigmodel.cn/usercenter/proj-mgmt/apikeys
2. Register and get the API key
3. Fill them into the configuration file' WHERE `id` = 'VLLM_ChatGLMVLLM';


-- Add parameters
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (113, 'server.http_port', '8003', 'number', 1, 'Port of the HTTP service, used to start the vision analysis API');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (114, 'server.vision_explain', 'null', 'string', 1, 'Vision analysis API address, delivered to devices; separate multiple addresses with ;');

-- Add VLLM model configuration to the agent table
ALTER TABLE `ai_agent` 
ADD COLUMN `vllm_model_id` varchar(32) NULL DEFAULT 'VLLM_ChatGLMVLLM' COMMENT 'Vision model ID' AFTER `llm_model_id`;

-- Add VLLM model configuration to the agent template table
ALTER TABLE `ai_agent_template` 
ADD COLUMN `vllm_model_id` varchar(32) NULL DEFAULT 'VLLM_ChatGLMVLLM' COMMENT 'Vision model ID' AFTER `llm_model_id`;
-- ===== end 202506010920.sql =====

-- ===== begin 202506031639.sql =====
-- VLLM Model provider
delete from `ai_model_provider` where id = 'SYSTEM_ASR_DoubaoStreamASR';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_DoubaoStreamASR', 'ASR', 'doubao_stream', 'Volcano Engine speech recognition (Streaming)', '[{"key":"appid","label":"App ID","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"cluster","label":"Cluster","type":"string"},{"key":"boosting_table_name","label":"Hot word file name","type":"string"},{"key":"correct_table_name","label":"Replacement word file name","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]', 3, 1, NOW(), 1, NOW());


-- VLLM Model configuration
delete from `ai_model_config` where id = 'ASR_DoubaoStreamASR';
INSERT INTO `ai_model_config` VALUES ('ASR_DoubaoStreamASR', 'ASR', 'DoubaoStreamASR', 'Doubao speech recognition (Streaming)', 0, 1, '{\"type\": \"doubao_stream\", \"appid\": \"\", \"access_token\": \"\", \"cluster\": \"volcengine_input_common\", \"output_dir\": \"tmp/\"}', NULL, NULL, 3, NULL, NULL, NULL, NULL);


-- Update the Doubao ASR configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/speech/app',
`remark` = 'Doubao ASR configuration notes:
1. Difference between Doubao ASR and Doubao (streaming) ASR: Doubao ASR is billed per call, Doubao (streaming) ASR is billed by time
2. Generally, per-call billing is cheaper, but Doubao (streaming) ASR uses large-model technology and gives better results
3. You need to create an application in the Volcano Engine console and get the appid and access_token
4. Supports Chinese speech recognition
5. Network connection required
6. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://console.volcengine.com/speech/app
2. Create a new application
3. Get the appid and access_token
4. Fill them into the configuration file
To set hot words, see: https://www.volcengine.com/docs/6561/155738
' WHERE `id` = 'ASR_DoubaoASR';

UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/speech/app',
`remark` = 'Doubao ASR configuration notes:
1. Difference between Doubao ASR and Doubao (streaming) ASR: Doubao ASR is billed per call, Doubao (streaming) ASR is billed by time
2. Generally, per-call billing is cheaper, but Doubao (streaming) ASR uses large-model technology and gives better results
3. You need to create an application in the Volcano Engine console and get the appid and access_token
4. Supports Chinese speech recognition
5. Network connection required
6. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://console.volcengine.com/speech/app
2. Create a new application
3. Get the appid and access_token
4. Fill them into the configuration file
To set hot words, see: https://www.volcengine.com/docs/6561/155738
' WHERE `id` = 'ASR_DoubaoStreamASR';
-- ===== end 202506031639.sql =====

-- ===== begin 202506032232.sql =====
-- VLLM Model configuration
delete from `ai_model_config` where id = 'VLLM_QwenVLVLLM';
INSERT INTO `ai_model_config` VALUES ('VLLM_QwenVLVLLM', 'VLLM', 'QwenVLVLLM', 'Qwen vision model', 0, 1, '{\"type\": \"openai\", \"model_name\": \"qwen2.5-vl-3b-instruct\", \"base_url\": \"https://dashscope.aliyuncs.com/compatible-mode/v1\", \"api_key\": \"your_api_key\"}', NULL, NULL, 2, NULL, NULL, NULL, NULL);

-- Update documentation
UPDATE `ai_model_config` SET 
`doc_link` = 'https://bailian.console.aliyun.com/?tab=api#/api/?type=model&url=https%3A%2F%2Fhelp.aliyun.com%2Fdocument_detail%2F2845564.html&renderType=iframe',
`remark` = 'Qwen vision model configuration notes:
1. Access https://bailian.console.aliyun.com/?tab=model#/api-key
2. Register and get the API key
3. Fill them into the configuration file' WHERE `id` = 'VLLM_QwenVLVLLM';

-- Delete the parameters; these two parameters have been moved to the python configuration file
delete from `sys_params` where id  in (113,114);
-- ===== end 202506032232.sql =====

-- ===== begin 202506051538.sql =====
-- Add the LinkeraiTTS provider and model configuration
delete from `ai_model_provider` where id = 'SYSTEM_TTS_LinkeraiTTS';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_TTS_LinkeraiTTS', 'TTS', 'linkerai', 'Linkerai speech synthesis', '[{"key":"api_url","label":"API address","type":"string"},{"key":"audio_format","label":"Audio format","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"voice","label":"Default voice","type":"string"}]', 14, 1, NOW(), 1, NOW());

delete from `ai_model_config` where id = 'TTS_LinkeraiTTS';
INSERT INTO `ai_model_config` VALUES ('TTS_LinkeraiTTS', 'TTS', 'LinkeraiTTS', 'Linkerai speech synthesis', 0, 1, '{\"type\": \"linkerai\", \"api_url\": \"https://tts.linkerai.cn/tts\", \"audio_format\": \"pcm\", \"access_token\": \"U4YdYXVfpwWnk2t5Gp822zWPCuORyeJL\", \"voice\": \"OUeAo1mhq6IBExi\"}', NULL, NULL, 17, NULL, NULL, NULL, NULL);

-- LinkeraiTTS model configuration documentation
UPDATE `ai_model_config` SET 
`doc_link` = 'https://tts.linkerai.cn/docs',
`remark` = 'Linkerai speech synthesis service configuration notes:
1. Visit https://linkerai.cn to register and get an access token
2. The default access_token is for testing only; do not use it for commercial purposes
3. Supports voice cloning; you can upload your own audio and fill it into the voice parameter
4. If the voice parameter is empty, the default voice will be used' WHERE `id` = 'TTS_LinkeraiTTS';


delete from `ai_tts_voice` where tts_model_id = 'TTS_LinkeraiTTS';
INSERT INTO `ai_tts_voice` VALUES ('TTS_LinkeraiTTS_0001', 'TTS_LinkeraiTTS', 'Zhiruo', 'OUeAo1mhq6IBExi', 'English', NULL, NULL, 1, NULL, NULL, NULL, NULL);
-- ===== end 202506051538.sql =====

-- ===== begin 202506080955.sql =====
-- Enable wake word acceleration in the control panel
update `sys_params` set param_value = 'hello;hey there' where param_code = 'wakeup_words';
update `sys_params` set param_value = 'true' where param_code = 'enable_wakeup_words_response_cache';
-- ===== end 202506080955.sql =====

-- ===== begin 202506091720.sql =====
ALTER TABLE `ai_tts_voice`
ADD COLUMN `reference_audio` VARCHAR(500) DEFAULT NULL COMMENT 'Reference audio path' AFTER `remark`,
ADD COLUMN `reference_text` VARCHAR(500) DEFAULT NULL COMMENT 'Reference text' AFTER `reference_audio`;
-- ===== end 202506091720.sql =====

-- ===== begin 202506161101.sql =====
ALTER TABLE ai_agent_plugin_mapping CONVERT TO CHARACTER SET utf8mb4;
-- ===== end 202506161101.sql =====

-- ===== begin 202506191643.sql =====
-- LLM intent recognition configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = NULL,
`remark` = 'LLM intent recognition configuration notes:
1. Uses a separate LLM for intent recognition
2. Uses the model of selected_module.LLM by default
3. A separate LLM can be configured (for example the free ChatGLMLLM)
4. Highly general, but increases processing time
Configuration notes:
1. Specify the LLM model to use in the llm field
2. If not specified, the model of selected_module.LLM is used' WHERE `id` = 'Intent_intent_llm';

-- Function-call intent recognition configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = NULL,
`remark` = 'Function-call intent recognition configuration notes:
1. Uses the function_call feature of the LLM for intent recognition
2. The selected LLM must support function_call
3. Tools are called on demand, so processing is fast' WHERE `id` = 'Intent_function_call';
-- ===== end 202506191643.sql =====

-- ===== begin 202506251620.sql =====
-- Update the existing get_news_from_newsnow plugin configuration
UPDATE ai_model_provider 
SET fields = JSON_ARRAY(
    JSON_OBJECT(
        'key', 'url',
        'type', 'string',
        'label', 'API address',
        'default', 'https://newsnow.busiyi.world/api/s?id='
    ),
    JSON_OBJECT(
        'key', 'news_sources',
        'type', 'string',
        'label', 'News source configuration',
        'default', 'your_news_sources' -- TODO(vi): customize for Vietnamese usage (see docs/remove-chinese-plan.md)
    )
)
WHERE provider_code = 'get_news_from_newsnow' 
AND model_type = 'Plugin'; 
-- ===== end 202506251620.sql =====

-- ===== begin 202506261637.sql =====
delete from `sys_params` where id = 113;
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (113, 'server.mcp_endpoint', 'null', 'string', 1, 'MCP endpoint address');
-- ===== end 202506261637.sql =====

-- ===== begin 202507101203.sql =====
-- OpenAI ASR Model provider
delete from `ai_model_provider` where id = 'SYSTEM_ASR_OpenaiASR';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_OpenaiASR', 'ASR', 'openai', 'OpenAI speech recognition', '[{"key": "base_url", "type": "string", "label": "Base URL"}, {"key": "model_name", "type": "string", "label": "Model name"}, {"key": "api_key", "type": "string", "label": "API key"}, {"key": "output_dir", "type": "string", "label": "Output directory"}]', 9, 1, NOW(), 1, NOW());


-- OpenAI ASR Model configuration
delete from `ai_model_config` where id = 'ASR_OpenaiASR';
INSERT INTO `ai_model_config` VALUES ('ASR_OpenaiASR', 'ASR', 'OpenaiASR', 'OpenAI speech recognition', 0, 1, '{\"type\": \"openai\", \"api_key\": \"\", \"base_url\": \"https://api.openai.com/v1/audio/transcriptions\", \"model_name\": \"gpt-4o-mini-transcribe\", \"output_dir\": \"tmp/\"}', NULL, NULL, 9, NULL, NULL, NULL, NULL);

-- groq ASR Model configuration
delete from `ai_model_config` where id = 'ASR_GroqASR';
INSERT INTO `ai_model_config` VALUES ('ASR_GroqASR', 'ASR', 'GroqASR', 'Groq speech recognition', 0, 1, '{\"type\": \"openai\", \"api_key\": \"\", \"base_url\": \"https://api.groq.com/openai/v1/audio/transcriptions\", \"model_name\": \"whisper-large-v3-turbo\", \"output_dir\": \"tmp/\"}', NULL, NULL, 10, NULL, NULL, NULL, NULL);


-- Update the OpenAI ASR configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://platform.openai.com/docs/api-reference/audio/createTranscription',
`remark` = 'OpenAI ASR configuration notes:
1. You need to create an organization on the OpenAI platform and get an api_key
2. Supports speech recognition in Chinese, English, Japanese, Korean and more; see the documentation at https://platform.openai.com/docs/guides/speech-to-text
3. Network connection required
4. Output files are saved in the tmp/ directory
Application steps:
**OpenAI ASR application steps:**
1.Log in to OpenAI Platform. https://auth.openai.com/log-in
2.Create an api-key  https://platform.openai.com/settings/organization/api-keys
3.You can choose gpt-4o-transcribe or GPT-4o mini Transcribe as the model
' WHERE `id` = 'ASR_OpenaiASR';

-- Update the Groq ASR configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.groq.com/docs/speech-to-text',
`remark` = 'Groq ASR configuration notes:
1.Log in to groq Console. https://console.groq.com/home
2.Create an api-key  https://console.groq.com/keys
3.You can choose whisper-large-v3-turbo or whisper-large-v3 as the model (distil-whisper-large-v3-en only supports English transcription)
' WHERE `id` = 'ASR_GroqASR';
-- ===== end 202507101203.sql =====

-- ===== begin 202507071130.sql =====
-- Add the Alibaba Cloud streaming ASR provider
delete from `ai_model_provider` where id = 'SYSTEM_ASR_AliyunStreamASR';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_AliyunStreamASR', 'ASR', 'aliyun_stream', 'Alibaba Cloud speech recognition (Streaming)', '[{"key":"appkey","label":"App AppKey","type":"string"},{"key":"token","label":"Temporary Token","type":"string"},{"key":"access_key_id","label":"AccessKey ID","type":"string"},{"key":"access_key_secret","label":"AccessKey Secret","type":"string"},{"key":"host","label":"Service address","type":"string"},{"key":"max_sentence_silence","label":"Sentence-break detection time","type":"number"},{"key":"output_dir","label":"Output directory","type":"string"}]', 6, 1, NOW(), 1, NOW());

-- Add the Alibaba Cloud streaming ASR model configuration
delete from `ai_model_config` where id = 'ASR_AliyunStreamASR';
INSERT INTO `ai_model_config` VALUES ('ASR_AliyunStreamASR', 'ASR', 'AliyunStreamASR', 'Alibaba Cloud speech recognition (Streaming)', 0, 1, '{\"type\": \"aliyun_stream\", \"appkey\": \"\", \"token\": \"\", \"access_key_id\": \"\", \"access_key_secret\": \"\", \"host\": \"nls-gateway-cn-shanghai.aliyuncs.com\", \"max_sentence_silence\": 800, \"output_dir\": \"tmp/\"}', NULL, NULL, 8, NULL, NULL, NULL, NULL);

-- Update the Alibaba Cloud streaming ASR configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://nls-portal.console.aliyun.com/',
`remark` = 'Alibaba Cloud streaming ASR configuration notes:
1. Difference between Alibaba Cloud ASR and Alibaba Cloud (streaming) ASR: Alibaba Cloud ASR recognizes in one shot, Alibaba Cloud (streaming) ASR recognizes in real-time streaming
2. Streaming ASR has lower latency and better real-time performance, suitable for voice interaction scenarios
3. You need to create an application in the Alibaba Cloud Intelligent Speech Interaction console and get the authentication information
4. Supports Chinese real-time speech recognition, with punctuation prediction and inverse text normalization
5. Network connection required; output files are saved in the tmp/ directory
Application steps:
1. Visit https://nls-portal.console.aliyun.com/ to activate the Intelligent Speech Interaction service
2. Visit https://nls-portal.console.aliyun.com/applist to create a project and get the appkey
3. Visit https://nls-portal.console.aliyun.com/overview to get a temporary token (or configure access_key_id and access_key_secret to get one automatically)
4. For dynamic token management, it is recommended to configure access_key_id and access_key_secret
5. The max_sentence_silence parameter controls the sentence-break detection time (in milliseconds), default 800ms
For more parameter configuration, see: https://help.aliyun.com/zh/isi/developer-reference/real-time-speech-recognition
' WHERE `id` = 'ASR_AliyunStreamASR';
-- ===== end 202507071130.sql =====

-- ===== begin 202507071530.sql =====
-- Add the Alibaba Cloud streaming TTS provider
delete from `ai_model_provider` where id = 'SYSTEM_TTS_AliyunStreamTTS';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_TTS_AliyunStreamTTS', 'TTS', 'aliyun_stream', 'Alibaba Cloud speech synthesis (Streaming)', '[{"key":"appkey","label":"App AppKey","type":"string"},{"key":"token","label":"Temporary Token","type":"string"},{"key":"access_key_id","label":"AccessKey ID","type":"string"},{"key":"access_key_secret","label":"AccessKey Secret","type":"string"},{"key":"host","label":"Service address","type":"string"},{"key":"voice","label":"Default voice","type":"string"},{"key":"format","label":"Audio format","type":"string"},{"key":"sample_rate","label":"Sample rate","type":"number"},{"key":"volume","label":"Volume","type":"number"},{"key":"speech_rate","label":"Speech rate","type":"number"},{"key":"pitch_rate","label":"Pitch","type":"number"},{"key":"output_dir","label":"Output directory","type":"string"}]', 15, 1, NOW(), 1, NOW());

-- Add the Alibaba Cloud streaming TTS model configuration
delete from `ai_model_config` where id = 'TTS_AliyunStreamTTS';
INSERT INTO `ai_model_config` VALUES ('TTS_AliyunStreamTTS', 'TTS', 'AliyunStreamTTS', 'Alibaba Cloud speech synthesis (Streaming)', 0, 1, '{\"type\": \"aliyun_stream\", \"appkey\": \"\", \"token\": \"\", \"access_key_id\": \"\", \"access_key_secret\": \"\", \"host\": \"nls-gateway-cn-beijing.aliyuncs.com\", \"voice\": \"longxiaochun\", \"format\": \"pcm\", \"sample_rate\": 16000, \"volume\": 50, \"speech_rate\": 0, \"pitch_rate\": 0, \"output_dir\": \"tmp/\"}', NULL, NULL, 18, NULL, NULL, NULL, NULL);

-- Update the Alibaba Cloud streaming TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://nls-portal.console.aliyun.com/',
`remark` = 'Alibaba Cloud streaming TTS configuration notes:
1. Difference between Alibaba Cloud TTS and Alibaba Cloud (streaming) TTS: Alibaba Cloud TTS synthesizes in one shot, Alibaba Cloud (streaming) TTS synthesizes in real-time streaming
2. Streaming TTS has lower latency and better real-time performance, suitable for voice interaction scenarios
3. You need to create an application in the Alibaba Cloud Intelligent Speech Interaction console and get the authentication information
4. Supports CosyVoice large-model voices with more natural sound quality
5. Supports real-time adjustment of volume, speech rate, pitch and other parameters
Application steps:
1. Visit https://nls-portal.console.aliyun.com/ to activate the Intelligent Speech Interaction service
2. Visit https://nls-portal.console.aliyun.com/applist to create a project and get the appkey
3. Visit https://nls-portal.console.aliyun.com/overview to get a temporary token (or configure access_key_id and access_key_secret to get one automatically)
4. For dynamic token management, it is recommended to configure access_key_id and access_key_secret
5. You can choose servers in different regions such as Beijing and Shanghai to optimize latency
6. The voice parameter supports CosyVoice large-model voices, such as longxiaochun, longyueyue, etc.
For more parameter configuration, see: https://help.aliyun.com/zh/isi/developer-reference/real-time-speech-synthesis
' WHERE `id` = 'TTS_AliyunStreamTTS';

-- Add Alibaba Cloud streaming TTS voices
delete from `ai_tts_voice` where tts_model_id = 'TTS_AliyunStreamTTS';
-- Gentle female voice series
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0001', 'TTS_AliyunStreamTTS', 'Longxiaochun-Gentle Big Sister', 'longxiaochun', 'English', NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0002', 'TTS_AliyunStreamTTS', 'Longxiaoxia-Gentle Female Voice', 'longxiaoxia', 'English', NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0003', 'TTS_AliyunStreamTTS', 'Longmei-Gentle Female Voice', 'longmei', 'English', NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0004', 'TTS_AliyunStreamTTS', 'Longgui-Gentle Female Voice', 'longgui', 'English', NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL);
-- Mature female voice series
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0005', 'TTS_AliyunStreamTTS', 'Longyu-Mature female voice', 'longyu', 'English', NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0006', 'TTS_AliyunStreamTTS', 'Longjiao-Mature female voice', 'longjiao', 'English', NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL);
-- Male voice series
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0007', 'TTS_AliyunStreamTTS', 'Longchen-Dubbed-film Male Voice', 'longchen', 'English', NULL, NULL, NULL, NULL, 7, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0008', 'TTS_AliyunStreamTTS', 'Longxiu-Young Male Voice', 'longxiu', 'English', NULL, NULL, NULL, NULL, 8, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0009', 'TTS_AliyunStreamTTS', 'Longcheng-Sunny Male Voice', 'longcheng', 'English', NULL, NULL, NULL, NULL, 9, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0010', 'TTS_AliyunStreamTTS', 'Longzhe-Mature male voice', 'longzhe', 'English', NULL, NULL, NULL, NULL, 10, NULL, NULL, NULL, NULL);
-- Professional broadcast series
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0011', 'TTS_AliyunStreamTTS', 'Bella2.0-News female voice', 'loongbella', 'English', NULL, NULL, NULL, NULL, 11, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0012', 'TTS_AliyunStreamTTS', 'Stella2.0-Dashing Female Voice', 'loongstella', 'English', NULL, NULL, NULL, NULL, 12, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0013', 'TTS_AliyunStreamTTS', 'Longshu-News male voice', 'longshu', 'English', NULL, NULL, NULL, NULL, 13, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0014', 'TTS_AliyunStreamTTS', 'Longjing-Serious female voice', 'longjing', 'English', NULL, NULL, NULL, NULL, 14, NULL, NULL, NULL, NULL);
-- Special voice series
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0015', 'TTS_AliyunStreamTTS', 'Longqi-Lively Child Voice', 'longqi', 'English', NULL, NULL, NULL, NULL, 15, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0016', 'TTS_AliyunStreamTTS', 'Longhua-Lively Girl', 'longhua', 'English', NULL, NULL, NULL, NULL, 16, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0017', 'TTS_AliyunStreamTTS', 'Longwu-Silly Male Voice', 'longwu', 'English', NULL, NULL, NULL, NULL, 17, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0018', 'TTS_AliyunStreamTTS', 'Longdachui-Humorous male voice', 'longdachui', 'English', NULL, NULL, NULL, NULL, 18, NULL, NULL, NULL, NULL);
-- Cantonese series
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0019', 'TTS_AliyunStreamTTS', 'Longjiayi-Cantonese Female Voice', 'longjiayi', 'English', NULL, NULL, NULL, NULL, 19, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliyunStreamTTS_0020', 'TTS_AliyunStreamTTS', 'Longtao-Cantonese Female Voice', 'longtao', 'English', NULL, NULL, NULL, NULL, 20, NULL, NULL, NULL, NULL);
-- ===== end 202507071530.sql =====

-- ===== begin 202507031602.sql =====
-- Add the voiceprint API address parameter configuration
delete from `sys_params` where id = 114;
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark)
VALUES (114, 'server.voice_print', 'null', 'string', 1, 'Voiceprint API address');
-- ===== end 202507031602.sql =====

-- ===== begin 202507041018.sql =====
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Agent voiceprint table';
-- ===== end 202507041018.sql =====

-- ===== begin 202507081646.sql =====
-- Add a new column to the agent voiceprint table
ALTER TABLE ai_agent_voice_print
    ADD COLUMN audio_id VARCHAR(32) NOT NULL COMMENT 'Audio ID';
-- ===== end 202507081646.sql =====

-- ===== begin 202508081701.sql =====
-- Add the Index-TTS-vLLM streaming TTS provider
delete from `ai_model_provider` where id = 'SYSTEM_TTS_IndexStreamTTS';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_TTS_IndexStreamTTS', 'TTS', 'index_stream', 'Index-TTS-vLLM Streaming speech synthesis', '[{"key":"api_url","label":"API Service address","type":"string"},{"key":"voice","label":"Default voice","type":"string"},{"key":"audio_format","label":"Audio format","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]', 16, 1, NOW(), 1, NOW());

-- Add the Index-TTS-vLLM streaming TTS model configuration
delete from `ai_model_config` where id = 'TTS_IndexStreamTTS';
INSERT INTO `ai_model_config` VALUES ('TTS_IndexStreamTTS', 'TTS', 'IndexStreamTTS', 'Index-TTS-vLLM Streaming speech synthesis', 0, 1, '{\"type\": \"index_stream\", \"api_url\": \"http://127.0.0.1:11996/tts\", \"voice\": \"jay_klee\", \"audio_format\": \"pcm\", \"output_dir\": \"tmp/\"}', NULL, NULL, 19, NULL, NULL, NULL, NULL);

-- Update the Index-TTS-vLLM streaming TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/Ksuriuri/index-tts-vllm',
`remark` = 'Index-TTS-vLLM streaming TTS configuration notes:
1. Index-TTS-vLLM is a vLLM inference service based on the Index-TTS project, providing streaming speech synthesis
2. Supports multiple voices with natural sound quality, suitable for all kinds of voice interaction scenarios
3. You need to deploy the Index-TTS-vLLM service first, then configure the API address
4. Supports real-time streaming synthesis with low latency
5. Supports custom voices; new voices can be registered in the project\'s assets folder
Deployment steps:
1. Clone the project: git clone https://github.com/Ksuriuri/index-tts-vllm.git
2. Install dependencies: pip install -r requirements.txt
3. Start the service: python app.py
4. The service runs at http://127.0.0.1:11996 by default
5. For other voices, register them in the project\'s assets folder
6. Supports multiple audio formats: pcm, wav, mp3, etc.
For more configuration, see: https://github.com/Ksuriuri/index-tts-vllm/blob/master/README.md
' WHERE `id` = 'TTS_IndexStreamTTS';

-- Add Index-TTS-vLLM streaming TTS voices
delete from `ai_tts_voice` where tts_model_id = 'TTS_IndexStreamTTS';
-- Default voice
INSERT INTO `ai_tts_voice` VALUES ('TTS_IndexStreamTTS_0001', 'TTS_IndexStreamTTS', 'Jay Klee', 'jay_klee', 'English', NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL);
-- ===== end 202508081701.sql =====

-- ===== begin 202508111734.sql =====
-- Update the HuoshanDoubleStreamTTS provider to add speech rate, pitch and other settings
UPDATE `ai_model_provider`
SET fields = '[{"key": "ws_url", "type": "string", "label": "WebSocket address"}, {"key": "appid", "type": "string", "label": "App ID"}, {"key": "access_token", "type": "string", "label": "Access token"}, {"key": "resource_id", "type": "string", "label": "Resource ID"}, {"key": "speaker", "type": "string", "label": "Default voice"}, {"key": "speech_rate", "type": "number", "label": "Speech rate (-50~100)"}, {"key": "loudness_rate", "type": "number", "label": "Volume (-50~100)"}, {"key": "pitch", "type": "number", "label": "Pitch (-12~12)"}]'
WHERE id = 'SYSTEM_TTS_HSDSTTS';

UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/speech/service/10007',
`remark` = 'Volcano Engine speech synthesis service configuration notes:
1. Visit https://www.volcengine.com/ to register and activate a Volcano Engine account
2. Visit https://console.volcengine.com/speech/service/10007 to activate the speech synthesis large model and buy voices
3. Get the appid and access_token at the bottom of the page
5. The resource ID is fixed to: volc.service_type.10029 (large-model speech synthesis and mixing)
6. Speech rate: -50~100, optional, the normal default is 0, can be set to -50~100
7. Volume: -50~100, optional, the normal default is 0, can be set to -50~100
8. Pitch: -12~12, optional, the normal default is 0, can be set to -12~12
9. Fill them into the configuration file' WHERE `id` = 'TTS_HuoshanDoubleStreamTTS';
-- ===== end 202508111734.sql =====

-- ===== begin 202508131557.sql =====
-- Add the paddle_speech streaming TTS provider
DELETE FROM `ai_model_provider` WHERE id = 'SYSTEM_TTS_PaddleSpeechTTS';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) 
VALUES ('SYSTEM_TTS_PaddleSpeechTTS', 'TTS', 'paddle_speech', 'PaddleSpeechTTS', 
'[{"key":"protocol","label":"Protocol type","type":"string","options":["websocket","http"]},{"key":"url","label":"Service address","type":"string"},{"key":"spk_id","label":"Voice","type":"int"},{"key":"sample_rate","label":"Sample rate","type":"float"},{"key":"speed","label":"Speech rate","type":"float"},{"key":"volume","label":"Volume","type":"float"},{"key":"save_path","label":"Save path","type":"string"}]', 
17, 1, NOW(), 1, NOW());

-- Add the paddle_speech streaming TTS model configuration
DELETE FROM `ai_model_config` WHERE id = 'TTS_PaddleSpeechTTS';
INSERT INTO `ai_model_config` VALUES ('TTS_PaddleSpeechTTS', 'TTS', 'PaddleSpeechTTS', 'PaddleSpeechTTS', 0, 1, 
'{"type": "paddle_speech", "protocol": "websocket", "url": "ws://127.0.0.1:8092/paddlespeech/tts/streaming", "spk_id": "0", "sample_rate": 24000, "speed": 1.0, "volume": 1.0, "save_path": "./streaming_tts.wav"}', 
NULL, NULL, 20, NULL, NULL, NULL, NULL);

-- Update the PaddleSpeechTTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/PaddlePaddle/PaddleSpeech',
`remark` = 'PaddleSpeechTTS configuration notes:
1. PaddleSpeech is an open-source speech synthesis toolkit from Baidu PaddlePaddle that supports local offline deployment and model training. PaddlePaddle framework address: https://www.paddlepaddle.org.cn/
2. Supports WebSocket and HTTP protocols, using WebSocket for streaming (see the deployment documentation: https://github.com/xinnan-tech/xiaozhi-esp32-server/blob/main/docs/paddlespeech-deploy.md).
3. The paddlespeech service must be deployed locally before use; it runs at ws://127.0.0.1:8092/paddlespeech/tts/streaming by default
4. Supports custom speakers, speech rate, volume and sample rate.
' WHERE `id` = 'TTS_PaddleSpeechTTS';

-- Delete the old voices and add the default voice
DELETE FROM `ai_tts_voice` WHERE tts_model_id = 'TTS_PaddleSpeechTTS';
INSERT INTO `ai_tts_voice` VALUES ('TTS_PaddleSpeechTTS_0000', 'TTS_PaddleSpeechTTS', 'Default', '0', 'English', NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL);
-- ===== end 202508131557.sql =====

-- ===== begin 202508271113.sql =====
-- VOSK ASR model provider
delete from `ai_model_provider` where id = 'SYSTEM_ASR_VoskASR';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_VoskASR', 'ASR', 'vosk', 'VOSK Offline speech recognition', '[{"key": "model_path", "type": "string", "label": "Model path"}, {"key": "output_dir", "type": "string", "label": "Output directory"}]', 11, 1, NOW(), 1, NOW());

-- VOSK ASR model configuration
delete from `ai_model_config` where id = 'ASR_VoskASR';
INSERT INTO `ai_model_config` VALUES ('ASR_VoskASR', 'ASR', 'VoskASR', 'VOSK Offline speech recognition', 0, 1, '{\"type\": \"vosk\", \"model_path\": \"\", \"output_dir\": \"tmp/\"}', NULL, NULL, 11, NULL, NULL, NULL, NULL);

-- Update the VOSK ASR configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://alphacephei.com/vosk/',
`remark` = 'VOSK ASR configuration notes:
1. VOSK is an offline speech recognition library that supports multiple languages
2. You need to download the model files first: https://alphacephei.com/vosk/models
3. For Chinese, vosk-model-small-cn-0.22 or vosk-model-cn-0.22 is recommended
4. Runs fully offline, no network connection required
5. Output files are saved in the tmp/ directory
Usage steps:
1. Visit https://alphacephei.com/vosk/models to download the Chinese model
2. Extract the model files into the models/vosk/ folder in the project directory
3. Specify the correct model path in the configuration
4. Note: the VOSK Chinese model output has no punctuation, and words are separated by spaces
' WHERE `id` = 'ASR_VoskASR';
-- ===== end 202508271113.sql =====

-- ===== begin 202509051745.sql =====
-- Add the MinimaxHTTPStream streaming TTS provider
delete from `ai_model_provider` where id = 'SYSTEM_TTS_MinimaxStreamTTS';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_TTS_MinimaxStreamTTS', 'TTS', 'minimax_httpstream', 'Minimax Streaming speech synthesis', '[{"key":"group_id","label":"Group ID","type":"string"},{"key":"api_key","label":"API key","type":"string"},{"key":"model","label":"Model","type":"string"},{"key":"voice_id","label":"Voice ID","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"voice_setting","label":"Voice settings","type":"dict","dict_name":"voice_setting"},{"key":"pronunciation_dict","label":"Pronunciation dictionary","type":"dict","dict_name":"pronunciation_dict"},{"key":"audio_setting","label":"Audio settings","type":"dict","dict_name":"audio_setting"},{"key":"timber_weights","label":"Voice weight","type":"string"}]', 18, 1, NOW(), 1, NOW());

-- Add the Minimax streaming TTS model configuration
delete from `ai_model_config` where id = 'TTS_MinimaxStreamTTS';
INSERT INTO `ai_model_config` VALUES ('TTS_MinimaxStreamTTS', 'TTS', 'MinimaxStreamTTS', 'Minimax Streaming speech synthesis', 0, 1, '{"type": "minimax_httpstream", "group_id": "", "api_key": "", "model": "speech-01-turbo", "voice_id": "female-shaonv", "output_dir": "tmp/", "voice_setting": {"speed": 1, "vol": 1, "pitch": 0, "emotion": "happy"}, "pronunciation_dict": {"tone": ["process/(pro3)(cess3)", "danger/dangerous"]}, "audio_setting": {"sample_rate": 24000, "bitrate": 128000, "format": "pcm", "channel": 1}}', NULL, NULL, 21, NULL, NULL, NULL, NULL);

-- Update the Minimax streaming TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://platform.minimaxi.com/',
`remark` = 'Minimax streaming TTS configuration notes:
1. You need to apply for a Minimax API Key first
2. Group ID is required
3. Supports multiple voice settings and audio parameter adjustment
4. Supports real-time streaming synthesis with low latency
5. Supports custom pronunciation dictionaries and voice weights
6. Hidden parameter configuration: voice settings (voice_setting), pronunciation dictionary (pronunciation_dict), voice weights (timber_weights)
   - Speech rate (speed): range [0.5,2], default 1.0; the larger the value, the faster the speech
   - Volume (vol): range (0,10], default 1.0; the larger the value, the louder
   - Pitch (pitch): range [-12,12], default 0; the value must be an integer
   - Emotion (emotion): controls the emotion of the synthesized speech; supports 7 values: ["happy", "sad", "angry", "fearful", "disgusted", "surprised", "calm"]; this parameter only takes effect for speech-2.5-hd-preview, speech-2.5-turbo-preview, speech-02-hd, speech-02-turbo, speech-01-turbo, speech-01-hd
   - Either timbre_weights or voice_id is required (choose one)
   - voice_id (the requested voice id; must be filled in together with the weight parameter)
   - weight (weight; supports mixing up to 4 voices. Range [1,100])
' WHERE `id` = 'TTS_MinimaxStreamTTS';

-- Add Minimax Streaming TTS Voice
delete from `ai_tts_voice` where tts_model_id = 'TTS_MinimaxStreamTTS';

-- Default voice
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0001', 'TTS_MinimaxStreamTTS', 'Girl voice', 'female-shaonv', 'English', NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0002', 'TTS_MinimaxStreamTTS', 'Mature female voice', 'female-chengshu', 'English', NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0003', 'TTS_MinimaxStreamTTS', 'Domineering Young Master', 'badao_shaoye', 'English', NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0004', 'TTS_MinimaxStreamTTS', 'Yandere Little Brother', 'bingjiao_didi', 'English', NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0005', 'TTS_MinimaxStreamTTS', 'Innocent Junior', 'chunzhen_xuedi', 'English', NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0006', 'TTS_MinimaxStreamTTS', 'Aloof Senior', 'lengdan_xiongzhang', 'English', NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0007', 'TTS_MinimaxStreamTTS', 'Sweet Xiaoling', 'tianxin_xiaoling', 'English', NULL, NULL, NULL, NULL, 7, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0008', 'TTS_MinimaxStreamTTS', 'Playful Cutie', 'qiaopi_mengmei', 'English', NULL, NULL, NULL, NULL, 8, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0009', 'TTS_MinimaxStreamTTS', 'Charming Mature Woman', 'wumei_yujie', 'English', NULL, NULL, NULL, NULL, 9, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0010', 'TTS_MinimaxStreamTTS', 'Sweet-talking Junior', 'diadia_xuemei', 'English', NULL, NULL, NULL, NULL, 7, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0011', 'TTS_MinimaxStreamTTS', 'Elegant Senior', 'danya_xuejie', 'English', NULL, NULL, NULL, NULL, 8, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0012', 'TTS_MinimaxStreamTTS', 'Santa Claus', 'Santa_Claus', 'English', NULL, NULL, NULL, NULL, 9, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0013', 'TTS_MinimaxStreamTTS', 'Grinch', 'Grinch', 'English', NULL, NULL, NULL, NULL, 10, NULL, NULL, NULL, NULL);
-- ===== end 202509051745.sql =====

-- ===== begin 202509081140.sql =====
-- Add the voiceprint recognition similarity threshold parameter configuration
delete from `sys_params` where id = 115;
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark)
VALUES (115, 'server.voiceprint_similarity_threshold', '0.4', 'string', 1, 'Voiceprint recognition similarity threshold, range 0.0-1.0, default 0.4; the higher the value, the stricter');
-- ===== end 202509081140.sql =====

-- ===== begin 202509091042.sql =====
-- Delete the non-streaming MiniMax TTS configuration, keeping the streaming version

-- Delete the old non-streaming MiniMax TTS model configuration
DELETE FROM `ai_model_config` WHERE `id` = 'TTS_MinimaxTTS';

-- Delete the old non-streaming MiniMax TTS provider configuration
DELETE FROM `ai_model_provider` WHERE `id` = 'SYSTEM_TTS_minimax';

-- Delete the old non-streaming MiniMax TTS voice configuration
DELETE FROM `ai_tts_voice` WHERE `tts_model_id` = 'TTS_MinimaxTTS';
-- ===== end 202509091042.sql =====

-- ===== begin 202509091633.sql =====
-- Add the Tongyi Qianwen Qwen3-ASR-Flash speech recognition service configuration
delete from `ai_model_provider` where id = 'SYSTEM_ASR_Qwen3Flash';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_Qwen3Flash', 'ASR', 'qwen3_asr_flash', 'Qwen3-ASR-Flash speech recognition', '[{"key":"api_key","label":"API key","type":"password"},{"key":"base_url","label":"Service address","type":"string"},{"key":"model_name","label":"Model name","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]', 17, 1, NOW(), 1, NOW());

delete from `ai_model_config` where id = 'ASR_Qwen3Flash';
INSERT INTO `ai_model_config` VALUES ('ASR_Qwen3Flash', 'ASR', 'Qwen3-ASR-Flash', 'Tongyi Qianwen speech recognition service', 0, 1, '{"type": "qwen3_asr_flash", "api_key": "", "base_url": "https://dashscope.aliyuncs.com/compatible-mode/v1", "model_name": "qwen3-asr-flash", "output_dir": "tmp/", "enable_lid": true, "enable_itn": true}', 'https://help.aliyun.com/zh/bailian/', 'Supports multilingual recognition, singing recognition and noise rejection', 20, NULL, NULL, NULL, NULL);

-- Update the Qwen3-ASR-Flash model configuration documentation
UPDATE `ai_model_config` SET 
`doc_link` = 'https://bailian.console.aliyun.com/?apiKey=1&tab=doc#/doc/?type=model&url=2979031',
`remark` = 'Tongyi Qianwen Qwen3-ASR-Flash configuration notes:
1. Log in to the Alibaba Cloud Bailian platform at https://bailian.console.aliyun.com/
2. Create an API-KEY  https://bailian.console.aliyun.com/#/api-key
3.Qwen3-ASR-Flash is based on the Tongyi Qianwen multimodal foundation and supports multilingual recognition, singing recognition, noise rejection and more
' WHERE `id` = 'ASR_Qwen3Flash';
-- ===== end 202509091633.sql =====

-- ===== begin 202509080922.sql =====
delete from `sys_params` where param_code = 'server.mqtt_gateway';
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (116, 'server.mqtt_gateway', 'null', 'string', 1, 'mqtt gateway configuration');

delete from `sys_params` where param_code = 'server.mqtt_signature_key';
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (117, 'server.mqtt_signature_key', 'null', 'string', 1, 'mqtt key configuration');

delete from `sys_params` where param_code = 'server.udp_gateway';
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (118, 'server.udp_gateway', 'null', 'string', 1, 'udp gateway configuration');
-- ===== end 202509080922.sql =====

-- ===== begin 202509161610.sql =====
delete from `sys_params` where param_code = 'server.mqtt_manager_api';
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark)
VALUES (119, 'server.mqtt_manager_api', 'null', 'string', 1, 'Address of the MQTT gateway management API');
-- ===== end 202509161610.sql =====

-- ===== begin 202509161701.sql =====
-- Add the Alibaba Bailian streaming TTS provider
delete from `ai_model_provider` where id = 'SYSTEM_TTS_AliBLStreamTTS';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_TTS_AliBLStreamTTS', 'TTS', 'alibl_stream', 'Alibaba Bailian streaming speech synthesis', '[{"key":"api_key","label":"API key","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"model","label":"Model","type":"string"},{"key":"voice","label":"Voice","type":"string"},{"key":"format","label":"Audio format","type":"string"},{"key":"sample_rate","label":"Sample rate","type":"number"},{"key": "volume", "type": "number", "label": "Volume"},{"key": "rate", "type": "number", "label": "Speech rate"},{"key": "pitch", "type": "number", "label": "Pitch"}]', 19, 1, NOW(), 1, NOW());

-- Add the Alibaba Bailian streaming TTS model configuration
delete from `ai_model_config` where id = 'TTS_AliBLStreamTTS';
INSERT INTO `ai_model_config` VALUES ('TTS_AliBLStreamTTS', 'TTS', 'AliBLStreamTTS', 'Alibaba Bailian streaming speech synthesis', 0, 1, '{\"type\": \"alibl_stream\", \"appkey\": \"\", \"output_dir\": \"tmp/\", \"model\": \"cosyvoice-v2\", \"voice\": \"longcheng_v2\", \"format\": \"pcm\", \"sample_rate\": 24000, \"volume\": 50, \"rate\": 1, \"pitch\": 1}', NULL, NULL, 22, NULL, NULL, NULL, NULL);

-- Update the Alibaba Bailian streaming TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://bailian.console.aliyun.com/?apiKey=1#/api-key',
`remark` = 'Alibaba Bailian streaming TTS notes:
1. Visit https://bailian.console.aliyun.com/?apiKey=1#/api-key to create a project and get the appkey
2. Supports real-time streaming synthesis with low latency
3. Supports multiple voice settings and audio parameter adjustment
4. Supports CosyVoice-V3 large-model voices at an affordable price (0.4 CNY per 10,000 characters)
5. Supports real-time adjustment of volume, speech rate, pitch and other parameters
6. To use the CosyVoice-V3 model and some restricted voice types, contact Alibaba Bailian customer service to apply
' WHERE `id` = 'TTS_AliBLStreamTTS';

-- Add Alibaba Bailian streaming TTS voices
delete from `ai_tts_voice` where tts_model_id = 'TTS_AliBLStreamTTS';

-- Voice Assistant
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0001', 'TTS_AliBLStreamTTS', 'Longxiaochun-Intellectual Upbeat Female', 'longxiaochun_v2', 'English', NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0002', 'TTS_AliBLStreamTTS', 'Longxiaoxia-Steady Authoritative Female', 'longxiaoxia_v2', 'English', NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL);

-- Livestream Sales
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0003', 'TTS_AliBLStreamTTS', 'Longanran-Lively Textured Female', 'longanran', 'English', NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0004', 'TTS_AliBLStreamTTS', 'Longanxuan-Classic Livestream Female', 'longanxuan', 'English', NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL);

-- Social Companion
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0005', 'TTS_AliBLStreamTTS', 'Longhan-Warm Devoted Male', 'longhan_v2', 'English', NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0006', 'TTS_AliBLStreamTTS', 'Longyan-Warm Spring Breeze Female', 'longyan_v2', 'English', NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0007', 'TTS_AliBLStreamTTS', 'Longfeifei-Sweet Affected Female', 'longfeifei_v2', 'English', NULL, NULL, NULL, NULL, 7, NULL, NULL, NULL, NULL);

-- Dialect
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0008', 'TTS_AliBLStreamTTS', 'Longlaotie-Frank Northeastern Guy', 'longlaotie_v2', 'English', NULL, NULL, NULL, NULL, 8, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0009', 'TTS_AliBLStreamTTS', 'Longjiayi-Intellectual Cantonese Female', 'longjiayi_v2', 'English', NULL, NULL, NULL, NULL, 9, NULL, NULL, NULL, NULL);

-- Child voice
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0010', 'TTS_AliBLStreamTTS', 'Longjielidou-Sunny Mischievous Male', 'longjielidou_v2', 'English', NULL, NULL, NULL, NULL, 10, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0011', 'TTS_AliBLStreamTTS', 'Longling-Childish Stiff Female', 'longling_v2', 'English', NULL, NULL, NULL, NULL, 11, NULL, NULL, NULL, NULL);

-- Poetry Recitation
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0012', 'TTS_AliBLStreamTTS', 'Li Bai-Ancient Poet-Immortal Male', 'libai_v2', 'English', NULL, NULL, NULL, NULL, 12, NULL, NULL, NULL, NULL);

-- Overseas Marketing
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0013', 'TTS_AliBLStreamTTS', 'loongeva-Intellectual English Female', 'loongeva_v2', 'English', NULL, NULL, NULL, NULL, 13, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0014', 'TTS_AliBLStreamTTS', 'loongbrian-Steady English Male', 'loongbrian_v2', 'English', NULL, NULL, NULL, NULL, 14, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0015', 'TTS_AliBLStreamTTS', 'loongkyong-Korean female', 'loongkyong_v2', 'English', NULL, NULL, NULL, NULL, 15, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0016', 'TTS_AliBLStreamTTS', 'loongtomoka-Japanese female', 'loongtomoka_v2', 'English', NULL, NULL, NULL, NULL, 16, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_AliBLStreamTTS_0017', 'TTS_AliBLStreamTTS', 'loongtomoya-Japanese male', 'loongtomoya_v2', 'English', NULL, NULL, NULL, NULL, 17, NULL, NULL, NULL, NULL);
-- ===== end 202509161701.sql =====

-- ===== begin 202509221530.sql =====
-- Add SM2 (Chinese national cryptographic standard) key parameters
-- Used for server-side SM2 encryption and decryption

-- Add SM2 key parameters
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES 
(120, 'server.public_key', '', 'string', 1, 'Server SM2 public key'),
(121, 'server.private_key', '', 'string', 1, 'Server SM2 private key');
-- ===== end 202509221530.sql =====

-- ===== begin 202509191545.sql =====
-- Add the iFlytek streaming TTS provider
delete from `ai_model_provider` where id = 'SYSTEM_TTS_XunFeiStreamTTS';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_TTS_XunFeiStreamTTS', 'TTS', 'xunfei_stream', 'iFlytek streaming speech synthesis', '[{"key":"app_id","label":"APP_ID","type":"string"},{"key":"api_secret","label":"API_Secret","type":"string"},{"key":"api_key","label":"API key","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"voice","label":"Voice","type":"string"},{"key":"format","label":"Audio format","type":"string"},{"key":"sample_rate","label":"Sample rate","type":"number"},{"key": "volume", "type": "number", "label": "Volume"},{"key": "speed", "type": "number", "label": "Speech rate"},{"key": "pitch", "type": "number", "label": "Pitch"},{"key": "oral_level", "type": "number", "label": "Colloquial level"},{"key": "spark_assist", "type": "number", "label": "Whether colloquial"},{"key": "stop_split", "type": "number", "label": "Server-side sentence splitting"},{"key": "remain", "type": "number", "label": "Keep written language"}]', 20, 1, NOW(), 1, NOW());

-- Add the iFlytek streaming TTS model configuration
delete from `ai_model_config` where id = 'TTS_XunFeiStreamTTS';
INSERT INTO `ai_model_config` VALUES ('TTS_XunFeiStreamTTS', 'TTS', 'XunFeiStreamTTS', 'iFlytek streaming speech synthesis', 0, 1, '{\"type\": \"xunfei_stream\", \"app_id\": \"\", \"api_secret\": \"\", \"api_key\": \"\", \"output_dir\": \"tmp/\", \"voice\": \"x5_lingxiaoxuan_flow\", \"format\": \"raw\", \"sample_rate\": 24000, \"volume\": 50, \"speed\": 50, \"pitch\": 50, \"oral_level\": \"mid\", \"spark_assist\": 1, \"stop_split\": 0, \"remain\": 0}', NULL, NULL, 23, NULL, NULL, NULL, NULL);

-- Update the iFlytek streaming TTS configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.xfyun.cn/app/myapp',
`remark` = 'iFlytek streaming TTS notes:
1. Log in to the iFlytek speech technology platform https://console.xfyun.cn/app/myapp and create the relevant application
2. Select the services you need to get the api-related configuration https://console.xfyun.cn/services/uts
3. Purchase the relevant services for the application (APPID) you want to use, for example: Super-Humanoid Synthesis https://console.xfyun.cn/services/uts
5. Supports real-time dual-stream communication with low latency
6. Supports colloquial settings and audio parameter adjustment. Note: V5 voices do not support colloquial configuration
7. Supports real-time adjustment of volume, speech rate, pitch and other parameters
' WHERE `id` = 'TTS_XunFeiStreamTTS';

-- Add iFlytek streaming TTS voices
delete from `ai_tts_voice` where tts_model_id = 'TTS_XunFeiStreamTTS';

-- Basic Characters
INSERT INTO `ai_tts_voice` VALUES ('TTS_XunFeiStreamTTS_0001', 'TTS_XunFeiStreamTTS', 'Ling Xiaoxuan', 'x5_lingxiaoxuan_flow', 'English', NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_XunFeiStreamTTS_0002', 'TTS_XunFeiStreamTTS', 'Ling Feiyi', 'x5_lingfeiyi_flow', 'English', NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_XunFeiStreamTTS_0003', 'TTS_XunFeiStreamTTS', 'Ling Xiaoyue', 'x5_lingxiaoyue_flow', 'English', NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_XunFeiStreamTTS_0004', 'TTS_XunFeiStreamTTS', 'Ling Yuzhao', 'x5_lingyuzhao_flow', 'English', NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_XunFeiStreamTTS_0005', 'TTS_XunFeiStreamTTS', 'Ling Yuyan', 'x5_lingyuyan_flow', 'English', NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL);

-- The corresponding character voices need to be added
INSERT INTO `ai_tts_voice` VALUES ('TTS_XunFeiStreamTTS_0006', 'TTS_XunFeiStreamTTS', 'Ling Feizhe', 'x4_lingfeizhe_oral', 'English', NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_XunFeiStreamTTS_0007', 'TTS_XunFeiStreamTTS', 'Ling Xiaoli', 'x4_lingxiaoli_oral', 'English', NULL, NULL, NULL, NULL, 7, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_XunFeiStreamTTS_0008', 'TTS_XunFeiStreamTTS', 'Ling Xiaotang', 'x5_lingxiaotang_flow', 'English', NULL, NULL, NULL, NULL, 8, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_XunFeiStreamTTS_0009', 'TTS_XunFeiStreamTTS', 'Ling Xiaoqi', 'x4_lingxiaoqi_oral', 'English', NULL, NULL, NULL, NULL, 9, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_XunFeiStreamTTS_0010', 'TTS_XunFeiStreamTTS', 'Ling Youyou-Childhood Female Voice', 'x4_lingyouyou_oral', 'English', NULL, NULL, NULL, NULL, 10, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_XunFeiStreamTTS_0011', 'TTS_XunFeiStreamTTS', 'Zijin', 'x4_zijin_oral', 'English', NULL, NULL, NULL, NULL, 11, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_XunFeiStreamTTS_0012', 'TTS_XunFeiStreamTTS', 'Ziyang', 'x4_ziyang_oral', 'English', NULL, NULL, NULL, NULL, 12, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_XunFeiStreamTTS_0013', 'TTS_XunFeiStreamTTS', 'Grant', 'x5_EnUs_Grant_flow', 'English', NULL, NULL, NULL, NULL, 13, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_XunFeiStreamTTS_0014', 'TTS_XunFeiStreamTTS', 'Lila', 'x5_EnUs_Lila_flow', 'English', NULL, NULL, NULL, NULL, 14, NULL, NULL, NULL, NULL);
-- ===== end 202509191545.sql =====

-- ===== begin 202509220926.sql =====
-- Add the iFlytek streaming speech recognition service configuration
delete from `ai_model_provider` where id = 'SYSTEM_ASR_XunfeiStream';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_XunfeiStream', 'ASR', 'xunfei_stream', 'iFlytek streaming speech recognition', '[{"key":"app_id","label":"App ID","type":"string"},{"key":"api_key","label":"API_KEY","type":"password"},{"key":"api_secret","label":"API_SECRET","type":"password"},{"key":"domain","label":"Recognition domain","type":"string"},{"key":"language","label":"Recognition language","type":"string"},{"key":"accent","label":"Dialect","type":"string"},{"key":"dwa","label":"Dynamic correction","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]', 18, 1, NOW(), 1, NOW());

delete from `ai_model_config` where id = 'ASR_XunfeiStream';
INSERT INTO `ai_model_config` VALUES ('ASR_XunfeiStream', 'ASR', 'iFlytek Streaming ASR', 'iFlytek streaming speech recognition service', 0, 1, '{"type": "xunfei_stream", "app_id": "", "api_key": "", "api_secret": "", "domain": "slm", "language": "zh_cn", "accent": "mandarin", "dwa": "wpgs", "output_dir": "tmp/"}', 'https://www.xfyun.cn/doc/spark/spark_zh_iat.html', 'Supports real-time streaming speech recognition, suitable for Chinese Mandarin and recognition of multiple dialects', 21, NULL, NULL, NULL, NULL);

-- Update the iFlytek streaming speech recognition model configuration documentation
UPDATE `ai_model_config` SET
`doc_link` = 'https://www.xfyun.cn/doc/spark/spark_zh_iat.html',
`remark` = 'iFlytek streaming speech recognition configuration notes:
1. Log in to the iFlytek Open Platform https://www.xfyun.cn/
2. Create a speech recognition application to get the APPID, APISecret and APIKey
3. Parameter notes:
   - app_id: application ID, obtained after creating an application on the iFlytek Open Platform
   - api_key: API key, used for API authentication
   - api_secret: API secret, used to generate signatures
   - domain: recognition domain, default slm (intelligent speech transcription)
   - language: recognition language, default zh_cn (Chinese)
   - accent: dialect type, default mandarin (Mandarin), supports cantonese (Cantonese), etc.
   - dwa: dynamic correction, default wpgs (dynamic correction enabled)
   - output_dir: audio file output directory, default tmp/
4. Supports real-time streaming recognition, suitable for real-time voice interaction scenarios
5. Supports recognition of multiple dialects and languages
' WHERE `id` = 'ASR_XunfeiStream';
-- ===== end 202509220926.sql =====

-- ===== begin 202509220958.sql =====
delete from `ai_model_config` where id = 'LLM_XunfeiSparkLLM';
INSERT INTO `ai_model_config` VALUES ('LLM_XunfeiSparkLLM', 'LLM', 'iFlytek Spark LLM', 'iFlytek Spark LLM', 0, 1, '{"type": "openai", "model_name": "generalv3.5", "base_url": "https://spark-api-open.xf-yun.com/v1", "api_password": "your_api_password", "temperature": 0.5, "max_tokens": 2048, "top_p": 1.0, "frequency_penalty": 0.0}', 'https://www.xfyun.cn/doc/spark/HTTP%E8%B0%83%E7%94%A8%E6%96%87%E6%A1%A3.html', 'iFlytek Spark LLM, supports multi-turn dialogue, text generation and other features', 14, NULL, NULL, NULL, NULL);

-- Update the documentation for the iFlytek Spark LLM configuration
UPDATE `ai_model_config` SET
`doc_link` = 'https://www.xfyun.cn/doc/spark/HTTP%E8%B0%83%E7%94%A8%E6%96%87%E6%A1%A3.html',
`remark` = 'iFlytek Spark LLM configuration notes:
1. Log in to the iFlytek Open Platform https://www.xfyun.cn/. Each model has its own api_password; when changing models, check the api_password of the corresponding model
2. Create a Spark LLM application to obtain the API Password
3. Parameter description:
   - api_password: API Password, obtained after creating an application on the iFlytek Open Platform
   - model_name: model name, supports generalv3.5, generalv3 and other versions
   - base_url: API URL, default https://spark-api-open.xf-yun.com/v1
   - temperature: temperature parameter, controls generation randomness, range 0-1, default 0.5
   - max_tokens: maximum number of output tokens, default 2048
   - top_p: nucleus sampling parameter, controls vocabulary diversity, default 1.0
   - frequency_penalty: frequency penalty, reduces repeated content, default 0.0
4. Each model has its own api_password; when changing models, check the api_password of the corresponding model.
' WHERE `id` = 'LLM_XunfeiSparkLLM';
-- ===== end 202509220958.sql =====

-- ===== begin 202510071522.sql =====
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
-- ===== end 202510071522.sql =====

-- ===== begin 202510191042.sql =====
UPDATE `ai_model_config` SET model_code = 'XunfeiSparkLLM' WHERE id = 'LLM_XunfeiSparkLLM';
UPDATE `ai_model_config` SET model_code = 'XunfeiStreamASR' WHERE id = 'ASR_XunfeiStream';
-- ===== end 202510191042.sql =====

-- ===== begin 202510250956.sql =====
-- Add the RAG model provider and config
-- -------------------------------------------------------

-- Add the RAG model provider
delete from `ai_model_provider` where id = 'SYSTEM_RAG_ragflow';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_RAG_ragflow', 'RAG', 'ragflow', 'RAGFlow', '[{"key": "base_url", "type": "string", "label": "Service URL"}, {"key": "api_key", "type": "string", "label": "API key"}]', 1, 1, NOW(), 1, NOW());

-- Add the RAG model config
delete from `ai_model_config` where id = 'RAG_RAGFlow';
INSERT INTO `ai_model_config` VALUES ('RAG_RAGFlow', 'RAG', 'ragflow', 'RAGFlow', 1, 1, '{"type": "ragflow", "base_url": "http://localhost", "api_key": "your_rag_api_key"}', 'https://github.com/infiniflow/ragflow/blob/main/README_zh.md', 'RAGFlow configuration notes:
I. Quick deployment tutorial (Docker deployment)
1.$ sysctl vm.max_map_count
2.$ sysctl -w vm.max_map_count=262144
3.$ git clone https://github.com/infiniflow/ragflow.git
4.docker compose -f docker-compose.yml up -d
5.$ docker logs -f docker-ragflow-cpu-1
6. After registering and logging in, click the avatar in the upper right corner to get the RAGFlow API KEY and API server address. Before using RAGFlow, add models and set the default model in Model Provider.
II. If you want to disable registration
1. Stop the service   docker compose down
2. sed -i ''s/REGISTER_ENABLED=1/REGISTER_ENABLED=0/g'' .env   
3.cat .env | grep -i register
4. Once you see REGISTER_ENABLED=0, restart the service.',  1, NULL, NULL, NULL, NULL);

-- ===== end 202510250956.sql =====

-- ===== begin 202510251150.sql =====
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
-- ===== end 202510251150.sql =====

-- ===== begin 202511131023.sql =====
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/infiniflow/ragflow/blob/main/README_zh.md',
`remark` = 'For the detailed deployment tutorial, see: https://github.com/xinnan-tech/xiaozhi-esp32-server/blob/main/docs/ragflow-integration.md
After a successful deployment, register and log in, then click the avatar in the upper right corner to get the RAGFlow API KEY and API server address. Before using RAGFlow, add models and set the default model in Model Provider.' WHERE `id` = 'RAG_RAGFlow';

update `ai_model_config` set `model_name` = 'External LLM intent recognition' where `id` = 'Intent_intent_llm';
update `ai_model_config` set `model_name` = 'LLM autonomous function calling' where `id` = 'Intent_function_call';
update `ai_model_config` set `model_name` = 'Bailian agent application' where `id` = 'LLM_AliAppLLM';

update `ai_model_provider` set `name` = 'External LLM intent recognition' , `fields` =  '[{"key":"llm","label":"Referenced LLM model","type":"string"}]' where  id = 'SYSTEM_Intent_intent_llm';
update `ai_model_provider` set `name` = 'LLM autonomous function calling' where  id = 'SYSTEM_Intent_function_call';

UPDATE ai_model_config set model_name = 'Linkerai (streaming)' where id = 'TTS_LinkeraiTTS';
UPDATE ai_model_config set model_name = 'Volcano Engine (streaming)' where id = 'TTS_HuoshanDoubleStreamTTS';
UPDATE ai_model_config set model_name = 'Alibaba Bailian (streaming)' where id = 'TTS_AliBLStreamTTS';
UPDATE ai_model_config set model_name = 'iFlytek (streaming)' where id = 'TTS_XunFeiStreamTTS';
UPDATE ai_model_config set model_name = 'Minimax (streaming)' where id = 'TTS_MinimaxStreamTTS';
UPDATE ai_model_config set model_name = 'Alibaba Cloud (streaming)' where id = 'TTS_AliyunStreamTTS';
UPDATE ai_model_config set model_name = 'PaddleSpeech (streaming)' where id = 'TTS_PaddleSpeechTTS';
UPDATE ai_model_config set model_name = 'IndexTTS (streaming)' where id = 'TTS_IndexStreamTTS';

update ai_model_config SET sort = 2 where id = 'TTS_LinkeraiTTS';
update ai_model_config SET sort = 3 where id = 'TTS_HuoshanDoubleStreamTTS';
update ai_model_config SET sort = 4 where id = 'TTS_AliBLStreamTTS';
update ai_model_config SET sort = 5 where id = 'TTS_XunFeiStreamTTS';
update ai_model_config SET sort = 6 where id = 'TTS_MinimaxStreamTTS';
update ai_model_config SET sort = 7 where id = 'TTS_AliyunStreamTTS';
update ai_model_config SET sort = 8 where id = 'TTS_IndexStreamTTS';
update ai_model_config SET sort = 9 where id = 'TTS_PaddleSpeechTTS';
update ai_model_config SET sort = 10 where id = 'TTS_DoubaoTTS';
update ai_model_config SET sort = 11 where id = 'TTS_TencentTTS';
update ai_model_config SET sort = 12 where id = 'TTS_AliyunTTS';
update ai_model_config SET sort = 13 where id = 'TTS_OpenAITTS';
update ai_model_config SET sort = 14 where id = 'TTS_CosyVoiceSiliconflow';
update ai_model_config SET sort = 15 where id = 'TTS_CozeCnTTS';
update ai_model_config SET sort = 16 where id = 'TTS_FishSpeech';
update ai_model_config SET sort = 17 where id = 'TTS_GPT_SOVITS_V3';
update ai_model_config SET sort = 18 where id = 'TTS_GPT_SOVITS_V2';
update ai_model_config SET sort = 19 where id = 'TTS_TTS302AI';
update ai_model_config SET sort = 20 where id = 'TTS_GizwitsTTS';
update ai_model_config SET sort = 21 where id = 'TTS_VolcesAiGatewayTTS';
update ai_model_config SET sort = 22 where id = 'TTS_ACGNTTS';
update ai_model_config SET sort = 23 where id = 'TTS_CustomTTS';

UPDATE ai_model_config set model_name = 'iFlytek speech recognition (streaming)' where id = 'ASR_XunfeiStream';
UPDATE ai_model_config set model_name = 'Qwen3Flash speech recognition' where id = 'ASR_Qwen3Flash';

update ai_model_config SET sort = 2 where id = 'ASR_FunASRServer';
update ai_model_config SET sort = 3 where id = 'ASR_XunfeiStream';
update ai_model_config SET sort = 4 where id = 'ASR_AliyunStreamASR';
update ai_model_config SET sort = 5 where id = 'ASR_DoubaoStreamASR';
update ai_model_config SET sort = 6 where id = 'ASR_TencentASR';
update ai_model_config SET sort = 7 where id = 'ASR_BaiduASR';
update ai_model_config SET sort = 8 where id = 'ASR_DoubaoASR';
update ai_model_config SET sort = 9 where id = 'ASR_AliyunASR';
update ai_model_config SET sort = 10 where id = 'ASR_SherpaASR';
update ai_model_config SET sort = 11 where id = 'ASR_OpenaiASR';
update ai_model_config SET sort = 12 where id = 'ASR_GroqASR';
update ai_model_config SET sort = 13 where id = 'ASR_VoskASR';
update ai_model_config SET sort = 14 where id = 'ASR_Qwen3Flash';

UPDATE ai_model_config SET config_json='{\"type\": \"openai\", \"base_url\": \"https://ark.cn-beijing.volces.com/api/v3\", \"model_name\": \"doubao-1-5-pro-32k-250115\", \"api_key\": \"your_api_key\"}' where id = 'LLM_DoubaoLLM' AND config_json LIKE '%your_api_key"%';
-- ===== end 202511131023.sql =====

-- ===== begin 202511221450.sql =====
-- Update the HuoshanDoubleStreamTTS provider config, adding the connection reuse option
UPDATE `ai_model_provider`
SET fields = '[{"key": "ws_url", "type": "string", "label": "WebSocket URL"}, {"key": "appid", "type": "string", "label": "App ID"}, {"key": "access_token", "type": "string", "label": "Access token"}, {"key": "resource_id", "type": "string", "label": "Resource ID"}, {"key": "speaker", "type": "string", "label": "Default voice"}, {"key": "enable_ws_reuse", "type": "boolean", "label": "Enable connection reuse", "default": true}, {"key": "speech_rate", "type": "number", "label": "Speech rate (-50~100)"}, {"key": "loudness_rate", "type": "number", "label": "Volume (-50~100)"}, {"key": "pitch", "type": "number", "label": "Pitch (-12~12)"}]'
WHERE id = 'SYSTEM_TTS_HSDSTTS';

UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/speech/service/10007',
`remark` = 'Volcano Engine speech synthesis service configuration notes:
1. Visit https://www.volcengine.com/ to register and activate a Volcano Engine account
2. Visit https://console.volcengine.com/speech/service/10007 to activate the speech synthesis model and purchase voices
3. Get the appid and access_token at the bottom of the page
5. The resource ID is fixed as: volc.service_type.10029 (large-model speech synthesis and mixing)
6. Connection reuse: enables WebSocket connection reuse, default true to reduce connection overhead (note: after reuse, idle connections count toward concurrency while the device is in listening state)
7. Speech rate: -50~100, optional, normal default 0, can be set to -50~100
8. Volume: -50~100, optional, normal default 0, can be set to -50~100
9. Pitch: -12~12, optional, normal default 0, can be set to -12~12
10. Fill them into the configuration file' WHERE `id` = 'TTS_HuoshanDoubleStreamTTS';
-- ===== end 202511221450.sql =====

-- ===== begin 202512031517.sql =====
-- Add system feature menu config parameter
delete from `sys_params` where param_code = 'system-web.menu';

-- Add system feature menu config parameter
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES 
(600, 'system-web.menu', '{"features":{"voiceprintRecognition":{"name":"feature.voiceprintRecognition.name","enabled":false,"description":"feature.voiceprintRecognition.description"},"voiceClone":{"name":"feature.voiceClone.name","enabled":false,"description":"feature.voiceClone.description"},"knowledgeBase":{"name":"feature.knowledgeBase.name","enabled":false,"description":"feature.knowledgeBase.description"},"mcpAccessPoint":{"name":"feature.mcpAccessPoint.name","enabled":false,"description":"feature.mcpAccessPoint.description"},"vad":{"name":"feature.vad.name","enabled":true,"description":"feature.vad.description"},"asr":{"name":"feature.asr.name","enabled":true,"description":"feature.asr.description"}},"groups":{"featureManagement":["voiceprintRecognition","voiceClone","knowledgeBase","mcpAccessPoint"],"voiceManagement":["vad","asr"]}}', 'json', 1, 'System feature menu config');
-- ===== end 202512031517.sql =====

-- ===== begin 202512041515.sql =====

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
-- ===== end 202512041515.sql =====

-- ===== begin 202512131453.sql =====
-- Delete the parameter for whether the server module enables token authentication
delete from `sys_params` where param_code = 'server.auth.enabled';

-- Add the parameter for whether the server module enables token authentication
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES 
(122, 'server.auth.enabled', 'true', 'boolean', 1, 'Whether the server module enables token authentication');
-- ===== end 202512131453.sql =====

-- ===== begin 202512161529.sql =====
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (311, 'enable_websocket_ping', 'false', 'boolean', 1, 'Whether to enable the WebSocket heartbeat keep-alive mechanism');
-- ===== end 202512161529.sql =====

-- ===== begin 202512192245.sql =====
-- Add an audio ID index to the agent chat history
ALTER TABLE ai_agent_chat_history ADD INDEX idx_ai_agent_chat_history_audio_id (audio_id);
-- ===== end 202512192245.sql =====

-- ===== begin 202512221117.sql =====
-- Update the Doubao streaming ASR provider, adding the end_window_size config
delete from `ai_model_provider` where id = 'SYSTEM_ASR_DoubaoStreamASR';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_DoubaoStreamASR', 'ASR', 'doubao_stream', 'Volcano Engine speech recognition (streaming)', '[{"key":"appid","label":"App ID","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"cluster","label":"Cluster","type":"string"},{"key":"boosting_table_name","label":"Hotword file name","type":"string"},{"key":"correct_table_name","label":"Replacement word file name","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"end_window_size","label":"Silence detection duration (ms)","type":"number"}]', 3, 1, NOW(), 1, NOW());


-- Update the Doubao streaming ASR model config, adding the end_window_size default value
UPDATE `ai_model_config` SET
`config_json` = JSON_SET(`config_json`, '$.end_window_size', 200)
WHERE `id` = 'ASR_DoubaoStreamASR' AND JSON_EXTRACT(`config_json`, '$.end_window_size') IS NULL;
-- ===== end 202512221117.sql =====

-- ===== begin 202512301430.sql =====
-- Add the Alibaba Bailian Paraformer real-time speech recognition service config
delete from `ai_model_provider` where id = 'SYSTEM_ASR_AliyunBLStream';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_AliyunBLStream', 'ASR', 'aliyunbl_stream', 'Alibaba Bailian Paraformer real-time speech recognition', '[{"key":"api_key","label":"API key","type":"password"},{"key":"model","label":"Model name","type":"string"},{"key":"format","label":"Audio format","type":"string"},{"key":"sample_rate","label":"Sample rate","type":"number"},{"key":"output_dir","label":"Output directory","type":"string"}]', 18, 1, NOW(), 1, NOW());

delete from `ai_model_config` where id = 'ASR_AliyunBLStream';
INSERT INTO `ai_model_config` VALUES ('ASR_AliyunBLStream', 'ASR', 'AliyunBLStream', 'Alibaba Bailian Paraformer real-time speech recognition', 0, 1, '{"type": "aliyunbl_stream", "api_key": "", "model": "paraformer-realtime-v2", "format": "pcm", "sample_rate": 16000, "disfluency_removal_enabled": false, "semantic_punctuation_enabled": false, "max_sentence_silence": 200, "multi_threshold_mode_enabled": false, "punctuation_prediction_enabled": true, "inverse_text_normalization_enabled": true, "output_dir": "tmp/"}', 'https://help.aliyun.com/zh/model-studio/websocket-for-paraformer-real-time-service', 'Supports advanced features such as multiple languages, custom hotwords and semantic sentence segmentation', 21, NULL, NULL, NULL, NULL);

-- Update the documentation for the Alibaba Bailian Paraformer model config
UPDATE `ai_model_config` SET
`doc_link` = 'https://help.aliyun.com/zh/model-studio/websocket-for-paraformer-real-time-service',
`remark` = 'Alibaba Bailian Paraformer real-time speech recognition configuration notes:
1. Log in to the Alibaba Cloud Bailian platform https://bailian.console.aliyun.com/
2. Create an API-KEY https://bailian.console.aliyun.com/#/api-key
3. Supported models: paraformer-realtime-v2 (recommended), paraformer-realtime-8k-v2, paraformer-realtime-v1, paraformer-realtime-8k-v1
4. Features:
   - Multi-language support (Chinese including dialects, English, Japanese, Korean, German, French, Russian)
   - Custom hotwords (vocabulary_id parameter); for details see: https://help.aliyun.com/zh/model-studio/custom-hot-words?
   - Semantic / VAD sentence segmentation (semantic_punctuation_enabled parameter)
   - Automatic punctuation, ITN, filler word filtering, etc.
5. Parameter description:
   - model: model name, paraformer-realtime-v2 recommended
   - sample_rate: sample rate (Hz); v2 supports any sample rate, v1 only supports 16000, the 8k versions only support 8000
   - semantic_punctuation_enabled: false for VAD segmentation (low latency), true for semantic segmentation (high accuracy)
   - max_sentence_silence: VAD segmentation silence duration threshold (200-6000ms)
' WHERE `id` = 'ASR_AliyunBLStream';


-- Update the Doubao streaming ASR provider, adding config
delete from `ai_model_provider` where id = 'SYSTEM_ASR_DoubaoStreamASR';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_DoubaoStreamASR', 'ASR', 'doubao_stream', 'Volcano Engine speech recognition (streaming)', '[{"key":"appid","label":"App ID","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"cluster","label":"Cluster","type":"string"},{"key":"boosting_table_name","label":"Hotword file name","type":"string"},{"key":"correct_table_name","label":"Replacement word file name","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"end_window_size","label":"Silence detection duration (ms)","type":"number"},{"key":"enable_multilingual","label":"Enable multilingual recognition mode","type":"boolean"},{"key":"language","label":"Specified language code","type":"string"}]', 3, 1, NOW(), 1, NOW());
UPDATE `ai_model_config` SET 
`remark` = 'Doubao ASR configuration notes:
1. The difference between Doubao ASR and Doubao (streaming) ASR: Doubao ASR is billed per request, Doubao (streaming) ASR is billed per hour
2. Per-request billing is generally cheaper, but Doubao (streaming) ASR uses large-model technology and performs better
3. You need to create an application in the Volcano Engine console and get the appid and access_token
4. Supports Chinese speech recognition
5. Requires a network connection
6. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://console.volcengine.com/speech/app
2. Create a new application
3. Get the appid and access_token
4. Fill them into the configuration file
To set hotwords, see: https://www.volcengine.com/docs/6561/155738
To enable multilingual recognition mode, set language. When this key is empty, the model supports Chinese, English, Shanghainese, Hokkien, and Sichuan, Shaanxi and Cantonese dialect recognition. For other languages see: https://www.volcengine.com/docs/6561/1354869
' WHERE `id` = 'ASR_DoubaoStreamASR';

-- Update the Doubao streaming ASR model config, adding the enable_multilingual default value
UPDATE `ai_model_config` SET
`config_json` = JSON_SET(
    `config_json`, 
    '$.enable_multilingual', false,
    '$.language', 'zh-CN'
)
WHERE `id` = 'ASR_DoubaoStreamASR' 
AND JSON_EXTRACT(`config_json`, '$.enable_multilingual') IS NULL 
AND JSON_EXTRACT(`config_json`, '$.language') IS NULL;


-- Update the HuoshanDoubleStreamTTS provider config, adding multi-emotion voice parameters
UPDATE `ai_model_provider`
SET `fields` = '[{"key": "ws_url", "type": "string", "label": "WebSocket URL"}, {"key": "appid", "type": "string", "label": "App ID"}, {"key": "access_token", "type": "string", "label": "Access token"}, {"key": "resource_id", "type": "string", "label": "Resource ID"}, {"key": "speaker", "type": "string", "label": "Default voice"}, {"key": "enable_ws_reuse", "type": "boolean", "label": "Enable connection reuse", "default": true}, {"key": "speech_rate", "type": "number", "label": "Speech rate (-50~100)"}, {"key": "loudness_rate", "type": "number", "label": "Volume (-50~100)"}, {"key": "pitch", "type": "number", "label": "Pitch (-12~12)"}, {"key": "emotion_scale", "type": "number", "label": "Emotion intensity(1-5)"}, {"key": "emotion", "type": "string", "label": "Emotion type"}]'
WHERE `id` = 'SYSTEM_TTS_HSDSTTS';

-- Update default values
UPDATE `ai_model_config` SET
`config_json` = JSON_SET(
    `config_json`,
    '$.emotion', 'neutral',
    '$.emotion_scale', 4
)
WHERE `id` = 'TTS_HuoshanDoubleStreamTTS'
AND JSON_EXTRACT(`config_json`, '$.emotion') IS NULL 
AND JSON_EXTRACT(`config_json`, '$.emotion_scale') IS NULL;

-- Add documentation link and remarks
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/speech/service/10007',
`remark` = 'Volcano Engine speech synthesis service configuration notes:
1. Visit https://www.volcengine.com/ to register and activate a Volcano Engine account
2. Visit https://console.volcengine.com/speech/service/10007 to activate the speech synthesis model and purchase voices
3. Get the appid and access_token at the bottom of the page
5. The resource ID is fixed as: volc.service_type.10029 (large-model speech synthesis and mixing)
6. Connection reuse: enables WebSocket connection reuse, default true to reduce connection overhead (note: after reuse, idle connections count toward concurrency while the device is in listening state)
7. Speech rate: -50~100, optional, normal default 0, can be set to -50~100
8. Volume: -50~100, optional, normal default 0, can be set to -50~100
9. Pitch: -12~12, optional, normal default 0, can be set to -12~12
10. Multi-emotion parameters (currently only some voices support setting emotions):
   Related voice list: https://www.volcengine.com/docs/6561/1257544
    - emotion_scale: emotion intensity, allowed values: 1~5, default 4
    - emotion: emotion type, allowed values: neutral, happy, sad, angry, fearful, disgusted, surprised
' WHERE `id` = 'TTS_HuoshanDoubleStreamTTS';
-- ===== end 202512301430.sql =====

-- ===== begin 202601051433.sql =====
-- Change the FunASRServer documentation model to SenseVoiceSmall
UPDATE `ai_model_config` SET 
`doc_link` = 'https://github.com/modelscope/FunASR/blob/main/runtime/docs/SDK_advanced_guide_online_zh.md',
`remark` = 'Deploy FunASR standalone and use the FunASR API service; only five commands are needed
Command 1: mkdir -p ./funasr-runtime-resources/models
Command 2: sudo docker run -d -p 10096:10095 --privileged=true -v $PWD/funasr-runtime-resources/models:/workspace/models registry.cn-hangzhou.aliyuncs.com/funasr_repo/funasr:funasr-runtime-sdk-online-cpu-0.1.12
After the previous command you will enter the container; continue with command 3: cd FunASR/runtime
Do not exit the container; continue in the container with command 4: nohup bash run_server_2pass.sh --download-model-dir /workspace/models --vad-dir damo/speech_fsmn_vad_zh-cn-16k-common-onnx --model-dir iic/SenseVoiceSmall-onnx  --online-model-dir damo/speech_paraformer-large_asr_nat-zh-cn-16k-common-vocab8404-online-onnx  --punc-dir damo/punc_ct-transformer_zh-cn-common-vad_realtime-vocab272727-onnx --lm-dir damo/speech_ngram_lm_zh-cn-ai-wesp-fst --itn-dir thuduj12/fst_itn_zh --hotword /workspace/models/hotwords.txt > log.txt 2>&1 &
After the previous command you will enter the container; continue with command 5: tail -f log.txt
After command 5 finishes you will see the model download log; once the download completes you can connect and use it
The above uses CPU inference. If you have a GPU, see: https://github.com/modelscope/FunASR/blob/main/runtime/docs/SDK_advanced_guide_online_zh.md' WHERE `id` = 'ASR_FunASRServer';
-- ===== end 202601051433.sql =====

-- ===== begin 202601141645.sql =====
-- Batch clean up the sample_rate field definitions in ai_model_provider
UPDATE `ai_model_provider` ap
JOIN (
    SELECT 
        id,
        JSON_ARRAYAGG(
            JSON_OBJECT('key', jt.k, 'label', jt.l, 'type', jt.t)
        ) AS new_fields
    FROM `ai_model_provider`,
         JSON_TABLE(`fields`, '$[*]' COLUMNS (
             k VARCHAR(50) PATH '$.key',
             l VARCHAR(100) PATH '$.label',
             t VARCHAR(20) PATH '$.type'
         )) AS jt
    WHERE `model_type` = 'TTS' 
      AND jt.k != 'sample_rate'
    GROUP BY id
) filtered ON ap.id = filtered.id
SET ap.fields = filtered.new_fields;

-- Clean up the top-level sample_rate in config_json
UPDATE `ai_model_config`
SET `config_json` = JSON_REMOVE(`config_json`, '$.sample_rate')
WHERE `model_type` = 'TTS'
  AND JSON_EXTRACT(`config_json`, '$.sample_rate') IS NOT NULL;

-- Clean up the sample_rate parameter of Minimax streaming TTS (inside audio_setting)
UPDATE `ai_model_config` SET 
`config_json` = JSON_SET(`config_json`, '$.audio_setting', JSON_REMOVE(JSON_EXTRACT(`config_json`, '$.audio_setting'), '$.sample_rate'))
WHERE `id` = 'TTS_MinimaxStreamTTS'
AND JSON_EXTRACT(`config_json`, '$.audio_setting.sample_rate') IS NOT NULL;
-- ===== end 202601141645.sql =====

-- ===== begin 202601231530.sql =====
-- Update the HuoshanDoubleStreamTTS provider config, changing the scattered parameters to JSON dict config
-- Consolidate parameters such as speech_rate, loudness_rate, pitch, emotion and emotion_scale into three JSON dicts: audio_params, additions and mix_speaker

UPDATE `ai_model_provider`
SET `fields` = '[
  {"key": "ws_url", "type": "string", "label": "WebSocket URL"},
  {"key": "appid", "type": "string", "label": "App ID"},
  {"key": "access_token", "type": "string", "label": "Access token"},
  {"key": "resource_id", "type": "string", "label": "Resource ID"},
  {"key": "speaker", "type": "string", "label": "Default voice"},
  {"key": "enable_ws_reuse", "type": "boolean", "label": "Enable connection reuse", "default": true},
  {"key": "audio_params", "type": "dict", "label": "Audio output config"},
  {"key": "additions", "type": "dict", "label": "Advanced text processing config"},
  {"key": "mix_speaker", "type": "dict", "label": "Mix control config"}
]'
WHERE `id` = 'SYSTEM_TTS_HSDSTTS';

-- Update the existing config, migrating the old scattered parameters to the new JSON dict structure
UPDATE `ai_model_config`
SET `config_json` = JSON_SET(
    `config_json`,
    '$.audio_params', JSON_OBJECT(
        'speech_rate', CAST(COALESCE(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`config_json`, '$.speech_rate')), ''), '0') AS SIGNED),
        'loudness_rate', CAST(COALESCE(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`config_json`, '$.loudness_rate')), ''), '0') AS SIGNED)
    ),
    '$.additions', JSON_OBJECT(
        'aigc_metadata', JSON_OBJECT(),
        'cache_config', JSON_OBJECT(),
        'post_process', JSON_OBJECT(
            'pitch', CAST(COALESCE(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`config_json`, '$.pitch')), ''), '0') AS SIGNED)
        )
    ),
    '$.mix_speaker', JSON_OBJECT()
)
WHERE `id` = 'TTS_HuoshanDoubleStreamTTS';

-- Delete the old scattered parameter fields
UPDATE `ai_model_config`
SET `config_json` = JSON_REMOVE(
    `config_json`,
    '$.speech_rate',
    '$.loudness_rate',
    '$.pitch',
    '$.emotion',
    '$.emotion_scale'
)
WHERE `id` = 'TTS_HuoshanDoubleStreamTTS';

-- Update documentation links and remarks
UPDATE `ai_model_config` SET
`doc_link` = 'https://www.volcengine.com/docs/6561/1329505',
`remark` = 'Volcano Engine bidirectional streaming TTS configuration notes:
1. Visit https://www.volcengine.com/ to register and activate a Volcano Engine account
2. Visit https://console.volcengine.com/speech/service/10007 to activate the speech synthesis model and purchase voices
3. Get the appid and access_token at the bottom of the page
4. The resource ID is fixed as: volc.service_type.10029 (large-model speech synthesis and mixing)
5. Connection reuse: enables WebSocket connection reuse, default true to reduce connection overhead (note: after reuse, idle connections count toward concurrency while the device is in listening state)

Detailed parameter documentation: https://www.volcengine.com/docs/6561/1329505
[audio_params] Audio output config - users can add any audio parameter supported by Volcano Engine
  - speech_rate: speech rate (-50~100), default 0
  - loudness_rate: volume (-50~100), default 0
  - emotion: emotion type (only some voices support it), allowed values: neutral, happy, sad, angry, fearful, disgusted, surprised
  - emotion_scale: emotion intensity (1~5), default 4
  Example: {"speech_rate": 10, "loudness_rate": 5, "emotion": "happy", "emotion_scale": 4}

[additions] Advanced text processing config - users can add any advanced parameter supported by Volcano Engine
  - post_process.pitch: pitch (-12~12), default 0
  - aigc_metadata: AIGC metadata config
  - cache_config: cache config
  Example: {"post_process": {"pitch": 2}, "aigc_metadata": {}, "cache_config": {}}

[mix_speaker] Mix control config - multi-voice mixing (TTS 1.0 only)
  Example:
    {"speakers": [
      {"source_speaker": "zh_male_bvlazysheep","mix_factor": 0.3}, 
      {"source_speaker": "BV120_streaming","mix_factor": 0.3}, 
      {"source_speaker": "zh_male_ahu_conversation_wvae_bigtts","mix_factor": 0.4}
    ]}

Note:
- The multi-emotion voice parameters (emotion, emotion_scale) are only supported by some voices
- Related voice list: https://www.volcengine.com/docs/6561/1257544
- Users can add more parameters according to the Volcano Engine API documentation
- The mixing feature mainly applies to Doubao speech synthesis model 1.0 voices; when using it, set req_params.speaker to custom_mix_bigtts
'
WHERE `id` = 'TTS_HuoshanDoubleStreamTTS';
-- ===== end 202601231530.sql =====

-- ===== begin 202601261730.sql =====
-- Change the default sample rate in the Xiaozhi parameters from 16000 to 24000
UPDATE `sys_params`
SET `param_value` = '{
  "type": "hello",
  "version": 1,
  "transport": "websocket",
  "audio_params": {
    "format": "opus",
    "sample_rate": 24000,
    "channels": 1,
    "frame_duration": 60
  }
}'
WHERE `id` = 309 AND `param_code` = 'xiaozhi';
-- ===== end 202601261730.sql =====

-- ===== begin 202602021555.sql =====
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (502, 'system_error_response', 'Master, Xiaozhi is a bit busy right now. Let\'s try again later.', 'string', 1, 'Reply on system error');
-- ===== end 202602021555.sql =====

-- ===== begin 202602051017.sql =====
-- Add the powermem memory model provider
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`)
VALUES ('SYSTEM_Memory_powermem', 'Memory', 'powermem', 'PowerMem memory', '[
  {"key":"enable_user_profile","label":"Enable user profile","type":"boolean"},
  {"key":"llm_provider","label":"LLM provider","type":"string"},
  {"key":"llm_api_key","label":"LLM API key","type":"string"},
  {"key":"llm_model","label":"LLM model","type":"string"},
  {"key":"openai_base_url","label":"OpenAI base URL","type":"string"},
  {"key":"embedding_provider","label":"Embedding provider","type":"string"},
  {"key":"embedding_api_key","label":"Embedding API key","type":"string"},
  {"key":"embedding_model","label":"Embedding model","type":"string"},
  {"key":"embedding_openai_base_url","label":"Embedding OpenAI base URL","type":"string"},
  {"key":"embedding_dims","label":"Embedding dimensions","type":"integer"},
  {"key":"vector_store","label":"Vector store config (JSON)","type":"dict"}
]', 4, 1, NOW(), 1, NOW());

-- Add the PowerMem memory model config
INSERT INTO `ai_model_config` VALUES (
  'Memory_powermem',
  'Memory',
  'powermem',
  'PowerMem memory',
  0,
  1,
  '{\"type\": \"powermem\", \"enable_user_profile\": true, \"llm_provider\": \"openai\", \"llm_api_key\": \"your_llm_api_key\", \"llm_model\": \"qwen-plus\", \"openai_base_url\": \"\", \"embedding_provider\": \"openai\", \"embedding_api_key\": \"your_embedding_api_key\", \"embedding_model\": \"text-embedding-v4\", \"embedding_openai_base_url\": \"https://api.openai.com/v1\", \"embedding_dims\": \"\", \"vector_store\": {\"provider\": \"sqlite\", \"config\": {}}}',
  NULL,
  NULL,
  4,
  NULL,
  NULL,
  NULL,
  NULL
);


-- PowerMem memory configuration notes
UPDATE `ai_model_config` SET
`doc_link` = 'https://github.com/oceanbase/powermem',
`remark` = 'PowerMem is an open-source agent memory component from OceanBase that summarizes memories via a local LLM
GitHub: https://github.com/oceanbase/powermem
Website: https://www.powermem.ai/
Usage examples: https://github.com/oceanbase/powermem/tree/main/examples

[Cost]
PowerMem itself is free; the actual cost depends on the chosen LLM and database:
- Using sqlite + a free LLM (e.g. glm-4-flash) = completely free
- Using a cloud LLM or cloud database = billed by the corresponding service

[enable_user_profile] User profile feature
- false: use the normal memory mode (AsyncMemory)
- true: use the user profile mode (UserMemory), which automatically extracts user information
- The user profile feature supports: oceanbase, seekdb, sqlite (powermem 0.3.0+)

[llm] LLM config - used for memory summarization and user profile extraction
  provider: LLM provider, allowed values:
    - qwen: Tongyi Qianwen (https://bailian.console.aliyun.com/?apiKey=1#/api-key)
    - openai: OpenAI-compatible API
    - zhipu: Zhipu AI (https://bigmodel.cn/usercenter/proj-mgmt/apikeys) - the free glm-4-flash is recommended
  config: LLM config parameters
    - api_key: API key (required)
    - model: model name, e.g. qwen-plus, glm-4-flash
    - openai_base_url: custom service URL (optional), e.g. https://api.openai.com/v1
  Example:
    {"provider": "zhipu", "config": {"api_key": "your_key", "model": "glm-4-flash"}}
    {"provider": "qwen", "config": {"api_key": "your_key", "model": "qwen-plus"}}

[embedder] Embedding config - used to vectorize memory content
  provider: embedding model provider, allowed values:
    - qwen: Tongyi Qianwen
    - openai: OpenAI-compatible API
  config: Embedding config parameters
    - api_key: API key (required)
    - model: model name, e.g. text-embedding-v4, text-embedding-3-small
    - openai_base_url: custom service URL (optional)
    - embedding_dims: vector dimensions (optional), must be configured when not 1536
  Example:
    {"provider": "openai", "config": {"api_key": "your_key", "model": "text-embedding-v4", "openai_base_url": "https://dashscope.aliyuncs.com/compatible-mode/v1"}}

[vector_store] Database storage config - used to store vectorized memories
  provider: database type, allowed values:
    - sqlite: lightweight local database (recommended for getting started, no extra configuration needed)
    - oceanbase: OceanBase database (recommended for production, best performance)
    - seekdb: SeekDB (recommended, integrated storage for AI applications)
    - postgres: PostgreSQL database

  SQLite config (no extra configuration needed):
    {"provider": "sqlite", "config": {}}

  OceanBase config example:
    {"provider": "oceanbase", "config": {
      "host": "127.0.0.1",
      "port": 2881,
      "user": "root@test",
      "password": "your_password",
      "db_name": "powermem",
      "collection_name": "memories",
      "embedding_model_dims": 1024
    }}
  Note:
    - collection_name: default table name; if the dimensions were created incorrectly, drop this table or change the name
    - embedding_model_dims: embedding vector dimensions, must match the embedder model dimensions
      For example, Zhipu: embedding-2 has 1024 dimensions, embedding-3 has 2048 dimensions

[Recommended configuration combinations]
1. Completely free option:
   - LLM: zhipu + glm-4-flash (free)
   - Embedder: Tongyi Qianwen text-embedding-v4
   - Database: sqlite

2. Production option:
   - LLM: qwen-plus or another commercial model
   - Embedder: text-embedding-v4
   - Database: oceanbase or seekdb
'
WHERE `id` = 'Memory_powermem';
-- ===== end 202602051017.sql =====

-- ===== begin 202602051125.sql =====
-- Drop the unused business table ai_voiceprint
DROP TABLE IF EXISTS ai_voiceprint;
-- ===== end 202602051125.sql =====

-- ===== begin 202602061650.sql =====
-- Normalize the language type data in ai_tts_voice (the Chinese language values below are matched data and are intentionally kept)
UPDATE ai_tts_voice
SET languages = CASE
    WHEN languages IN ('English', 'English','English','English','English','English','English','English','English','English','English','English','English') THEN 'English'
    WHEN languages IN ('English', 'English', 'English','English','English') THEN 'English'
    WHEN languages IN ('English', 'English', 'English', 'English', 'English') THEN 'English'
    WHEN languages = 'English' THEN 'English'
    WHEN languages = 'English' THEN 'English'
    WHEN languages = 'English' THEN 'English'
    WHEN languages IN ('English', 'English') THEN 'English'
    WHEN languages = 'English' THEN 'English'
    WHEN languages = 'English' THEN 'English'
    ELSE languages
END;

-- Add voice language, volume, speech rate and pitch fields to the ai_agent table
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent' AND COLUMN_NAME = 'tts_language');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_agent` ADD COLUMN `tts_language` VARCHAR(50) NULL COMMENT ''Voice language'' AFTER `tts_voice_id`', 'SELECT ''Column tts_language already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent' AND COLUMN_NAME = 'tts_volume');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_agent` ADD COLUMN `tts_volume` INT NULL COMMENT ''TTS volume'' AFTER `tts_language`', 'SELECT ''Column tts_volume already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent' AND COLUMN_NAME = 'tts_rate');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_agent` ADD COLUMN `tts_rate` INT NULL COMMENT ''TTS speech rate'' AFTER `tts_volume`', 'SELECT ''Column tts_rate already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent' AND COLUMN_NAME = 'tts_pitch');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_agent` ADD COLUMN `tts_pitch` INT NULL COMMENT ''TTS pitch'' AFTER `tts_rate`', 'SELECT ''Column tts_pitch already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Add voice language, volume, speech rate and pitch fields to the ai_agent_template table
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent_template' AND COLUMN_NAME = 'tts_language');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_agent_template` ADD COLUMN `tts_language` VARCHAR(50) NULL COMMENT ''Voice language'' AFTER `tts_voice_id`', 'SELECT ''Column tts_language already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent_template' AND COLUMN_NAME = 'tts_volume');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_agent_template` ADD COLUMN `tts_volume` INT NULL COMMENT ''TTS volume'' AFTER `tts_language`', 'SELECT ''Column tts_volume already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent_template' AND COLUMN_NAME = 'tts_rate');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_agent_template` ADD COLUMN `tts_rate` INT NULL COMMENT ''TTS speech rate'' AFTER `tts_volume`', 'SELECT ''Column tts_rate already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent_template' AND COLUMN_NAME = 'tts_pitch');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_agent_template` ADD COLUMN `tts_pitch` INT NULL COMMENT ''TTS pitch'' AFTER `tts_rate`', 'SELECT ''Column tts_pitch already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
-- ===== end 202602061650.sql =====

-- ===== begin 202602271137.sql =====
-- Update the Tencent TTS provider config, adding the speed, volume and format parameters
UPDATE `ai_model_provider`
SET fields = '[{"key":"appid","label":"App ID","type":"string"},{"key":"secret_id","label":"Secret ID","type":"string"},{"key":"secret_key","label":"Secret Key","type":"string"},{"key":"format","label":"Audio format","type":"string"},{"key":"speed","label":"Speech rate","type":"number"},{"key":"volume","label":"Volume","type":"number"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"voice","label":"Voice ID","type":"string"},{"key":"region","label":"Region","type":"string"}]'
WHERE id = 'SYSTEM_TTS_TencentTTS';

-- Update the Tencent TTS model config, adding the speed and volume parameters and parameter descriptions
UPDATE `ai_model_config` SET 
    `config_json` = JSON_SET(`config_json`, '$.speed', 0, '$.volume', 0),
    `remark` = 'Tencent TTS configuration notes:
1. You need to activate the intelligent speech interaction service on the Tencent Cloud platform
2. Multiple voices are supported; the current config uses 101001
3. Requires a network connection
4. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://console.cloud.tencent.com/cam/capi to get the keys
2. Visit https://console.cloud.tencent.com/tts/resourcebundle to claim free resources
3. Create a new application
4. Get the appid, secret_id and secret_key
5. Fill them into the configuration file
Audio parameters:
- format: audio format, supports pcm, wav, mp3
- speed: speech rate, range -2~6, default 0
- volume: volume, range -10~10, default 0'
WHERE `id` = 'TTS_TencentTTS';

-- Update the CozeCnTTS provider config, adding the speed and loudness_rate parameters
UPDATE `ai_model_provider`
SET fields = '[{"key":"voice","label":"Voice","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"speed","label":"Speech rate","type":"number"},{"key":"loudness_rate","label":"Volume gain","type":"number"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"response_format","label":"Response format","type":"string"}]'
WHERE id = 'SYSTEM_TTS_cozecn';

-- Update the CozeCnTTS model config, adding the speed and loudness_rate parameters and parameter descriptions
UPDATE `ai_model_config` SET 
    `config_json` = JSON_SET(`config_json`, '$.speed', 1, '$.loudness_rate', 0),
    `remark` = 'Coze Chinese speech synthesis configuration notes:
1. Visit https://www.coze.cn/ to register and log in
2. Create an application and get the access_token
3. Choose a suitable voice ID
Audio parameters:
- response_format: audio format, supports pcm, wav, mp3
- speed: speech rate, range 0.5~2, default 1
- loudness_rate: volume gain, range -50~100, default 0'
WHERE `id` = 'TTS_CozeCnTTS';
-- ===== end 202602271137.sql =====

-- ===== begin 202602281000.sql =====
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
-- ===== end 202602281000.sql =====

-- ===== begin 202603091051.sql =====
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
-- ===== end 202603091051.sql =====

-- ===== begin 202603101723.sql =====
-- Add a language field to the voice clone table
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_voice_clone' AND COLUMN_NAME = 'languages');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_voice_clone` ADD COLUMN `languages` VARCHAR(50) DEFAULT NULL COMMENT ''Language'' AFTER `voice_id`', 'SELECT ''Column languages already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
-- ===== end 202603101723.sql =====

-- ===== begin 202603111131.sql =====
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
-- ===== end 202603111131.sql =====

-- ===== begin 202603231037.sql =====
-- Add the report-chat-history-only memory model provider

delete from `ai_model_provider` where `id` = 'SYSTEM_Memory_mem_report_only';
delete from `ai_model_config` where `id` = 'Memory_mem_report_only';

INSERT INTO `ai_model_provider` VALUES ('SYSTEM_Memory_mem_report_only', 'Memory', 'mem_report_only', 'Report chat history only', '[]', 4, 1, NOW(), 1, NOW());
INSERT INTO `ai_model_config` VALUES ('Memory_mem_report_only', 'Memory', 'mem_report_only', 'Report chat history only', 0, 1, '{"type": "mem_report_only"}', NULL, 'Only reports chat history, does not summarize memory', 3, NULL, NULL, NULL, NULL);
-- ===== end 202603231037.sql =====

-- ===== begin 202603311200.sql =====
-- Change the chat content column type
ALTER TABLE ai_agent_chat_history MODIFY COLUMN content TEXT COMMENT 'Chat content';
-- ===== end 202603311200.sql =====

-- ===== begin 202604010930.sql =====
-- Rename the memory models

UPDATE `ai_model_config` SET `model_name` = 'Local short-term memory (summarized memory)' WHERE `id` = 'Memory_mem_local_short';
UPDATE `ai_model_provider` SET `name` = 'Local short-term memory (summarized memory)' WHERE `id` = 'SYSTEM_Memory_mem_local_short';

UPDATE `ai_model_config` SET `model_name` = 'Report chat history only (no memory summarization)' WHERE `id` = 'Memory_mem_report_only';
UPDATE `ai_model_provider` SET `name` = 'Report chat history only (no memory summarization)' WHERE `id` = 'SYSTEM_Memory_mem_report_only';
-- ===== end 202604010930.sql =====

-- ===== begin 202604011035.sql =====
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (312, 'tool_call_timeout', '30', 'number', 1, 'Tool call timeout (seconds)');
-- ===== end 202604011035.sql =====

-- ===== begin 202604011545.sql =====
-- Add the small model ID field to the agent table
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent' AND COLUMN_NAME = 'slm_model_id');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE `ai_agent` ADD COLUMN `slm_model_id` VARCHAR(255) NULL COMMENT ''Small model ID'' AFTER `llm_model_id`', 'SELECT ''Column slm_model_id already exists'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Create the chat title table
DROP TABLE IF EXISTS `ai_agent_chat_title`;
CREATE TABLE `ai_agent_chat_title` (
    `id` VARCHAR(32) NOT NULL COMMENT 'Primary key ID',
    `session_id` VARCHAR(255) NOT NULL COMMENT 'Session ID',
    `title` VARCHAR(255) DEFAULT NULL COMMENT 'Chat title',
    `created_at` DATETIME DEFAULT NULL COMMENT 'Creation time',
    `updated_at` DATETIME DEFAULT NULL COMMENT 'Update time',
    PRIMARY KEY (`id`),
    KEY `idx_session_id` (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Agent chat title table';
-- ===== end 202604011545.sql =====

-- ===== begin 202604161357.sql =====
-- Update the model name: change qwen2.5-vl-3b-instruct to qwen3.5-flash
UPDATE `ai_model_config` 
SET `config_json` = JSON_SET(`config_json`, '$.model_name', 'qwen3.5-flash')
WHERE `id` = 'VLLM_QwenVLVLLM' 
AND JSON_EXTRACT(`config_json`, '$.model_name') = 'qwen2.5-vl-3b-instruct';

-- Update the model name: change qwen-turbo to qwen-flash
UPDATE `ai_model_config` 
SET `config_json` = JSON_SET(`config_json`, '$.model_name', 'qwen-flash')
WHERE `id` = 'LLM_AliLLM' 
AND JSON_EXTRACT(`config_json`, '$.model_name') = 'qwen-turbo';

-- Update the remark: change qwen-turbo to qwen-flash
UPDATE `ai_model_config` 
SET `remark` = REPLACE(`remark`, 'qwen-turbo', 'qwen-flash')
WHERE `id` = 'LLM_AliLLM' 
AND `remark` LIKE '%qwen-turbo%';
-- ===== end 202604161357.sql =====

-- ===== begin 202604201719.sql =====
-- Add the Doubao speech synthesis model 2.0 provider (uses the seed-tts-2.0 resource ID)
-- Same config as Volcano dual-stream TTS, but resource_id is fixed to seed-tts-2.0

-- Insert the Doubao speech synthesis model 2.0 provider
delete from `ai_model_provider` where id = 'SYSTEM_TTS_HSDSTTS_V2';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_TTS_HSDSTTS_V2', 'TTS', 'huoshan_double_stream', 'Doubao speech synthesis model 2.0', '[
  {"key": "ws_url", "type": "string", "label": "WebSocket URL"},
  {"key": "appid", "type": "string", "label": "App ID"},
  {"key": "access_token", "type": "string", "label": "Access token"},
  {"key": "resource_id", "type": "string", "label": "Resource ID"},
  {"key": "speaker", "type": "string", "label": "Default voice"},
  {"key": "enable_ws_reuse", "type": "boolean", "label": "Enable connection reuse", "default": true},
  {"key": "audio_params", "type": "dict", "label": "Audio output config"},
  {"key": "additions", "type": "dict", "label": "Advanced text processing config"},
  {"key": "mix_speaker", "type": "dict", "label": "Mix control config"}
]', 14, 1, NOW(), 1, NOW());

-- Insert the Doubao speech synthesis model 2.0 config
delete from `ai_model_config` where id = 'TTS_HSDSTTS_V2';
INSERT INTO `ai_model_config` VALUES ('TTS_HSDSTTS_V2', 'TTS', 'HuoshanDoubleStreamTTSV2', 'Doubao speech synthesis model 2.0', 0, 1, '{
  "type": "huoshan_double_stream",
  "ws_url": "wss://openspeech.bytedance.com/api/v3/tts/bidirection",
  "appid": "",
  "access_token": "",
  "resource_id": "seed-tts-2.0",
  "speaker": "zh_female_xiaohe_uranus_bigtts",
  "enable_ws_reuse": true,
  "audio_params": {
    "speech_rate": 0,
    "loudness_rate": 0
  },
  "additions": {
    "aigc_metadata": {},
    "cache_config": {},
    "post_process": {
      "pitch": 0
    }
  },
  "mix_speaker": {}
}', NULL, NULL, 17, NULL, NULL, NULL, NULL);

-- Doubao speech synthesis model 2.0 configuration documentation
UPDATE `ai_model_config` SET
`doc_link` = 'https://www.volcengine.com/docs/6561/1329505',
`remark` = 'Doubao speech synthesis model 2.0 configuration notes (based on Volcano Engine seed-tts-2.0):
1. Visit https://www.volcengine.com/ to register and activate a Volcano Engine account
2. Visit https://console.volcengine.com/speech/service/10035 to activate the speech synthesis model and purchase voices
3. Get the appid and access_token at the bottom of the page
4. The resource ID is fixed as: seed-tts-2.0 (Doubao speech synthesis model 2.0)
5. Connection reuse: enables WebSocket connection reuse, default true to reduce connection overhead (note: after reuse, idle connections count toward concurrency while the device is in listening state)

Detailed parameter documentation: https://www.volcengine.com/docs/6561/1329505
[audio_params] Audio output config - users can add any audio parameter supported by Volcano Engine
  - speech_rate: speech rate (-50~100), default 0
  - loudness_rate: volume (-50~100), default 0
  Example: {"speech_rate": 10, "loudness_rate": 5}

[additions] Advanced text processing config - users can add any advanced parameter supported by Volcano Engine
  - post_process.pitch: pitch (-12~12), default 0
  - aigc_metadata: AIGC metadata config
  - cache_config: cache config
  Example: {"post_process": {"pitch": 2}, "aigc_metadata": {}, "cache_config": {}}

Note:
- Doubao speech synthesis model 2.0 uses the seed-tts-2.0 resource ID, which differs from Volcano dual-stream TTS (volc.service_type.10029)
- Related voice list: https://www.volcengine.com/docs/6561/1257544
- Users can add more parameters according to the Volcano Engine API documentation
' WHERE `id` = 'TTS_HSDSTTS_V2';

-- Add Doubao speech synthesis model 2.0 voices (same as the Volcano dual-stream TTS voices)
delete from `ai_tts_voice` where tts_model_id = 'TTS_HSDSTTS_V2';
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0001', 'TTS_HSDSTTS_V2', 'Vivi', 'zh_female_vv_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_vv_uranus_bigtts.wav', NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0002', 'TTS_HSDSTTS_V2', 'Xiaohe', 'zh_female_xiaohe_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_xiaohe_uranus_bigtts.mp3', NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0003', 'TTS_HSDSTTS_V2', 'Yunzhou', 'zh_male_m191_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_m191_uranus_bigtts.mp3', NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0004', 'TTS_HSDSTTS_V2', 'Xiaotian', 'zh_male_taocheng_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_taocheng_uranus_bigtts.mp3', NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0005', 'TTS_HSDSTTS_V2', 'Liu Fei', 'zh_male_liufei_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_liufei_uranus_bigtts.mp3', NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0006', 'TTS_HSDSTTS_V2', 'Charming Sophie', 'zh_female_sophie_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_sophie_uranus_bigtts.mp3', NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0007', 'TTS_HSDSTTS_V2', 'Fresh Female Voice', 'zh_female_qingxinnvsheng_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_qingxinnvsheng_uranus_bigtts.mp3', NULL, NULL, NULL, 7, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0008', 'TTS_HSDSTTS_V2', 'Intellectual Cancan', 'zh_female_cancan_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_cancan_uranus_bigtts.mp3', NULL, NULL, NULL, 8, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0009', 'TTS_HSDSTTS_V2', 'Coquettish Junior Girl', 'zh_female_sajiaoxuemei_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_sajiaoxuemei_uranus_bigtts.mp3', NULL, NULL, NULL, 9, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0010', 'TTS_HSDSTTS_V2', 'Sweet Xiaoyuan', 'zh_female_tianmeixiaoyuan_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_tianmeixiaoyuan_uranus_bigtts.mp3', NULL, NULL, NULL, 10, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0011', 'TTS_HSDSTTS_V2', 'Sweet Taozi', 'zh_female_tianmeitaozi_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_tianmeitaozi_uranus_bigtts.mp3', NULL, NULL, NULL, 11, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0012', 'TTS_HSDSTTS_V2', 'Cheerful Sisi', 'zh_female_shuangkuaisisi_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_shuangkuaisisi_uranus_bigtts.mp3', NULL, NULL, NULL, 12, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0013', 'TTS_HSDSTTS_V2', 'Peppa Pig', 'zh_female_peiqi_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_peiqi_uranus_bigtts.mp3', NULL, NULL, NULL, 13, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0014', 'TTS_HSDSTTS_V2', 'Girl Next Door', 'zh_female_linjianvhai_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_linjianvhai_uranus_bigtts.mp3', NULL, NULL, NULL, 14, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0015', 'TTS_HSDSTTS_V2', 'Young Zixin/Brayan', 'zh_male_shaonianzixin_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_shaonianzixin_uranus_bigtts.mp3', NULL, NULL, NULL, 15, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0016', 'TTS_HSDSTTS_V2', 'Monkey King', 'zh_male_sunwukong_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_sunwukong_uranus_bigtts.mp3', NULL, NULL, NULL, 16, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0017', 'TTS_HSDSTTS_V2', 'Charming Girlfriend', 'zh_female_meilinvyou_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_meilinvyou_uranus_bigtts.mp3', NULL, NULL, NULL, 17, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0018', 'TTS_HSDSTTS_V2', 'Tim', 'en_male_tim_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/en_male_tim_uranus_bigtts.mp3', NULL, NULL, NULL, 18, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0019', 'TTS_HSDSTTS_V2', 'Dacey', 'en_female_dacey_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/en_female_dacey_uranus_bigtts.mp3', NULL, NULL, NULL, 19, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0020', 'TTS_HSDSTTS_V2', 'Stokie', 'en_female_stokie_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/en_female_stokie_uranus_bigtts.mp3', NULL, NULL, NULL, 20, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0021', 'TTS_HSDSTTS_V2', 'Warm Ahu/Alvin', 'zh_male_wennuanahu_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_wennuanahu_uranus_bigtts.mp3', NULL, NULL, NULL, 21, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0022', 'TTS_HSDSTTS_V2', 'Baby-voiced Cutie', 'zh_male_naiqimengwa_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_naiqimengwa_uranus_bigtts.mp3', NULL, NULL, NULL, 22, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0023', 'TTS_HSDSTTS_V2', 'Grandma', 'zh_female_popo_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_popo_uranus_bigtts.mp3', NULL, NULL, NULL, 23, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0024', 'TTS_HSDSTTS_V2', 'Cheerful Big Sister', 'zh_female_kailangjiejie_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_kailangjiejie_uranus_bigtts.mp3', NULL, NULL, NULL, 24, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0025', 'TTS_HSDSTTS_V2', 'Lively Duoduo', 'saturn_zh_female_qingyingduoduo_cs_tob', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/ICL_zh_female_qingyingduoduo_cs_tob.mp3', NULL, NULL, NULL, 25, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0026', 'TTS_HSDSTTS_V2', 'Gentle Shanshan', 'saturn_zh_female_wenwanshanshan_cs_tob', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/ICL_zh_female_wenwanshanshan_cs_tob.mp3', NULL, NULL, NULL, 26, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0027', 'TTS_HSDSTTS_V2', 'Domineering Uncle Qing', 'zh_male_baqiqingshu_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_baqiqingshu_uranus_bigtts.mp3', NULL, NULL, NULL, 27, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0028', 'TTS_HSDSTTS_V2', 'Mystery Narrator', 'zh_male_xuanyijieshuo_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_xuanyijieshuo_uranus_bigtts.mp3', NULL, NULL, NULL, 28, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0029', 'TTS_HSDSTTS_V2', 'Ancient-style Shaoyu', 'zh_female_gufengshaoyu_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_gufengshaoyu_uranus_bigtts.mp3', NULL, NULL, NULL, 29, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0030', 'TTS_HSDSTTS_V2', 'Tang Monk', 'zh_male_tangseng_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_tangseng_uranus_bigtts.mp3', NULL, NULL, NULL, 30, NULL, NULL, NULL, NULL);
-- ===== end 202604201719.sql =====

-- ===== begin 202604211515.sql =====
-- Agent replacement word file table
CREATE TABLE IF NOT EXISTS `ai_agent_correct_word_file` (
    `id`          VARCHAR(32)  NOT NULL,
    `file_name`   VARCHAR(256) NOT NULL COMMENT 'Original file name',
    `word_count`  INT          NOT NULL DEFAULT 0 COMMENT 'Replacement word count',
    `content`     TEXT         COMMENT 'Original file content',
    `creator`     BIGINT       DEFAULT NULL,
    `created_at`  DATETIME     DEFAULT CURRENT_TIMESTAMP,
    `updater`     BIGINT       DEFAULT NULL,
    `updated_at`  DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_creator` (`creator`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Replacement word file';

-- Replacement word entry table
CREATE TABLE IF NOT EXISTS `ai_agent_correct_word_item` (
    `id`          VARCHAR(32)  NOT NULL,
    `file_id`     VARCHAR(32)  NOT NULL COMMENT 'Owning file ID',
    `source_word` VARCHAR(128) NOT NULL COMMENT 'Source word',
    `target_word` VARCHAR(128) NOT NULL COMMENT 'Replacement word',
    PRIMARY KEY (`id`),
    INDEX `idx_file_id` (`file_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Replacement word entry';

-- Agent replacement word file relation table
CREATE TABLE IF NOT EXISTS `ai_agent_correct_word_mapping` (
    `id`          VARCHAR(32)  NOT NULL,
    `agent_id`    VARCHAR(32)  NOT NULL,
    `file_id`     VARCHAR(32)  NOT NULL,
    `creator`     BIGINT       DEFAULT NULL,
    `created_at`  DATETIME     DEFAULT CURRENT_TIMESTAMP,
    `updater`     BIGINT       DEFAULT NULL,
    `updated_at`  DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `uk_agent_file` (`agent_id`, `file_id`),
    INDEX `idx_agent_id` (`agent_id`),
    INDEX `idx_file_id` (`file_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Agent replacement word file relation';
-- ===== end 202604211515.sql =====

-- ===== begin 202604211700.sql =====
-- Fix the duplicate provider_code of Doubao speech synthesis model 2.0 and add ASR 2.0 support

-- ==================== Doubao speech synthesis model 2.0 ====================
-- Delete the TTS 2.0 provider (a separate provider is no longer needed)
delete from `ai_model_provider` where id = 'SYSTEM_TTS_HSDSTTS_V2';

-- ==================== Doubao speech recognition (streaming) ====================
-- Fix the existing Doubao speech recognition (streaming) provider: remove the cluster field and add the resource_id field
UPDATE `ai_model_provider` SET `fields` = '[{"key":"appid","type":"string","label":"App ID"},{"key":"access_token","type":"string","label":"Access token"},{"key":"boosting_table_name","type":"string","label":"Hotword file name"},{"key":"correct_table_name","type":"string","label":"Replacement word file name"},{"key":"output_dir","type":"string","label":"Output directory"},{"key":"end_window_size","type":"number","label":"Silence detection duration (ms)"},{"key":"enable_multilingual","type":"boolean","label":"Enable multilingual recognition mode"},{"key":"language","type":"string","label":"Specified language code"},{"key":"resource_id","type":"string","label":"Resource ID"}]' WHERE `id` = 'SYSTEM_ASR_DoubaoStreamASR';

-- Fix the existing Doubao speech recognition (streaming) config: remove the cluster field and add the resource_id default value
UPDATE `ai_model_config` SET `config_json` = JSON_REMOVE(JSON_SET(`config_json`, '$.resource_id', 'volc.bigasr.sauc.duration'), '$.cluster') WHERE `id` = 'ASR_DoubaoStreamASR';

-- ==================== Doubao speech recognition model 2.0 ====================

-- Insert the Doubao speech recognition model 2.0 config
delete from `ai_model_config` where id = 'ASR_DoubaoStreamASRV2';
INSERT INTO `ai_model_config` VALUES ('ASR_DoubaoStreamASRV2', 'ASR', 'DoubaoStreamASRV2', 'Doubao speech recognition model 2.0', 0, 1, '{
  "type": "doubao_stream",
  "appid": "",
  "access_token": "",
  "resource_id": "volc.seedasr.sauc.duration",
  "end_window_size": 200,
  "enable_multilingual": false,
  "language": "zh-CN",
  "output_dir": "tmp/"
}', NULL, NULL, 6, NULL, NULL, NULL, NULL);

-- Doubao speech recognition model 2.0 configuration documentation
UPDATE `ai_model_config` SET
`doc_link` = 'https://www.volcengine.com/docs/6561/109979',
`remark` = 'Doubao speech recognition model 2.0 configuration notes (based on Volcano Engine seed-asr):
1. Visit https://www.volcengine.com/ to register and activate a Volcano Engine account
2. Visit https://console.volcengine.com/speech/service/10038 to activate Doubao streaming speech recognition model 2.0
3. Get the appid and access_token at the bottom of the page
4. There are two kinds of resource IDs: the hourly edition (volc.seedasr.sauc.duration) and the concurrency edition (volc.seedasr.sauc.concurrent)
   - Hourly edition: fixed as: volc.seedasr.sauc.duration (Doubao speech recognition model 2.0)
   - Concurrency edition: fixed as: volc.seedasr.sauc.concurrent (Doubao speech recognition model 2.0)

Detailed parameter documentation: https://www.volcengine.com/docs/6561/109979

Note:
- Doubao speech recognition model 2.0 uses the volc.seedasr.sauc.duration resource ID, which differs from Doubao speech recognition (streaming) (volc.bigasr.sauc.duration)
- Speech recognition model 2.0 is cheaper; the concurrency edition resource ID is recommended for high-concurrency scenarios
' WHERE `id` = 'ASR_DoubaoStreamASRV2';
-- ===== end 202604211700.sql =====

-- ===== begin 202604300930.sql =====
-- Rename models
UPDATE `ai_model_config` SET `model_name` = 'Doubao speech recognition 2.0 (streaming)' WHERE `id` = 'ASR_DoubaoStreamASRV2';

UPDATE `ai_model_config` SET `model_name` = 'Doubao speech synthesis 2.0 (streaming)' WHERE `id` = 'TTS_HSDSTTS_V2';

-- Adjust the model voices
delete from `ai_tts_voice` where tts_model_id = 'TTS_HSDSTTS_V2';

-- General scenarios and video dubbing
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0001', 'TTS_HSDSTTS_V2', 'Taiwanese Xiaohe', 'zh_female_xiaohe_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_xiaohe_uranus_bigtts.mp3', NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0002', 'TTS_HSDSTTS_V2', 'Vivi', 'zh_female_vv_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_vv_uranus_bigtts.wav', NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0003', 'TTS_HSDSTTS_V2', 'Cute Girl', 'saturn_zh_female_keainvsheng_tob', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/saturn_zh_female_keainvsheng_tob.wav', NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0004', 'TTS_HSDSTTS_V2', 'Playful Princess', 'saturn_zh_female_tiaopigongzhu_tob', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/saturn_zh_female_tiaopigongzhu_tob.wav', NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0005', 'TTS_HSDSTTS_V2', 'Sunny Young Man', 'zh_male_yangguangqingnian_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_yangguangqingnian_uranus_bigtts.mp3', NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0006', 'TTS_HSDSTTS_V2', 'Outgoing Young Man', 'saturn_zh_male_shuanglangshaonian_tob', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/saturn_zh_male_shuanglangshaonian_tob.wav', NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0007', 'TTS_HSDSTTS_V2', 'Outgoing Young Man', 'saturn_zh_male_tiancaitongzhuo_tob', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/saturn_zh_male_tiancaitongzhuo_tob.wav', NULL, NULL, NULL, 7, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0008', 'TTS_HSDSTTS_V2', 'Dayi', 'zh_male_dayi_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_dayi_saturn_bigtts.wav', NULL, NULL, NULL, 8, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0009', 'TTS_HSDSTTS_V2', 'Black Cat Detective Mizai', 'zh_female_mizai_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_mizai_saturn_bigtts.wav', NULL, NULL, NULL, 9, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0010', 'TTS_HSDSTTS_V2', 'Motivational Woman', 'zh_female_jitangnv_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_jitangnv_saturn_bigtts.wav', NULL, NULL, NULL, 10, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0011', 'TTS_HSDSTTS_V2', 'Charming Girlfriend', 'zh_female_meilinvyou_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_meilinvyou_saturn_bigtts.wav', NULL, NULL, NULL, 11, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0012', 'TTS_HSDSTTS_V2', 'Smooth Female Voice', 'zh_female_liuchangnv_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/%E6%B5%81%E7%95%85%E5%A5%B3%E5%A3%B0.wav', NULL, NULL, NULL, 12, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0013', 'TTS_HSDSTTS_V2', 'Refined Yichen', 'zh_male_ruyayichen_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_ruyayichen_saturn_bigtts.wav', NULL, NULL, NULL, 13, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0014', 'TTS_HSDSTTS_V2', 'Yunzhou', 'zh_male_m191_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_m191_uranus_bigtts.mp3', NULL, NULL, NULL, 14, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0015', 'TTS_HSDSTTS_V2', 'Xiaotian', 'zh_male_taocheng_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_taocheng_uranus_bigtts.mp3', NULL, NULL, NULL, 15, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0016', 'TTS_HSDSTTS_V2', 'Liu Fei', 'zh_male_liufei_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_liufei_uranus_bigtts.mp3', NULL, NULL, NULL, 16, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0017', 'TTS_HSDSTTS_V2', 'Charming Sophie', 'zh_female_sophie_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_sophie_uranus_bigtts.mp3', NULL, NULL, NULL, 17, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0018', 'TTS_HSDSTTS_V2', 'Fresh Female Voice', 'zh_female_qingxinnvsheng_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_qingxinnvsheng_uranus_bigtts.mp3', NULL, NULL, NULL, 18, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0019', 'TTS_HSDSTTS_V2', 'Intellectual Cancan', 'zh_female_cancan_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_cancan_uranus_bigtts.mp3', NULL, NULL, NULL, 19, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0020', 'TTS_HSDSTTS_V2', 'Coquettish Junior Girl', 'zh_female_sajiaoxuemei_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_sajiaoxuemei_uranus_bigtts.mp3', NULL, NULL, NULL, 20, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0021', 'TTS_HSDSTTS_V2', 'Sweet Xiaoyuan', 'zh_female_tianmeixiaoyuan_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_tianmeixiaoyuan_uranus_bigtts.mp3', NULL, NULL, NULL, 21, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0022', 'TTS_HSDSTTS_V2', 'Sweet Taozi', 'zh_female_tianmeitaozi_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_tianmeitaozi_uranus_bigtts.mp3', NULL, NULL, NULL, 22, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0023', 'TTS_HSDSTTS_V2', 'Girl Next Door', 'zh_female_linjianvhai_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_linjianvhai_uranus_bigtts.mp3', NULL, NULL, NULL, 23, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0024', 'TTS_HSDSTTS_V2', 'Cheerful Sisi', 'zh_female_shuangkuaisisi_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_shuangkuaisisi_uranus_bigtts.mp3', NULL, NULL, NULL, 24, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0025', 'TTS_HSDSTTS_V2', 'Young Zixin/Brayan', 'zh_male_shaonianzixin_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_shaonianzixin_uranus_bigtts.mp3', NULL, NULL, NULL, 25, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0026', 'TTS_HSDSTTS_V2', 'Warm Ahu/Alvin', 'zh_male_wennuanahu_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_wennuanahu_uranus_bigtts.mp3', NULL, NULL, NULL, 26, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0027', 'TTS_HSDSTTS_V2', 'Baby-voiced Cutie', 'zh_male_naiqimengwa_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_naiqimengwa_uranus_bigtts.mp3', NULL, NULL, NULL, 27, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0028', 'TTS_HSDSTTS_V2', 'Grandma', 'zh_female_popo_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_popo_uranus_bigtts.mp3', NULL, NULL, NULL, 28, NULL, NULL, NULL, NULL);

-- Customer service scenarios
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0029', 'TTS_HSDSTTS_V2', 'Lively Duoduo', 'saturn_zh_female_qingyingduoduo_cs_tob', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/ICL_zh_female_qingyingduoduo_cs_tob.mp3', NULL, NULL, NULL, 29, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0030', 'TTS_HSDSTTS_V2', 'Gentle Shanshan', 'saturn_zh_female_wenwanshanshan_cs_tob', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/ICL_zh_female_wenwanshanshan_cs_tob.mp3', NULL, NULL, NULL, 30, NULL, NULL, NULL, NULL);

-- Multilingual
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0031', 'TTS_HSDSTTS_V2', 'Tim', 'en_male_tim_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/en_male_tim_uranus_bigtts.mp3', NULL, NULL, NULL, 31, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0032', 'TTS_HSDSTTS_V2', 'Dacey', 'en_female_dacey_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/en_female_dacey_uranus_bigtts.mp3', NULL, NULL, NULL, 32, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0033', 'TTS_HSDSTTS_V2', 'Stokie', 'en_female_stokie_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/en_female_stokie_uranus_bigtts.mp3', NULL, NULL, NULL, 33, NULL, NULL, NULL, NULL);

-- Audiobook reading
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0034', 'TTS_HSDSTTS_V2', 'Ancient-style Shaoyu', 'zh_female_gufengshaoyu_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_gufengshaoyu_uranus_bigtts.mp3', NULL, NULL, NULL, 34, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0035', 'TTS_HSDSTTS_V2', 'Domineering Uncle Qing', 'zh_male_baqiqingshu_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_baqiqingshu_uranus_bigtts.mp3', NULL, NULL, NULL, 35, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0036', 'TTS_HSDSTTS_V2', 'Mystery Narrator', 'zh_male_xuanyijieshuo_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_xuanyijieshuo_uranus_bigtts.mp3', NULL, NULL, NULL, 36, NULL, NULL, NULL, NULL);

-- Role playing
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0037', 'TTS_HSDSTTS_V2', 'Peppa Pig', 'zh_female_peiqi_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_female_peiqi_uranus_bigtts.mp3', NULL, NULL, NULL, 37, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0038', 'TTS_HSDSTTS_V2', 'Monkey King', 'zh_male_sunwukong_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_sunwukong_uranus_bigtts.mp3', NULL, NULL, NULL, 38, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0039', 'TTS_HSDSTTS_V2', 'Zhu Bajie', 'zh_male_zhubajie_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_zhubajie_uranus_bigtts.mp3', NULL, NULL, NULL, 39, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_HSDSTTS_V2_0040', 'TTS_HSDSTTS_V2', 'Tang Monk', 'zh_male_tangseng_uranus_bigtts', 'English', 'https://lf3-static.bytednsdoc.com/obj/eden-cn/lm_hz_ihsph/ljhwZthlaukjlkulzlp/portal/bigtts/zh_male_tangseng_uranus_bigtts.mp3', NULL, NULL, NULL, 40, NULL, NULL, NULL, NULL);
-- ===== end 202604300930.sql =====

-- ===== begin 202605071037.sql =====
-- Delete the provider whose provider_code is ttson
DELETE FROM `ai_model_provider` WHERE `provider_code` = 'ttson';

-- Delete the config whose model_code is ACGNTTS
DELETE FROM `ai_model_config` WHERE `model_code` = 'ACGNTTS';
-- ===== end 202605071037.sql =====

-- ===== begin 202605071120.sql =====
-- Delete the config whose model_code is GizwitsTTS
DELETE FROM `ai_model_config` WHERE `model_code` = 'GizwitsTTS';

-- Delete the associated TTS voice records
DELETE FROM `ai_tts_voice` WHERE `tts_model_id` = 'TTS_GizwitsTTS';
DELETE FROM `ai_tts_voice` WHERE `tts_model_id` = 'TTS_ACGNTTS';
-- ===== end 202605071120.sql =====

-- ===== begin 202605081008.sql =====
-- Delete the provider config whose provider_code is linkerai
DELETE FROM `ai_model_provider` WHERE `provider_code` = 'linkerai';

-- Delete the model config whose model_code is LinkeraiTTS
DELETE FROM `ai_model_config` WHERE `model_code` = 'LinkeraiTTS';

-- Delete the TTS voice records associated with LinkeraiTTS
DELETE FROM `ai_tts_voice` WHERE `tts_model_id` = 'TTS_LinkeraiTTS';
-- ===== end 202605081008.sql =====

-- ===== begin 202605121509.sql =====
-- Add the web search tool config fields
SET @data_exists = (SELECT COUNT(*) FROM ai_model_provider WHERE id = 'SYSTEM_PLUGIN_WEB_SEARCH');
SET @sql = IF(@data_exists = 0,
    'INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES (''SYSTEM_PLUGIN_WEB_SEARCH'', ''Plugin'', ''web_search'', ''Web search'', ''[{\"key\": \"provider\", \"type\": \"string\", \"label\": \"Search source: metaso / tavily\", \"default\": \"metaso\", \"editing\": false, \"selected\": false}, {\"key\": \"description\", \"type\": \"string\", \"label\": \"Tool description\", \"default\": \"Web search tool. Use this tool when the user explicitly needs to search the web for a question.\", \"editing\": false, \"selected\": false}, {\"key\": \"max_results\", \"type\": \"string\", \"label\": \"Result count\", \"default\": \"5\", \"editing\": false, \"selected\": false}, {\"key\": \"api_key\", \"type\": \"string\", \"label\": \"apiKey\", \"default\": \"mk-XXXX\", \"editing\": false, \"selected\": false}]'', 80, 1988490863118454785, ''2026-05-11 17:15:35'', 1988490863118454785, ''2026-05-12 10:55:49'')',
    'SELECT ''data already exists, skip'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
-- ===== end 202605121509.sql =====

-- ===== begin 202605251426.sql =====
-- Add the call-device tool config                                                                                                                            
SET @data_exists = (SELECT COUNT(*) FROM ai_model_provider WHERE id = 'SYSTEM_PLUGIN_CALL_DEVICE');                                                   
SET @sql = IF(@data_exists = 0,
    'INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`,
`update_date`) VALUES (''SYSTEM_PLUGIN_CALL_DEVICE'', ''Plugin'', ''call_device'', ''Device calls device'', ''[]'', 85, 1988490863118454785, ''2026-05-18     
12:00:00'', 1988490863118454785, ''2026-05-18 12:00:00'')',
    'SELECT ''data already exists, skip'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Update the system menu config, adding the contact management menu
UPDATE sys_params
SET param_value = CAST(
    JSON_SET(
        CAST(param_value AS JSON),
        '$.addressBook',
        JSON_OBJECT(
            'name', 'feature.addressBook.name',
            'enabled', FALSE,
            'description', 'feature.addressBook.description'
        )
    ) AS CHAR
)
WHERE param_code = 'system-web.menu'
  AND NOT JSON_CONTAINS_PATH(CAST(param_value AS JSON), 'one', '$.addressBook');

-- Create the device contact table
CREATE TABLE IF NOT EXISTS `ai_device_address_book` (
    `mac_address` VARCHAR(64) NOT NULL COMMENT 'This device MAC address',
    `target_mac` VARCHAR(64) NOT NULL COMMENT 'Peer device MAC address',
    `alias` VARCHAR(64) DEFAULT NULL COMMENT 'Alias',
    `has_permission` TINYINT(1) DEFAULT TRUE COMMENT 'Whether calling is permitted',
    `creator` BIGINT DEFAULT NULL COMMENT 'Creator',
    `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updater` BIGINT DEFAULT NULL COMMENT 'Updater',
    `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    PRIMARY KEY (`mac_address`, `target_mac`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Device contact table';
-- ===== end 202605251426.sql =====

-- ===== begin 202606231030.sql =====
-- Update the EdgeTTS provider, adding speech rate, pitch and volume config
UPDATE `ai_model_provider`
SET fields = '[{"key":"voice","label":"Voice","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"rate","label":"Speech rate (-100~100)","type":"number"},{"key":"volume","label":"Volume (0~100)","type":"number"},{"key":"pitch","label":"Pitch (-100~100)","type":"number"}]'
WHERE id = 'SYSTEM_TTS_edge';

UPDATE `ai_model_config` SET
`remark` = 'EdgeTTS configuration notes:
1. Uses the Microsoft Edge TTS service
2. Supports multiple languages and voices
3. Free to use, no registration required
4. Requires a network connection
5. Output files are saved in the tmp/ directory
6. Speech rate: -100~100, 0 is the normal speed
7. Volume: 0~100, 50 is the normal volume
8. Pitch: -100~100, 0 is the normal pitch' WHERE `id` = 'TTS_EdgeTTS';
-- ===== end 202606231030.sql =====

-- ===== begin 202606261131.sql =====
-- Fix and add Minimax streaming TTS voices
delete from `ai_tts_voice` where tts_model_id = 'TTS_MinimaxStreamTTS';

INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0001', 'TTS_MinimaxStreamTTS', 'Girl Voice', 'female-shaonv', 'English', NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0002', 'TTS_MinimaxStreamTTS', 'Mature Female Voice', 'female-chengshu', 'English', NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0003', 'TTS_MinimaxStreamTTS', 'Domineering Young Master', 'badao_shaoye', 'English', NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0004', 'TTS_MinimaxStreamTTS', 'Yandere Younger Brother', 'bingjiao_didi', 'English', NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0005', 'TTS_MinimaxStreamTTS', 'Innocent Junior Boy', 'chunzhen_xuedi', 'English', NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0006', 'TTS_MinimaxStreamTTS', 'Aloof Senior Boy', 'lengdan_xiongzhang', 'English', NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0007', 'TTS_MinimaxStreamTTS', 'Sweet Xiaoling', 'tianxin_xiaoling', 'English', NULL, NULL, NULL, NULL, 7, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0008', 'TTS_MinimaxStreamTTS', 'Playful Cutie', 'qiaopi_mengmei', 'English', NULL, NULL, NULL, NULL, 8, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0009', 'TTS_MinimaxStreamTTS', 'Charming Mature Woman', 'wumei_yujie', 'English', NULL, NULL, NULL, NULL, 9, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0010', 'TTS_MinimaxStreamTTS', 'Teasing Junior Girl', 'diadia_xuemei', 'English', NULL, NULL, NULL, NULL, 10, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0011', 'TTS_MinimaxStreamTTS', 'Elegant Senior Girl', 'danya_xuejie', 'English', NULL, NULL, NULL, NULL, 11, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0012', 'TTS_MinimaxStreamTTS', 'Santa Claus', 'Santa_Claus', 'English', NULL, NULL, NULL, NULL, 12, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0013', 'TTS_MinimaxStreamTTS', 'Grinch', 'Grinch', 'English', NULL, NULL, NULL, NULL, 13, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0014', 'TTS_MinimaxStreamTTS', 'Professional Female Host', 'Cantonese_ProfessionalHost（F)', 'English', "https://filecdn.minimax.chat/public/84589766-c651-477b-b320-36b89599f953.mp3", NULL, NULL, NULL, 14, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0015', 'TTS_MinimaxStreamTTS', 'Gentle Female Voice', 'Cantonese_GentleLady', 'English', "https://filecdn.minimax.chat/public/d391936d-d586-4dab-886c-a2a084a20920.mp3", NULL, NULL, NULL, 15, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0016', 'TTS_MinimaxStreamTTS', 'Professional Male Host', 'Cantonese_ProfessionalHost（M)', 'English', NULL, NULL, NULL, NULL, 16, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0017', 'TTS_MinimaxStreamTTS', 'Lively Male Voice', 'Cantonese_PlayfulMan', 'English', NULL, NULL, NULL, NULL, 17, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0018', 'TTS_MinimaxStreamTTS', 'Cute Girl', 'Cantonese_CuteGirl', 'English', "https://filecdn.minimax.chat/public/ff96520a-ac12-491d-945e-d6337467eb7d.mp3", NULL, NULL, NULL, 18, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0019', 'TTS_MinimaxStreamTTS', 'Kind Female Voice', 'Cantonese_KindWoman', 'English', "https://filecdn.minimax.chat/public/78239a18-5e9c-4538-94f6-2f504c080374.mp3", NULL, NULL, NULL, 19, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0020', 'TTS_MinimaxStreamTTS', 'Crisp News Anchor', 'Cantonese_crisp_news_anchor_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/741a5a4b-f42a-4a9b-ae83-3954d097ab73.mp3', NULL, NULL, NULL, 20, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0021', 'TTS_MinimaxStreamTTS', 'Pro Reporter', 'Cantonese_professional_reporter_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/77afb86d-2cc4-4149-8c2e-e1174fa849d4.mp3', NULL, NULL, NULL, 21, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0022', 'TTS_MinimaxStreamTTS', 'Crisp Reporter', 'Cantonese_crisp_reporter_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/4ad39a61-628e-481c-9d60-bfb7c36bceb8.mp3', NULL, NULL, NULL, 22, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0023', 'TTS_MinimaxStreamTTS', 'Articulate', 'Cantonese_Articulate_commentator_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/9346601d-3035-4f9e-9b1c-0e03f30e5eef.mp3', NULL, NULL, NULL, 23, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0024', 'TTS_MinimaxStreamTTS', 'Warm Reporter', 'Cantonese_Warm_Reporter_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/c651050e-d6a5-4653-b09e-5177bdc8b04c.mp3', NULL, NULL, NULL, 24, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0025', 'TTS_MinimaxStreamTTS', 'Energetic', 'Cantonese_energetic_commentator_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/1fd1c461-71da-450d-91bb-45f819249b44.mp3', NULL, NULL, NULL, 25, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0026', 'TTS_MinimaxStreamTTS', 'Objective Narrator', 'Cantonese_objective_narrator_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/463c5a68-a7b5-4fe9-85b6-d494dca74abb.mp3', NULL, NULL, NULL, 26, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0027', 'TTS_MinimaxStreamTTS', 'Husky Male Voice', 'Cantonese_Narrator', 'English', 'https://filecdn.minimax.chat/public/22e29cb0-0f5a-443a-9fa9-a32dabd55cf9.mp3', NULL, NULL, NULL, 27, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0028', 'TTS_MinimaxStreamTTS', 'News Anchor', 'Cantonese_news_anchor_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/59b9ba49-47d4-48f1-b207-09c0e0769a1b.mp3', NULL, NULL, NULL, 28, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0029', 'TTS_MinimaxStreamTTS', 'Learned Scholar', 'Cantonese_WiselProfessor', 'English', 'https://filecdn.minimax.chat/public/8de234c4-64a7-4539-a316-c3b43ee1d0a9.mp3', NULL, NULL, NULL, 29, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0030', 'TTS_MinimaxStreamTTS', 'Resonant Host', 'Cantonese_resonant_host_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/ec8fc0ce-6657-4c49-9bf0-3953a15046ec.mp3', NULL, NULL, NULL, 30, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0031', 'TTS_MinimaxStreamTTS', 'Indifferent Staff', 'Cantonese_IndifferentStaff', 'English', 'https://filecdn.minimax.chat/public/9686682c-3fc8-45f0-bd88-2a4692e1f63e.mp3', NULL, NULL, NULL, 31, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0032', 'TTS_MinimaxStreamTTS', 'Male News Anchor', 'Cantonese_Male_news_anchor_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/2055ee8b-fb25-424c-b8cb-e2baf971e520.mp3', NULL, NULL, NULL, 32, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0033', 'TTS_MinimaxStreamTTS', 'History Narrator', 'Cantonese_casual_narrator_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/c170f9e4-145d-4331-9910-1c3a0e6bbc3a.mp3', NULL, NULL, NULL, 33, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0034', 'TTS_MinimaxStreamTTS', 'Steady Reporter', 'Cantonese_Steady_reporter_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/381cfee2-772d-4a73-b30c-7914aec05771.mp3', NULL, NULL, NULL, 34, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0035', 'TTS_MinimaxStreamTTS', 'Serious Commentator', 'Cantonese_serious_commentator_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/57335c8a-32ea-475f-a198-b0de7fa1b126.mp3', NULL, NULL, NULL, 35, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0036', 'TTS_MinimaxStreamTTS', 'Podcast Host', 'Cantonese_podcast_host_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/048b617f-e1f8-422c-89fb-fdbc6e303675.mp3', NULL, NULL, NULL, 36, NULL, NULL, NULL, NULL);
INSERT INTO `ai_tts_voice` VALUES ('TTS_MinimaxStreamTTS_0037', 'TTS_MinimaxStreamTTS', 'Obj commentator', 'Cantonese_Objective_commentator_vv2', 'English', 'https://cdn.hailuoai.video/open-hailuo-video-web/public_assets/a8f55e44-b726-4ba5-815a-f1b515ba57ef.mp3', NULL, NULL, NULL, 37, NULL, NULL, NULL, NULL);
-- ===== end 202606261131.sql =====

-- ===== begin 202607011405.sql =====
-- Add language configuration for local FunASR ASR.
UPDATE `ai_model_provider`
SET `fields` = '[{"key":"model_dir","label":"Model directory","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"language","label":"Recognition language","type":"string","default":"auto"}]'
WHERE `id` = 'SYSTEM_ASR_FunASR';

UPDATE `ai_model_config`
SET `config_json` = JSON_SET(`config_json`, '$.language', 'auto')
WHERE `id` = 'ASR_FunASR'
AND JSON_EXTRACT(`config_json`, '$.language') IS NULL;

-- Update the FunASR local model configuration description to mention the language option.
UPDATE `ai_model_config`
SET `remark` = 'FunASR local model configuration notes:
1. You need to download the model files into the xiaozhi-server/models/SenseVoiceSmall directory
2. Supports Chinese, Japanese, Korean and Cantonese speech recognition
3. Local inference, no network connection required
4. Files to be recognized are saved in the tmp/ directory
5. The "Recognition language" field controls the recognition language: auto = automatic detection; to recognize Chinese only, set it to zh (en = English, ja = Japanese, ko = Korean, yue = Cantonese).'
WHERE `id` = 'ASR_FunASR';
-- ===== end 202607011405.sql =====

-- ===== begin 202607071530.sql =====

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
-- ===== end 202607071530.sql =====

-- ===== begin 202607101200.sql =====

ALTER TABLE `ai_agent_snapshot`
    ADD COLUMN `redaction_version` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Snapshot redaction rule version' AFTER `created_at`,
    ADD INDEX `idx_snapshot_redaction_version_id` (`redaction_version`, `id`);

-- rollback ALTER TABLE `ai_agent_snapshot` DROP INDEX `idx_snapshot_redaction_version_id`, DROP COLUMN `redaction_version`;
-- ===== end 202607101200.sql =====

-- ===== begin 202607290930.sql =====

-- Insert the new hass_state plugin record (merging the config fields of get_state)
INSERT INTO ai_model_provider (id, model_type, provider_code, name, fields,
                               sort, creator, create_date, updater, update_date)
VALUES ('SYSTEM_PLUGIN_HA_STATE',
        'Plugin',
        'hass_state',
        'HomeAssistant device control',
        JSON_ARRAY(
                JSON_OBJECT(
                        'key', 'base_url',
                        'type', 'string',
                        'label', 'HA server URL',
                        'default',
                        (SELECT param_value FROM sys_params WHERE param_code = 'plugins.home_assistant.base_url')
                ),
                JSON_OBJECT(
                        'key', 'api_key',
                        'type', 'string',
                        'label', 'HA API access token',
                        'default',
                        (SELECT param_value FROM sys_params WHERE param_code = 'plugins.home_assistant.api_key')
                ),
                JSON_OBJECT(
                        'key', 'devices',
                        'type', 'array',
                        'label', 'Device list (name,entity ID;...)',
                        'default',
                        (SELECT param_value FROM sys_params WHERE param_code = 'plugins.home_assistant.devices')
                )
        ),
        50, 0, NOW(), 0, NOW());

-- Migrate configured agents: change those pointing to HA_GET_STATE to HA_STATE (keeping the parameters)
UPDATE ai_agent_plugin_mapping
SET plugin_id = 'SYSTEM_PLUGIN_HA_STATE'
WHERE plugin_id = 'SYSTEM_PLUGIN_HA_GET_STATE';

-- HA_SET_STATE has no config fields to begin with (fields=[]), so delete its mapping directly
DELETE FROM ai_agent_plugin_mapping
WHERE plugin_id = 'SYSTEM_PLUGIN_HA_SET_STATE';

-- Delete the old plugin definitions
DELETE FROM ai_model_provider
WHERE id IN ('SYSTEM_PLUGIN_HA_GET_STATE', 'SYSTEM_PLUGIN_HA_SET_STATE');
-- ===== end 202607290930.sql =====

-- ===== begin 202608061030.sql =====
UPDATE `ai_model_config`
SET `config_json` = JSON_SET(`config_json`, '$.model_name', 'deepseek-v4-flash')
WHERE `id` = 'LLM_DeepSeekLLM'
  AND JSON_EXTRACT(`config_json`, '$.model_name') = 'deepseek-chat';
-- ===== end 202608061030.sql =====

-- ===== begin 202608061800.sql =====
UPDATE `ai_model_config`
SET `config_json` = JSON_SET(`config_json`, '$.model_name', 'doubao-seed-2-0-lite-260215')
WHERE `id` = 'LLM_DoubaoLLM'
  AND JSON_UNQUOTE(JSON_EXTRACT(`config_json`, '$.model_name')) IN (
    'doubao-1-5-pro-32k-250115'
  );

-- Remark rewrite removed: not needed on a fresh database.
-- ===== end 202608061800.sql =====

-- ===== begin 202608131030.sql =====
UPDATE `sys_params`
SET `param_value` = '15'
WHERE `param_code` = 'tts_timeout'
  AND `param_value` = '10';
-- ===== end 202608131030.sql =====

-- ===== begin 202609021000.sql =====
-- Alibaba Bailian streaming TTS supports workspace WebSocket URLs

UPDATE `ai_model_provider`
SET `fields` = JSON_ARRAY(
    JSON_OBJECT('key', 'api_key', 'type', 'string', 'label', 'API key'),
    JSON_OBJECT(
        'key', 'ws_url',
        'type', 'string',
        'label', 'WebSocket URL (including Workspace ID)',
        'default', 'wss://dashscope.aliyuncs.com/api-ws/v1/inference/'
    ),
    JSON_OBJECT('key', 'output_dir', 'type', 'string', 'label', 'Output directory'),
    JSON_OBJECT('key', 'model', 'type', 'string', 'label', 'Model'),
    JSON_OBJECT('key', 'voice', 'type', 'string', 'label', 'Voice'),
    JSON_OBJECT('key', 'format', 'type', 'string', 'label', 'Audio format'),
    JSON_OBJECT('key', 'sample_rate', 'type', 'number', 'label', 'Sample rate'),
    JSON_OBJECT('key', 'volume', 'type', 'number', 'label', 'Volume'),
    JSON_OBJECT('key', 'rate', 'type', 'number', 'label', 'Speech rate'),
    JSON_OBJECT('key', 'pitch', 'type', 'number', 'label', 'Pitch')
)
WHERE `id` = 'SYSTEM_TTS_AliBLStreamTTS';

UPDATE `ai_model_config`
SET `config_json` = JSON_SET(
    `config_json`,
    '$.ws_url',
    COALESCE(
        NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`config_json`, '$.ws_url')), ''),
        'wss://dashscope.aliyuncs.com/api-ws/v1/inference/'
    )
)
WHERE `id` = 'TTS_AliBLStreamTTS';

UPDATE `ai_model_config`
SET `remark` = 'Alibaba Bailian streaming TTS configuration notes:
1. For the API key, enter a DashScope API Key valid for the current workspace
2. Public mode can use wss://dashscope.aliyuncs.com/api-ws/v1/inference/
3. For a North China 2 (Beijing) workspace, enter wss://<WorkspaceId>.cn-beijing.maas.aliyuncs.com/api-ws/v1/inference
4. For a Singapore workspace, enter wss://<WorkspaceId>.ap-southeast-1.maas.aliyuncs.com/api-ws/v1/inference
5. Replace <WorkspaceId> with the real workspace ID; only official Alibaba Cloud WSS inference URLs are supported
6. Supports CosyVoice streaming synthesis and volume, speech rate and pitch config'
WHERE `id` = 'TTS_AliBLStreamTTS';
-- ===== end 202609021000.sql =====

-- ===== begin 202609172100.sql =====
-- Add the Serply search source to the web search plugin

UPDATE `ai_model_provider`
SET `fields` = JSON_SET(
    `fields`,
    '$[0].label',
    'Search source: metaso / tavily / serply'
)
WHERE `id` = 'SYSTEM_PLUGIN_WEB_SEARCH';
-- ===== end 202609172100.sql =====

-- ===== begin 202610131200.sql =====
-- Add OpenRouter LLM provider (type: openrouter)
DELETE FROM `ai_model_provider` WHERE `id` = 'SYSTEM_LLM_openrouter';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_LLM_openrouter', 'LLM', 'openrouter', 'OpenRouter', '[{"key":"api_key","label":"API key","type":"string"},{"key":"model_name","label":"Model name (vendor/model, e.g. openai/gpt-4o-mini)","type":"string"},{"key":"base_url","label":"Base URL","type":"string"},{"key":"temperature","label":"Temperature","type":"number"},{"key":"max_tokens","label":"Max output tokens","type":"number"},{"key":"top_p","label":"Top P","type":"number"},{"key":"frequency_penalty","label":"Frequency penalty","type":"number"},{"key":"timeout","label":"Timeout in seconds","type":"number"},{"key":"reasoning_effort","label":"Reasoning effort (max/xhigh/high/medium/low/minimal/none, empty = not sent)","type":"string"},{"key":"fallback_models","label":"Fallback models (comma separated)","type":"string"},{"key":"provider_sort","label":"Provider sort (price/throughput/latency, ignored if order is set)","type":"string"},{"key":"provider_order","label":"Provider order (comma separated)","type":"string"},{"key":"provider_only","label":"Allowed providers (comma separated)","type":"string"},{"key":"provider_ignore","label":"Ignored providers (comma separated)","type":"string"},{"key":"allow_fallbacks","label":"Allow provider fallbacks","type":"boolean"},{"key":"require_parameters","label":"Require providers that support all request parameters","type":"boolean"},{"key":"data_collection","label":"Data collection (allow/deny, empty = not sent)","type":"string"},{"key":"zdr","label":"Zero data retention only","type":"boolean"},{"key":"preferred_max_latency","label":"Preferred max latency (seconds)","type":"number"},{"key":"preferred_min_throughput","label":"Preferred min throughput (tokens/s)","type":"number"},{"key":"record_routing","label":"Record routing metadata (selected provider) in usage log","type":"boolean"},{"key":"app_referer","label":"App URL for attribution","type":"string"},{"key":"app_title","label":"App title for attribution","type":"string"},{"key":"app_categories","label":"App categories (comma separated)","type":"string"}]', 9, 1, NOW(), 1, NOW());

-- Add OpenRouter model config
DELETE FROM `ai_model_config` WHERE `id` = 'LLM_OpenRouterLLM';
INSERT INTO `ai_model_config` VALUES ('LLM_OpenRouterLLM', 'LLM', 'OpenRouterLLM', 'OpenRouter', 0, 1, '{"type": "openrouter", "base_url": "https://openrouter.ai/api/v1", "model_name": "openai/gpt-4o-mini", "api_key": "your_api_key", "temperature": 0.7, "max_tokens": 500, "timeout": 30, "allow_fallbacks": true, "require_parameters": true, "zdr": false, "record_routing": false}', 'https://openrouter.ai/docs/api-reference/overview', 'OpenRouter gateway (official openrouter SDK). Model name format is vendor/model. Routing fields are optional, leave empty to not send them. Token and cost usage is written to the server log (llm_usage).', 15, NULL, NULL, NULL, NULL);
-- ===== end 202610131200.sql =====
