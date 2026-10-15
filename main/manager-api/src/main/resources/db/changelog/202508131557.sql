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