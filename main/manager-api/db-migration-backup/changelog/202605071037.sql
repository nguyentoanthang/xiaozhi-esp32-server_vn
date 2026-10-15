-- Delete the provider whose provider_code is ttson
DELETE FROM `ai_model_provider` WHERE `provider_code` = 'ttson';

-- Delete the config whose model_code is ACGNTTS
DELETE FROM `ai_model_config` WHERE `model_code` = 'ACGNTTS';
