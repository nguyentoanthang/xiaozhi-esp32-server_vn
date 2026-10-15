-- Update the Tencent TTS provider config, adding the speed, volume and format parameters
UPDATE `ai_model_provider`
SET fields = '[{"key":"appid","label":"App ID","type":"string"},{"key":"secret_id","label":"Secret ID","type":"string"},{"key":"secret_key","label":"Secret Key","type":"string"},{"key":"format","label":"Audio format","type":"string"},{"key":"speed","label":"Speech rate","type":"number"},{"key":"volume","label":"Volume","type":"number"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"voice","label":"Voice ID","type":"string"},{"key":"region","label":"Region","type":"string"}]'
WHERE id = 'SYSTEM_TTS_TencentTTS';

-- Update the Tencent TTS model config, adding the speed and volume parameters and parameter descriptions
UPDATE `ai_model_config` SET 
    `config_json` = JSON_SET(`config_json`, '$.speed', 0, '$.volume', 0),
    `remark` = 'Tencent TTS configuration notes:
1. You need to activate the intelligent speech interaction service on the Tencent Cloud platform
2. Multiple voices are supported; the current config uses 101001
3. Requires a network connection
4. Output files are saved in the tmp/ directory
Application steps:
1. Visit https://console.cloud.tencent.com/cam/capi to get the keys
2. Visit https://console.cloud.tencent.com/tts/resourcebundle to claim free resources
3. Create a new application
4. Get the appid, secret_id and secret_key
5. Fill them into the configuration file
Audio parameters:
- format: audio format, supports pcm, wav, mp3
- speed: speech rate, range -2~6, default 0
- volume: volume, range -10~10, default 0'
WHERE `id` = 'TTS_TencentTTS';

-- Update the CozeCnTTS provider config, adding the speed and loudness_rate parameters
UPDATE `ai_model_provider`
SET fields = '[{"key":"voice","label":"Voice","type":"string"},{"key":"access_token","label":"Access token","type":"string"},{"key":"speed","label":"Speech rate","type":"number"},{"key":"loudness_rate","label":"Volume gain","type":"number"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"response_format","label":"Response format","type":"string"}]'
WHERE id = 'SYSTEM_TTS_cozecn';

-- Update the CozeCnTTS model config, adding the speed and loudness_rate parameters and parameter descriptions
UPDATE `ai_model_config` SET 
    `config_json` = JSON_SET(`config_json`, '$.speed', 1, '$.loudness_rate', 0),
    `remark` = 'Coze Chinese speech synthesis configuration notes:
1. Visit https://www.coze.cn/ to register and log in
2. Create an application and get the access_token
3. Choose a suitable voice ID
Audio parameters:
- response_format: audio format, supports pcm, wav, mp3
- speed: speech rate, range 0.5~2, default 1
- loudness_rate: volume gain, range -50~100, default 0'
WHERE `id` = 'TTS_CozeCnTTS';
