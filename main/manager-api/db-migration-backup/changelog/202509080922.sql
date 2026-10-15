delete from `sys_params` where param_code = 'server.mqtt_gateway';
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (116, 'server.mqtt_gateway', 'null', 'string', 1, 'mqtt gateway configuration');

delete from `sys_params` where param_code = 'server.mqtt_signature_key';
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (117, 'server.mqtt_signature_key', 'null', 'string', 1, 'mqtt key configuration');

delete from `sys_params` where param_code = 'server.udp_gateway';
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (118, 'server.udp_gateway', 'null', 'string', 1, 'udp gateway configuration');