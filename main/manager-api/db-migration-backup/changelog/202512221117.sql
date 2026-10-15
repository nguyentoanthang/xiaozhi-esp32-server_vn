-- Update the Doubao streaming ASR provider, adding the end_window_size config
delete from `ai_model_provider` where id = 'SYSTEM_ASR_DoubaoStreamASR';
INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES
('SYSTEM_ASR_DoubaoStreamASR', 'ASR', 'doubao_stream', 'Volcano Engine speech recognition (streaming)', '[{"key":"appid","label":"App ID","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"cluster","label":"Cluster","type":"string"},{"key":"boosting_table_name","label":"Hotword file name","type":"string"},{"key":"correct_table_name","label":"Replacement word file name","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"end_window_size","label":"Silence detection duration (ms)","type":"number"}]', 3, 1, NOW(), 1, NOW());


-- Update the Doubao streaming ASR model config, adding the end_window_size default value
UPDATE `ai_model_config` SET
`config_json` = JSON_SET(`config_json`, '$.end_window_size', 200)
WHERE `id` = 'ASR_DoubaoStreamASR' AND JSON_EXTRACT(`config_json`, '$.end_window_size') IS NULL;
