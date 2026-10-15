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