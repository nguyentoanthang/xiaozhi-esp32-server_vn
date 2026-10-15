-- Delete the provider config whose provider_code is linkerai
DELETE FROM `ai_model_provider` WHERE `provider_code` = 'linkerai';

-- Delete the model config whose model_code is LinkeraiTTS
DELETE FROM `ai_model_config` WHERE `model_code` = 'LinkeraiTTS';

-- Delete the TTS voice records associated with LinkeraiTTS
DELETE FROM `ai_tts_voice` WHERE `tts_model_id` = 'TTS_LinkeraiTTS';
