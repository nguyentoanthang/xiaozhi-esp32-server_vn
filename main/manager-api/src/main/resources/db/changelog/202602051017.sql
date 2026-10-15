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
