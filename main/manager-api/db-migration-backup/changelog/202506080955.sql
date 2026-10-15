-- Enable wake word acceleration in the control panel
update `sys_params` set param_value = 'hello;hey there' where param_code = 'wakeup_words';
update `sys_params` set param_value = 'true' where param_code = 'enable_wakeup_words_response_cache';
