-- Add Baidu ASR Model configuration
delete from `ai_model_config` where `id` = 'ASR_BaiduASR';
INSERT INTO `ai_model_config` VALUES ('ASR_BaiduASR', 'ASR', 'BaiduASR', 'Baidu speech recognition', 0, 1, '{\"type\": \"baidu\", \"app_id\": \"\", \"api_key\": \"\", \"secret_key\": \"\", \"dev_pid\": 1537, \"output_dir\": \"tmp/\"}', NULL, NULL, 7, NULL, NULL, NULL, NULL);


-- Add Baidu ASR provider
delete from `ai_model_provider` where `id` = 'SYSTEM_ASR_BaiduASR';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_BaiduASR', 'ASR', 'baidu', 'Baidu speech recognition', '[{"key":"app_id","label":"App AppID","type":"string"},{"key":"api_key","label":"API Key","type":"string"},{"key":"secret_key","label":"Secret Key","type":"string"},{"key":"dev_pid","label":"Language parameter","type":"number"},{"key":"output_dir","label":"Output directory","type":"string"}]', 7, 1, NOW(), 1, NOW());


-- Update Baidu ASR configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.bce.baidu.com/ai-engine/old/#/ai/speech/app/list',
`remark` = 'Baidu ASR Configuration notes:
1. Access https://console.bce.baidu.com/ai-engine/old/#/ai/speech/app/list
2. Create a new application
3. Get the AppID, API Key and Secret Key
4. Fill them into the configuration file
View the resource quota: https://console.bce.baidu.com/ai-engine/old/#/ai/speech/overview/resource/list
Language parameter notes: https://ai.baidu.com/ai-doc/SPEECH/0lbxfnc9b
' WHERE `id` = 'ASR_BaiduASR';

-- Update the Doubao provider fields
update `ai_model_provider` set `fields` = 
'[{"key":"appid","label":"App ID","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"cluster","label":"Cluster","type":"string"},{"key":"boosting_table_name","label":"Hot word file name","type":"string"},{"key":"correct_table_name","label":"Replacement word file name","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]'
where `id` = 'SYSTEM_ASR_DoubaoASR';

-- Update the Doubao ASR configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/speech/app',
`remark` = 'Doubao ASR configuration notes:
1. You need to create an application in the Volcano Engine console and get the appid and access_token
2. Supports Chinese speech recognition
3. Network connection required
4. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://console.volcengine.com/speech/app
2. Create a new application
3. Get the appid and access_token
4. Fill them into the configuration file
To set hot words, see: https://www.volcengine.com/docs/6561/155738
' WHERE `id` = 'ASR_DoubaoASR';