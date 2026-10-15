-- Add the parameters required by the mobile SMS registration feature
delete from sys_params where id in (108, 109, 110, 111, 112, 113, 114, 115);
delete from sys_params where id in (610, 611, 612, 613);
INSERT INTO sys_params
(id, param_code, param_value, value_type, param_type, remark, creator, create_date, updater, update_date)
    VALUES
(108, 'server.name', 'xiaozhi-esp32-server', 'string', 1, 'System name', NULL, NULL, NULL, NULL),
(109, 'server.beian_icp_num', 'null', 'string', 1, 'icp filing number; fill in null to leave it unset', NULL, NULL, NULL, NULL),
(110, 'server.beian_ga_num', 'null', 'string', 1, 'public security filing number; fill in null to leave it unset', NULL, NULL, NULL, NULL),
(111, 'server.enable_mobile_register', 'false', 'boolean', 1, 'Whether to enable mobile registration', NULL, NULL, NULL, NULL),
(112, 'server.sms_max_send_count', '10', 'number', 1, 'Maximum number of SMS messages per phone number per day', NULL, NULL, NULL, NULL),
(610, 'aliyun.sms.access_key_id', '', 'string', 1, 'Alibaba Cloud platform access_key', NULL, NULL, NULL, NULL),
(611, 'aliyun.sms.access_key_secret', '', 'string', 1, 'Alibaba Cloud platform access_key_secret', NULL, NULL, NULL, NULL),
(612, 'aliyun.sms.sign_name', '', 'string', 1, 'Alibaba Cloud SMS signature', NULL, NULL, NULL, NULL),
(613, 'aliyun.sms.sms_code_template_code', '', 'string', 1, 'Alibaba Cloud SMS template', NULL, NULL, NULL, NULL);

update sys_params set remark = 'Whether people other than administrators may register' where param_code = 'server.allow_user_register';

-- Add the mobile region dictionary
-- Insert firmware type dictionary type
delete from `sys_dict_type` where `id` = 102;
INSERT INTO `sys_dict_type` (`id`, `dict_type`, `dict_name`, `remark`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES 
(102, 'MOBILE_AREA', 'Mobile region', 'Mobile region dictionary', 0, 1, NOW(), 1, NOW());

-- Insert firmware type dictionary data
delete from `sys_dict_data` where `dict_type_id` = 102;
INSERT INTO `sys_dict_data` (`id`, `dict_type_id`, `dict_label`, `dict_value`, `remark`, `sort`, `creator`, `create_date`, `updater`, `update_date`) VALUES 
(102001, 102, 'Mainland China', '+86', 'Mainland China', 1, 1, NOW(), 1, NOW()),
(102002, 102, 'Hong Kong, China', '+852', 'Hong Kong, China', 2, 1, NOW(), 1, NOW()),
(102003, 102, 'Macau, China', '+853', 'Macau, China', 3, 1, NOW(), 1, NOW()),
(102004, 102, 'Taiwan, China', '+886', 'Taiwan, China', 4, 1, NOW(), 1, NOW()),
(102005, 102, 'United States/Canada', '+1', 'United States/Canada', 5, 1, NOW(), 1, NOW()),
(102006, 102, 'United Kingdom', '+44', 'United Kingdom', 6, 1, NOW(), 1, NOW()),
(102007, 102, 'France', '+33', 'France', 7, 1, NOW(), 1, NOW()),
(102008, 102, 'Italy', '+39', 'Italy', 8, 1, NOW(), 1, NOW()),
(102009, 102, 'Germany', '+49', 'Germany', 9, 1, NOW(), 1, NOW()),
(102010, 102, 'Poland', '+48', 'Poland', 10, 1, NOW(), 1, NOW()),
(102011, 102, 'Switzerland', '+41', 'Switzerland', 11, 1, NOW(), 1, NOW()),
(102012, 102, 'Spain', '+34', 'Spain', 12, 1, NOW(), 1, NOW()),
(102013, 102, 'Denmark', '+45', 'Denmark', 13, 1, NOW(), 1, NOW()),
(102014, 102, 'Malaysia', '+60', 'Malaysia', 14, 1, NOW(), 1, NOW()),
(102015, 102, 'Australia', '+61', 'Australia', 15, 1, NOW(), 1, NOW()),
(102016, 102, 'Indonesia', '+62', 'Indonesia', 16, 1, NOW(), 1, NOW()),
(102017, 102, 'Philippines', '+63', 'Philippines', 17, 1, NOW(), 1, NOW()),
(102018, 102, 'New Zealand', '+64', 'New Zealand', 18, 1, NOW(), 1, NOW()),
(102019, 102, 'Singapore', '+65', 'Singapore', 19, 1, NOW(), 1, NOW()),
(102020, 102, 'Thailand', '+66', 'Thailand', 20, 1, NOW(), 1, NOW()),
(102021, 102, 'Japan', '+81', 'Japan', 21, 1, NOW(), 1, NOW()),
(102022, 102, 'South Korea', '+82', 'South Korea', 22, 1, NOW(), 1, NOW()),
(102023, 102, 'Vietnam', '+84', 'Vietnam', 23, 1, NOW(), 1, NOW()),
(102024, 102, 'India', '+91', 'India', 24, 1, NOW(), 1, NOW()),
(102025, 102, 'Pakistan', '+92', 'Pakistan', 25, 1, NOW(), 1, NOW()),
(102026, 102, 'Nigeria', '+234', 'Nigeria', 26, 1, NOW(), 1, NOW()),
(102027, 102, 'Bangladesh', '+880', 'Bangladesh', 27, 1, NOW(), 1, NOW()),
(102028, 102, 'Saudi Arabia', '+966', 'Saudi Arabia', 28, 1, NOW(), 1, NOW()),
(102029, 102, 'United Arab Emirates', '+971', 'United Arab Emirates', 29, 1, NOW(), 1, NOW()),
(102030, 102, 'Brazil', '+55', 'Brazil', 30, 1, NOW(), 1, NOW()),
(102031, 102, 'Mexico', '+52', 'Mexico', 31, 1, NOW(), 1, NOW()),
(102032, 102, 'Chile', '+56', 'Chile', 32, 1, NOW(), 1, NOW()),
(102033, 102, 'Argentina', '+54', 'Argentina', 33, 1, NOW(), 1, NOW()),
(102034, 102, 'Egypt', '+20', 'Egypt', 34, 1, NOW(), 1, NOW()),
(102035, 102, 'South Africa', '+27', 'South Africa', 35, 1, NOW(), 1, NOW()),
(102036, 102, 'Kenya', '+254', 'Kenya', 36, 1, NOW(), 1, NOW()),
(102037, 102, 'Tanzania', '+255', 'Tanzania', 37, 1, NOW(), 1, NOW()),
(102038, 102, 'Kazakhstan', '+7', 'Kazakhstan', 38, 1, NOW(), 1, NOW());
