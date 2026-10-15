UPDATE `ai_model_config`
SET `config_json` = JSON_SET(`config_json`, '$.model_name', 'doubao-seed-2-0-lite-260215')
WHERE `id` = 'LLM_DoubaoLLM'
  AND JSON_UNQUOTE(JSON_EXTRACT(`config_json`, '$.model_name')) IN (
    'doubao-1-5-pro-32k-250115'
  );

-- Remark rewrite removed: not needed on a fresh database.
