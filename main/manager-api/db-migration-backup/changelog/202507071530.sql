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
