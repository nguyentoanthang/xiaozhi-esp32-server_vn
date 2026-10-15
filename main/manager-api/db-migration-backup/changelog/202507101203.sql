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