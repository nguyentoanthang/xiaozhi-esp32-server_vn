-- VLLM Model provider
delete from `ai_model_provider` where id = 'SYSTEM_ASR_DoubaoStreamASR';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_DoubaoStreamASR', 'ASR', 'doubao_stream', 'Volcano Engine speech recognition (Streaming)', '[{"key":"appid","label":"App ID","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"cluster","label":"Cluster","type":"string"},{"key":"boosting_table_name","label":"Hot word file name","type":"string"},{"key":"correct_table_name","label":"Replacement word file name","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]', 3, 1, NOW(), 1, NOW());


-- VLLM Model configuration
delete from `ai_model_config` where id = 'ASR_DoubaoStreamASR';
INSERT INTO `ai_model_config` VALUES ('ASR_DoubaoStreamASR', 'ASR', 'DoubaoStreamASR', 'Doubao speech recognition (Streaming)', 0, 1, '{\"type\": \"doubao_stream\", \"appid\": \"\", \"access_token\": \"\", \"cluster\": \"volcengine_input_common\", \"output_dir\": \"tmp/\"}', NULL, NULL, 3, NULL, NULL, NULL, NULL);


-- Update the Doubao ASR configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/speech/app',
`remark` = 'Doubao ASR configuration notes:
1. Difference between Doubao ASR and Doubao (streaming) ASR: Doubao ASR is billed per call, Doubao (streaming) ASR is billed by time
2. Generally, per-call billing is cheaper, but Doubao (streaming) ASR uses large-model technology and gives better results
3. You need to create an application in the Volcano Engine console and get the appid and access_token
4. Supports Chinese speech recognition
5. Network connection required
6. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://console.volcengine.com/speech/app
2. Create a new application
3. Get the appid and access_token
4. Fill them into the configuration file
To set hot words, see: https://www.volcengine.com/docs/6561/155738
' WHERE `id` = 'ASR_DoubaoASR';

UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/speech/app',
`remark` = 'Doubao ASR configuration notes:
1. Difference between Doubao ASR and Doubao (streaming) ASR: Doubao ASR is billed per call, Doubao (streaming) ASR is billed by time
2. Generally, per-call billing is cheaper, but Doubao (streaming) ASR uses large-model technology and gives better results
3. You need to create an application in the Volcano Engine console and get the appid and access_token
4. Supports Chinese speech recognition
5. Network connection required
6. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://console.volcengine.com/speech/app
2. Create a new application
3. Get the appid and access_token
4. Fill them into the configuration file
To set hot words, see: https://www.volcengine.com/docs/6561/155738
' WHERE `id` = 'ASR_DoubaoStreamASR';
