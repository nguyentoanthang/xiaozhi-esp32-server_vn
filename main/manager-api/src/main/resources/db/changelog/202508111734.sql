-- Update the HuoshanDoubleStreamTTS provider to add speech rate, pitch and other settings
UPDATE `ai_model_provider`
SET fields = '[{"key": "ws_url", "type": "string", "label": "WebSocket address"}, {"key": "appid", "type": "string", "label": "App ID"}, {"key": "access_token", "type": "string", "label": "Access token"}, {"key": "resource_id", "type": "string", "label": "Resource ID"}, {"key": "speaker", "type": "string", "label": "Default voice"}, {"key": "speech_rate", "type": "number", "label": "Speech rate (-50~100)"}, {"key": "loudness_rate", "type": "number", "label": "Volume (-50~100)"}, {"key": "pitch", "type": "number", "label": "Pitch (-12~12)"}]'
WHERE id = 'SYSTEM_TTS_HSDSTTS';

UPDATE `ai_model_config` SET 
`doc_link` = 'https://console.volcengine.com/speech/service/10007',
`remark` = 'Volcano Engine speech synthesis service configuration notes:
1. Visit https://www.volcengine.com/ to register and activate a Volcano Engine account
2. Visit https://console.volcengine.com/speech/service/10007 to activate the speech synthesis large model and buy voices
3. Get the appid and access_token at the bottom of the page
5. The resource ID is fixed to: volc.service_type.10029 (large-model speech synthesis and mixing)
6. Speech rate: -50~100, optional, the normal default is 0, can be set to -50~100
7. Volume: -50~100, optional, the normal default is 0, can be set to -50~100
8. Pitch: -12~12, optional, the normal default is 0, can be set to -12~12
9. Fill them into the configuration file' WHERE `id` = 'TTS_HuoshanDoubleStreamTTS';