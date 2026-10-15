-- Alibaba Bailian streaming TTS supports workspace WebSocket URLs

UPDATE `ai_model_provider`
SET `fields` = JSON_ARRAY(
    JSON_OBJECT('key', 'api_key', 'type', 'string', 'label', 'API key'),
    JSON_OBJECT(
        'key', 'ws_url',
        'type', 'string',
        'label', 'WebSocket URL (including Workspace ID)',
        'default', 'wss://dashscope.aliyuncs.com/api-ws/v1/inference/'
    ),
    JSON_OBJECT('key', 'output_dir', 'type', 'string', 'label', 'Output directory'),
    JSON_OBJECT('key', 'model', 'type', 'string', 'label', 'Model'),
    JSON_OBJECT('key', 'voice', 'type', 'string', 'label', 'Voice'),
    JSON_OBJECT('key', 'format', 'type', 'string', 'label', 'Audio format'),
    JSON_OBJECT('key', 'sample_rate', 'type', 'number', 'label', 'Sample rate'),
    JSON_OBJECT('key', 'volume', 'type', 'number', 'label', 'Volume'),
    JSON_OBJECT('key', 'rate', 'type', 'number', 'label', 'Speech rate'),
    JSON_OBJECT('key', 'pitch', 'type', 'number', 'label', 'Pitch')
)
WHERE `id` = 'SYSTEM_TTS_AliBLStreamTTS';

UPDATE `ai_model_config`
SET `config_json` = JSON_SET(
    `config_json`,
    '$.ws_url',
    COALESCE(
        NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`config_json`, '$.ws_url')), ''),
        'wss://dashscope.aliyuncs.com/api-ws/v1/inference/'
    )
)
WHERE `id` = 'TTS_AliBLStreamTTS';

UPDATE `ai_model_config`
SET `remark` = 'Alibaba Bailian streaming TTS configuration notes:
1. For the API key, enter a DashScope API Key valid for the current workspace
2. Public mode can use wss://dashscope.aliyuncs.com/api-ws/v1/inference/
3. For a North China 2 (Beijing) workspace, enter wss://<WorkspaceId>.cn-beijing.maas.aliyuncs.com/api-ws/v1/inference
4. For a Singapore workspace, enter wss://<WorkspaceId>.ap-southeast-1.maas.aliyuncs.com/api-ws/v1/inference
5. Replace <WorkspaceId> with the real workspace ID; only official Alibaba Cloud WSS inference URLs are supported
6. Supports CosyVoice streaming synthesis and volume, speech rate and pitch config'
WHERE `id` = 'TTS_AliBLStreamTTS';
