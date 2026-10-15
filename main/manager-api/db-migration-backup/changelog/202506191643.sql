-- LLM intent recognition configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = NULL,
`remark` = 'LLM intent recognition configuration notes:
1. Uses a separate LLM for intent recognition
2. Uses the model of selected_module.LLM by default
3. A separate LLM can be configured (for example the free ChatGLMLLM)
4. Highly general, but increases processing time
Configuration notes:
1. Specify the LLM model to use in the llm field
2. If not specified, the model of selected_module.LLM is used' WHERE `id` = 'Intent_intent_llm';

-- Function-call intent recognition configuration notes
UPDATE `ai_model_config` SET 
`doc_link` = NULL,
`remark` = 'Function-call intent recognition configuration notes:
1. Uses the function_call feature of the LLM for intent recognition
2. The selected LLM must support function_call
3. Tools are called on demand, so processing is fast' WHERE `id` = 'Intent_function_call';