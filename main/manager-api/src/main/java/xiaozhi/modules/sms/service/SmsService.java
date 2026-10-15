package xiaozhi.modules.sms.service;

/**
 * Interface defining SMS service methods
 *
 * @author zjy
 * @since 2025-05-12
 */
public interface SmsService {

    /**
     * Send the verification SMS
     * @param phone phone number
     * @param VerificationCode Captcha
     */
    void sendVerificationCodeSms(String phone, String VerificationCode) ;
}
