-- Add SM2 (Chinese national cryptographic standard) key parameters
-- Used for server-side SM2 encryption and decryption

-- Add SM2 key parameters
INSERT INTO `sys_params` (id, param_code, param_value, value_type, param_type, remark) VALUES 
(120, 'server.public_key', '', 'string', 1, 'Server SM2 public key'),
(121, 'server.private_key', '', 'string', 1, 'Server SM2 private key');