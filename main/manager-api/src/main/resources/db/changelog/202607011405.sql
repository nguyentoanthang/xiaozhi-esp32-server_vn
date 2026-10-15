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
