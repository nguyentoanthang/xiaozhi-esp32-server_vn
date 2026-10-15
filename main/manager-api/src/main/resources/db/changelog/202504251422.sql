-- Add server.ota, used to configure ota address

delete from `sys_params` where id = 100;
delete from `sys_params` where id = 101;

delete from `sys_params` where id = 106;
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (106, 'server.websocket', 'null', 'string', 1, 'websocket address, separate multiple addresses with ;');

delete from `sys_params` where id = 107;
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES (107, 'server.ota', 'null', 'string', 1, 'ota address');


-- AddFirmware info table
CREATE TABLE IF NOT EXISTS `ai_ota` (
  `id` varchar(32) NOT NULL COMMENT 'ID',
  `firmware_name` varchar(100) DEFAULT NULL COMMENT 'Firmware name',
  `type` varchar(50) DEFAULT NULL COMMENT 'Firmware type',
  `version` varchar(50) DEFAULT NULL COMMENT 'Version',
  `size` bigint DEFAULT NULL COMMENT 'File size (bytes)',
  `remark` varchar(500) DEFAULT NULL COMMENT 'Remarks/Notes',
  `firmware_path` varchar(255) DEFAULT NULL COMMENT 'Firmware path',
  `sort` int unsigned DEFAULT '0' COMMENT 'Sort',
  `updater` bigint DEFAULT NULL COMMENT 'Updated by',
  `update_date` datetime DEFAULT NULL COMMENT 'Updated at',
  `creator` bigint DEFAULT NULL COMMENT 'Created by',
  `create_date` datetime DEFAULT NULL COMMENT 'Created at',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Firmware info table';

update ai_device set auto_update = 1;
