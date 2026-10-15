-- Add the call-device tool config                                                                                                                            
SET @data_exists = (SELECT COUNT(*) FROM ai_model_provider WHERE id = 'SYSTEM_PLUGIN_CALL_DEVICE');                                                   
SET @sql = IF(@data_exists = 0,
    'INSERT INTO `ai_model_provider` (`id`, `model_type`, `provider_code`, `name`, `fields`, `sort`, `creator`, `create_date`, `updater`,
`update_date`) VALUES (''SYSTEM_PLUGIN_CALL_DEVICE'', ''Plugin'', ''call_device'', ''Device calls device'', ''[]'', 85, 1988490863118454785, ''2026-05-18     
12:00:00'', 1988490863118454785, ''2026-05-18 12:00:00'')',
    'SELECT ''data already exists, skip'' AS msg');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Update the system menu config, adding the contact management menu
UPDATE sys_params
SET param_value = CAST(
    JSON_SET(
        CAST(param_value AS JSON),
        '$.addressBook',
        JSON_OBJECT(
            'name', 'feature.addressBook.name',
            'enabled', FALSE,
            'description', 'feature.addressBook.description'
        )
    ) AS CHAR
)
WHERE param_code = 'system-web.menu'
  AND NOT JSON_CONTAINS_PATH(CAST(param_value AS JSON), 'one', '$.addressBook');

-- Create the device contact table
CREATE TABLE IF NOT EXISTS `ai_device_address_book` (
    `mac_address` VARCHAR(64) NOT NULL COMMENT 'This device MAC address',
    `target_mac` VARCHAR(64) NOT NULL COMMENT 'Peer device MAC address',
    `alias` VARCHAR(64) DEFAULT NULL COMMENT 'Alias',
    `has_permission` TINYINT(1) DEFAULT TRUE COMMENT 'Whether calling is permitted',
    `creator` BIGINT DEFAULT NULL COMMENT 'Creator',
    `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updater` BIGINT DEFAULT NULL COMMENT 'Updater',
    `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    PRIMARY KEY (`mac_address`, `target_mac`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Device contact table';