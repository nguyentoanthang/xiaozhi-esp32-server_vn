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
