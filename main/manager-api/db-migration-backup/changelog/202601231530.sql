-- Update the HuoshanDoubleStreamTTS provider config, changing the scattered parameters to JSON dict config
-- Consolidate parameters such as speech_rate, loudness_rate, pitch, emotion and emotion_scale into three JSON dicts: audio_params, additions and mix_speaker

UPDATE `ai_model_provider`
SET `fields` = '[
  {"key": "ws_url", "type": "string", "label": "WebSocket URL"},
  {"key": "appid", "type": "string", "label": "App ID"},
  {"key": "access_token", "type": "string", "label": "Access token"},
  {"key": "resource_id", "type": "string", "label": "Resource ID"},
  {"key": "speaker", "type": "string", "label": "Default voice"},
  {"key": "enable_ws_reuse", "type": "boolean", "label": "Enable connection reuse", "default": true},
  {"key": "audio_params", "type": "dict", "label": "Audio output config"},
  {"key": "additions", "type": "dict", "label": "Advanced text processing config"},
  {"key": "mix_speaker", "type": "dict", "label": "Mix control config"}
]'
WHERE `id` = 'SYSTEM_TTS_HSDSTTS';

-- Update the existing config, migrating the old scattered parameters to the new JSON dict structure
UPDATE `ai_model_config`
SET `config_json` = JSON_SET(
    `config_json`,
    '$.audio_params', JSON_OBJECT(
        'speech_rate', CAST(COALESCE(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`config_json`, '$.speech_rate')), ''), '0') AS SIGNED),
        'loudness_rate', CAST(COALESCE(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`config_json`, '$.loudness_rate')), ''), '0') AS SIGNED)
    ),
    '$.additions', JSON_OBJECT(
        'aigc_metadata', JSON_OBJECT(),
        'cache_config', JSON_OBJECT(),
        'post_process', JSON_OBJECT(
            'pitch', CAST(COALESCE(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`config_json`, '$.pitch')), ''), '0') AS SIGNED)
        )
    ),
    '$.mix_speaker', JSON_OBJECT()
)
WHERE `id` = 'TTS_HuoshanDoubleStreamTTS';

-- Delete the old scattered parameter fields
UPDATE `ai_model_config`
SET `config_json` = JSON_REMOVE(
    `config_json`,
    '$.speech_rate',
    '$.loudness_rate',
    '$.pitch',
    '$.emotion',
    '$.emotion_scale'
)
WHERE `id` = 'TTS_HuoshanDoubleStreamTTS';

-- Update documentation links and remarks
UPDATE `ai_model_config` SET
`doc_link` = 'https://www.volcengine.com/docs/6561/1329505',
`remark` = 'Volcano Engine bidirectional streaming TTS configuration notes:
1. Visit https://www.volcengine.com/ to register and activate a Volcano Engine account
2. Visit https://console.volcengine.com/speech/service/10007 to activate the speech synthesis model and purchase voices
3. Get the appid and access_token at the bottom of the page
4. The resource ID is fixed as: volc.service_type.10029 (large-model speech synthesis and mixing)
5. Connection reuse: enables WebSocket connection reuse, default true to reduce connection overhead (note: after reuse, idle connections count toward concurrency while the device is in listening state)

Detailed parameter documentation: https://www.volcengine.com/docs/6561/1329505
[audio_params] Audio output config - users can add any audio parameter supported by Volcano Engine
  - speech_rate: speech rate (-50~100), default 0
  - loudness_rate: volume (-50~100), default 0
  - emotion: emotion type (only some voices support it), allowed values: neutral, happy, sad, angry, fearful, disgusted, surprised
  - emotion_scale: emotion intensity (1~5), default 4
  Example: {"speech_rate": 10, "loudness_rate": 5, "emotion": "happy", "emotion_scale": 4}

[additions] Advanced text processing config - users can add any advanced parameter supported by Volcano Engine
  - post_process.pitch: pitch (-12~12), default 0
  - aigc_metadata: AIGC metadata config
  - cache_config: cache config
  Example: {"post_process": {"pitch": 2}, "aigc_metadata": {}, "cache_config": {}}

[mix_speaker] Mix control config - multi-voice mixing (TTS 1.0 only)
  Example:
    {"speakers": [
      {"source_speaker": "zh_male_bvlazysheep","mix_factor": 0.3}, 
      {"source_speaker": "BV120_streaming","mix_factor": 0.3}, 
      {"source_speaker": "zh_male_ahu_conversation_wvae_bigtts","mix_factor": 0.4}
    ]}

Note:
- The multi-emotion voice parameters (emotion, emotion_scale) are only supported by some voices
- Related voice list: https://www.volcengine.com/docs/6561/1257544
- Users can add more parameters according to the Volcano Engine API documentation
- The mixing feature mainly applies to Doubao speech synthesis model 1.0 voices; when using it, set req_params.speaker to custom_mix_bigtts
'
WHERE `id` = 'TTS_HuoshanDoubleStreamTTS';
