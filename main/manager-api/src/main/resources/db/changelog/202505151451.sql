-- Modify the custom TTS API request definition
update `ai_model_provider` set `fields` =
'[{"key":"url","label":"Service address","type":"string"},{"key":"method","label":"Request method","type":"string"},{"key":"params","label":"Request parameters","type":"dict","dict_name":"params"},{"key":"headers","label":"Request headers","type":"dict","dict_name":"headers"},{"key":"format","label":"Audio format","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"}]'
where `id` = 'SYSTEM_TTS_custom';

-- Modify the custom TTS configuration notes
UPDATE `ai_model_config` SET
`doc_link` = NULL,
`remark` = 'Custom TTS configuration notes:
1. A custom TTS API service; the request parameters are customizable, so many TTS services can be connected
2. Take a locally deployed KokoroTTS as an example
3. If running on CPU only: docker run -p 8880:8880 ghcr.io/remsky/kokoro-fastapi-cpu:latest
4. If running on GPU only: docker run --gpus all -p 8880:8880 ghcr.io/remsky/kokoro-fastapi-gpu:latest
Configuration notes:
1. Configure the request parameters in params, using JSON format
   For example KokoroTTS: { "input": "{prompt_text}", "speed": 1, "voice": "zm_yunxi", "stream": true, "download_format": "mp3", "response_format": "mp3", "return_download_link": true }
2. Configure the request headers in headers
3. Set the returned audio format' WHERE `id` = 'TTS_CustomTTS';