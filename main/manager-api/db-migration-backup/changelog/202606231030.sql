-- Update the EdgeTTS provider, adding speech rate, pitch and volume config
UPDATE `ai_model_provider`
SET fields = '[{"key":"voice","label":"Voice","type":"string"},{"key":"output_dir","label":"Output directory","type":"string"},{"key":"rate","label":"Speech rate (-100~100)","type":"number"},{"key":"volume","label":"Volume (0~100)","type":"number"},{"key":"pitch","label":"Pitch (-100~100)","type":"number"}]'
WHERE id = 'SYSTEM_TTS_edge';

UPDATE `ai_model_config` SET
`remark` = 'EdgeTTS configuration notes:
1. Uses the Microsoft Edge TTS service
2. Supports multiple languages and voices
3. Free to use, no registration required
4. Requires a network connection
5. Output files are saved in the tmp/ directory
6. Speech rate: -100~100, 0 is the normal speed
7. Volume: 0~100, 50 is the normal volume
8. Pitch: -100~100, 0 is the normal pitch' WHERE `id` = 'TTS_EdgeTTS';
