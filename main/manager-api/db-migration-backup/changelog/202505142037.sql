update ai_agent_template set system_prompt = replace(system_prompt, 'I am', 'You are');

delete from sys_params where id in (500,501,402);
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (500, 'end_prompt.enable', 'true', 'boolean', 1, 'Whether to enable the closing message');
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (501, 'end_prompt.prompt', 'Please end this conversation with warm, reluctant words, starting with "Time flies".', 'string', 1, 'End prompt');

INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (402, 'plugins.get_weather.api_host', 'mj7p3y7naa.re.qweatherapi.com', 'string', 1, 'Developer apihost');