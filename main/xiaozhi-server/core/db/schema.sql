-- xiaozhi-server SQLite schema (version 1). Applied idempotently at startup by core/db/database.py.
-- Conventions: TEXT ids (uuid hex), timestamps as ISO-8601 UTC text ('YYYY-MM-DDTHH:MM:SSZ'),
-- JSON stored as TEXT with CHECK (json_valid(...)).
-- Pragmas (journal_mode=WAL, foreign_keys=ON, busy_timeout=5000) are set per connection in Python.

-- Global settings; same dotted keys as the old sys_params
CREATE TABLE IF NOT EXISTS setting (
  key   TEXT PRIMARY KEY,           -- e.g. 'server.port', 'log.log_level', 'exit_commands'
  value TEXT NOT NULL,              -- JSON-encoded value
  note  TEXT
);

CREATE TABLE IF NOT EXISTS model_config (
  id          TEXT PRIMARY KEY,     -- e.g. 'LLM_OpenRouter', same ids as before
  model_type  TEXT NOT NULL,        -- VAD|ASR|LLM|TTS|Memory|Intent
  model_code  TEXT NOT NULL,        -- provider type, e.g. 'openrouter', 'FunASR'
  name        TEXT NOT NULL,
  config_json TEXT NOT NULL CHECK (json_valid(config_json)),  -- keys, urls, model names
  enabled     INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS agent (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  is_default      INTEGER NOT NULL DEFAULT 0,       -- used for unknown devices
  system_prompt   TEXT,
  language        TEXT,
  vad_id TEXT REFERENCES model_config(id),
  asr_id TEXT REFERENCES model_config(id),
  llm_id TEXT REFERENCES model_config(id),
  tts_id TEXT REFERENCES model_config(id),
  mem_id TEXT REFERENCES model_config(id),
  intent_id TEXT REFERENCES model_config(id),
  tts_voice       TEXT,
  tts_params_json TEXT,                            -- {"language","volume","rate","pitch"}
  history_mode    INTEGER NOT NULL DEFAULT 2,      -- 0 off, 1 text, 2 text+audio
  plugins_json    TEXT,                            -- per-agent plugin params
  mcp_endpoint    TEXT,
  context_providers_json TEXT
);

CREATE TABLE IF NOT EXISTS replacement_word (                     -- TTS text substitutions
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  agent_id TEXT REFERENCES agent(id),              -- NULL = global (v1 uses only global rows)
  source   TEXT NOT NULL,
  target   TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_replacement_unique ON replacement_word(COALESCE(agent_id, ''), source);

CREATE TABLE IF NOT EXISTS memory (                               -- replaces data/.memory.yaml (one row per device)
  device_mac TEXT PRIMARY KEY REFERENCES device(mac),
  summary    TEXT,
  updated_at TEXT
);

CREATE TABLE IF NOT EXISTS device (
  mac               TEXT PRIMARY KEY,
  agent_id          TEXT NOT NULL REFERENCES agent(id),
  alias             TEXT,
  board             TEXT,
  app_version       TEXT,
  last_connected_at TEXT
);

CREATE TABLE IF NOT EXISTS chat_session (
  id         TEXT PRIMARY KEY,                    -- the connection's session_id
  device_mac TEXT NOT NULL,
  agent_id   TEXT NOT NULL,
  title      TEXT,
  summary    TEXT,
  started_at TEXT NOT NULL,
  ended_at   TEXT
);

CREATE TABLE IF NOT EXISTS chat_message (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL REFERENCES chat_session(id),
  chat_type  INTEGER NOT NULL,                    -- 1 user, 2 agent, 3 tool call
  content    TEXT NOT NULL,
  audio_id   INTEGER REFERENCES chat_audio(id),
  created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_msg_session ON chat_message(session_id, id);

CREATE TABLE IF NOT EXISTS chat_audio (                           -- separate table keeps BLOBs out of message scans
  id     INTEGER PRIMARY KEY AUTOINCREMENT,
  format      TEXT NOT NULL,                      -- 'opus-frames' (length-prefixed packets)
  sample_rate INTEGER NOT NULL,
  data        BLOB NOT NULL
);

CREATE TABLE IF NOT EXISTS guardrail_name (                       -- names to mask (filled by hand)
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  name    TEXT NOT NULL UNIQUE COLLATE NOCASE,
  note    TEXT,
  enabled INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS ai_usage (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  record_id         TEXT UNIQUE,                  -- UsageRecord.record_id
  created_at        TEXT NOT NULL,
  kind              TEXT NOT NULL DEFAULT 'llm',  -- llm | stt | tts
  session_id        TEXT,
  device_mac        TEXT,                         -- which ESP32 (copied at call time)
  agent_id          TEXT,                         -- which agent (copied at call time, survives re-assignment)
  purpose           TEXT,                         -- chat | intent | memory | title | summary | stt | tts
  call_kind         TEXT,                         -- llm: chat | chat_functions | no_stream
  requested_model   TEXT,
  served_model      TEXT,                         -- NULL for stt (not reported)
  provider          TEXT,                         -- NULL for stt (not reported)
  generation_id     TEXT,                         -- NULL for stt
  prompt_tokens     INTEGER,
  completion_tokens INTEGER,
  total_tokens      INTEGER,
  cost              REAL,                         -- OpenRouter usage.cost (USD)
  upstream_cost     REAL,
  is_byok           INTEGER,
  audio_seconds     REAL,                         -- stt/tts units (NULL for llm)
  ttft_ms           INTEGER,
  duration_ms       INTEGER
);
CREATE INDEX IF NOT EXISTS idx_usage_time   ON ai_usage(created_at);
CREATE INDEX IF NOT EXISTS idx_usage_device ON ai_usage(device_mac, created_at);
CREATE INDEX IF NOT EXISTS idx_usage_agent  ON ai_usage(agent_id, created_at);

-- Ready-made reports (query with plain SQL or any SQLite browser)
CREATE VIEW IF NOT EXISTS usage_by_device AS
  SELECT device_mac, kind, date(created_at, 'localtime') AS day, COUNT(*) AS calls,
         SUM(prompt_tokens) AS prompt_tokens, SUM(completion_tokens) AS completion_tokens,
         SUM(total_tokens) AS total_tokens, SUM(cost) AS cost_usd
  FROM ai_usage GROUP BY device_mac, kind, day;
CREATE VIEW IF NOT EXISTS usage_by_agent AS
  SELECT agent_id, kind, date(created_at, 'localtime') AS day, COUNT(*) AS calls,
         SUM(prompt_tokens) AS prompt_tokens, SUM(completion_tokens) AS completion_tokens,
         SUM(total_tokens) AS total_tokens, SUM(cost) AS cost_usd
  FROM ai_usage GROUP BY agent_id, kind, day;

PRAGMA user_version = 1;
