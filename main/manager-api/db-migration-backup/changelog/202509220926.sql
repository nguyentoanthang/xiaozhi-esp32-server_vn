-- Add the iFlytek streaming speech recognition service configuration
delete from `ai_model_provider` where id = 'SYSTEM_ASR_XunfeiStream';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_XunfeiStream', 'ASR', 'xunfei_stream', 'iFlytek streaming speech recognition', '[{"key":"app_id","label":"App ID","type":"string"},{"key":"api_key","label":"API_KEY","type":"password"},{"key":"api_secret","label":"API_SECRET","type":"password"},{"key":"domain","label":"Recognition domain","type":"string"},{"key":"language","label":"Recognition language","type":"string"},{"key":"accent","label":"Dialect","type":"string"},{"key":"dwa","label":"Dynamic correction","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]', 18, 1, NOW(), 1, NOW());

delete from `ai_model_config` where id = 'ASR_XunfeiStream';
INSERT INTO `ai_model_config` VALUES ('ASR_XunfeiStream', 'ASR', 'iFlytek Streaming ASR', 'iFlytek streaming speech recognition service', 0, 1, '{"type": "xunfei_stream", "app_id": "", "api_key": "", "api_secret": "", "domain": "slm", "language": "zh_cn", "accent": "mandarin", "dwa": "wpgs", "output_dir": "tmp/"}', 'https://www.xfyun.cn/doc/spark/spark_zh_iat.html', 'Supports real-time streaming speech recognition, suitable for Chinese Mandarin and recognition of multiple dialects', 21, NULL, NULL, NULL, NULL);

-- Update the iFlytek streaming speech recognition model configuration documentation
UPDATE `ai_model_config` SET
`doc_link` = 'https://www.xfyun.cn/doc/spark/spark_zh_iat.html',
`remark` = 'iFlytek streaming speech recognition configuration notes:
1. Log in to the iFlytek Open Platform https://www.xfyun.cn/
2. Create a speech recognition application to get the APPID, APISecret and APIKey
3. Parameter notes:
   - app_id: application ID, obtained after creating an application on the iFlytek Open Platform
   - api_key: API key, used for API authentication
   - api_secret: API secret, used to generate signatures
   - domain: recognition domain, default slm (intelligent speech transcription)
   - language: recognition language, default zh_cn (Chinese)
   - accent: dialect type, default mandarin (Mandarin), supports cantonese (Cantonese), etc.
   - dwa: dynamic correction, default wpgs (dynamic correction enabled)
   - output_dir: audio file output directory, default tmp/
4. Supports real-time streaming recognition, suitable for real-time voice interaction scenarios
5. Supports recognition of multiple dialects and languages
' WHERE `id` = 'ASR_XunfeiStream';