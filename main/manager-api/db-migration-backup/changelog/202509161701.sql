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