-- Add the voiceprint recognition similarity threshold parameter configuration
delete from `sys_params` where id = 115;
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark)
VALUES (115, 'server.voiceprint_similarity_threshold', '0.4', 'string', 1, 'Voiceprint recognition similarity threshold, range 0.0-1.0, default 0.4; the higher the value, the stricter');
