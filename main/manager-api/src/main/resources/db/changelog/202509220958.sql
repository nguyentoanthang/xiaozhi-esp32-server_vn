delete from `ai_model_config` where id = 'LLM_XunfeiSparkLLM';
INSERT INTO `ai_model_config` VALUES ('LLM_XunfeiSparkLLM', 'LLM', 'iFlytek Spark LLM', 'iFlytek Spark LLM', 0, 1, '{"type": "openai", "model_name": "generalv3.5", "base_url": "https://spark-api-open.xf-yun.com/v1", "api_password": "your_api_password", "temperature": 0.5, "max_tokens": 2048, "top_p": 1.0, "frequency_penalty": 0.0}', 'https://www.xfyun.cn/doc/spark/HTTP%E8%B0%83%E7%94%A8%E6%96%87%E6%A1%A3.html', 'iFlytek Spark LLM, supports multi-turn dialogue, text generation and other features', 14, NULL, NULL, NULL, NULL);

-- Update the documentation for the iFlytek Spark LLM configuration
UPDATE `ai_model_config` SET
`doc_link` = 'https://www.xfyun.cn/doc/spark/HTTP%E8%B0%83%E7%94%A8%E6%96%87%E6%A1%A3.html',
`remark` = 'iFlytek Spark LLM configuration notes:
1. Log in to the iFlytek Open Platform https://www.xfyun.cn/. Each model has its own api_password; when changing models, check the api_password of the corresponding model
2. Create a Spark LLM application to obtain the API Password
3. Parameter description:
   - api_password: API Password, obtained after creating an application on the iFlytek Open Platform
   - model_name: model name, supports generalv3.5, generalv3 and other versions
   - base_url: API URL, default https://spark-api-open.xf-yun.com/v1
   - temperature: temperature parameter, controls generation randomness, range 0-1, default 0.5
   - max_tokens: maximum number of output tokens, default 2048
   - top_p: nucleus sampling parameter, controls vocabulary diversity, default 1.0
   - frequency_penalty: frequency penalty, reduces repeated content, default 0.0
4. Each model has its own api_password; when changing models, check the api_password of the corresponding model.
' WHERE `id` = 'LLM_XunfeiSparkLLM';