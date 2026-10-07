package com.techstore.service;

import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.mail.MailException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.mail-from:TechStore <noreply@techstore.vn>}")
    private String mailFrom;

    /**
     * Gửi email mã OTP xác thực đăng ký tài khoản
     */
    public void sendRegistrationOtp(String toEmail, String otpCode) throws MailException {
        String subject = "TechStore - Mã xác thực đăng ký tài khoản: " + otpCode;
        String content = buildHtmlTemplate(
                "Xác thực đăng ký tài khoản",
                "Cảm ơn bạn đã lựa chọn đăng ký tài khoản tại <strong>TechStore</strong>. Vui lòng sử dụng mã OTP bên dưới để kích hoạt tài khoản của bạn trên ứng dụng:",
                otpCode,
                "Mã xác thực có hiệu lực trong vòng <strong>10 phút</strong>. Vì lý do an toàn, vui lòng không cung cấp mã này cho bất kỳ ai khác."
        );
        sendHtmlMail(toEmail, subject, content, otpCode);
    }

    /**
     * Gửi email mã OTP đặt lại mật khẩu
     */
    public void sendForgotPasswordOtp(String toEmail, String otpCode) throws MailException {
        String subject = "TechStore - Mã xác thực đặt lại mật khẩu: " + otpCode;
        String content = buildHtmlTemplate(
                "Yêu cầu đặt lại mật khẩu",
                "Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản liên kết với email <strong>" + toEmail + "</strong>. Vui lòng nhập mã OTP bên dưới vào ứng dụng để tiến hành đổi mật khẩu mới:",
                otpCode,
                "Mã xác thực có hiệu lực trong vòng <strong>10 phút</strong>. Nếu bạn không gửi yêu cầu này, vui lòng bỏ qua email và tài khoản của bạn vẫn được bảo mật an toàn."
        );
        sendHtmlMail(toEmail, subject, content, otpCode);
    }

    @Value("${resend.api-key:${RESEND_API_KEY:}}")
    private String resendApiKey;

    @Value("${brevo.api-key:${BREVO_API_KEY:}}")
    private String brevoApiKey;

    @Value("${brevo.sender-email:${BREVO_SENDER_EMAIL:phankeduy112005@gmail.com}}")
    private String brevoSenderEmail;

    @Value("${brevo.sender-name:${BREVO_SENDER_NAME:TechStore}}")
    private String brevoSenderName;

    private String resolveResendApiKey() {
        if (resendApiKey != null && !resendApiKey.isBlank()) {
            return resendApiKey.trim();
        }
        String envKey = System.getenv("RESEND_API_KEY");
        if (envKey != null && !envKey.isBlank()) {
            return envKey.trim();
        }
        return System.getProperty("RESEND_API_KEY");
    }

    private String resolveBrevoApiKey() {
        if (brevoApiKey != null && !brevoApiKey.isBlank()) {
            return brevoApiKey.trim();
        }
        String envKey = System.getenv("BREVO_API_KEY");
        if (envKey != null && !envKey.isBlank()) {
            return envKey.trim();
        }
        return System.getProperty("BREVO_API_KEY");
    }

    private void sendHtmlMail(String toEmail, String subject, String htmlContent, String otpCode) {
        boolean sent = false;
        String brevoKey = resolveBrevoApiKey();
        String resendKey = resolveResendApiKey();

        // 1. Ưu tiên hàng đầu: Brevo HTTPS API (Cổng 443 - gửi được cho MỌI EMAIL không cần tên miền)
        if (brevoKey != null && !brevoKey.isBlank()) {
            sent = trySendViaBrevo(brevoKey, toEmail, subject, htmlContent);
        }

        // 2. Dự phòng: Resend HTTPS API (Cổng 443)
        if (!sent && resendKey != null && !resendKey.isBlank()) {
            sent = trySendViaResend(resendKey, toEmail, subject, htmlContent);
        }

        // 3. Nếu chưa gửi được và chạy ở Local, thử qua Google SMTP (Cổng 587)
        if (!sent) {
            try {
                MimeMessage message = mailSender.createMimeMessage();
                MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

                helper.setFrom(mailFrom);
                helper.setTo(toEmail);
                helper.setSubject(subject);
                helper.setText(htmlContent, true);

                mailSender.send(message);
                sent = true;
                log.info("Đã gửi email xác thực thành công qua SMTP tới: {}", toEmail);
            } catch (Exception ex) {
                log.warn("Không thể kết nối cổng SMTP (Cloud Render Free chặn cổng SMTP 587): {}", ex.getMessage());
            }
        }

        // 4. Fallback an toàn: Ghi mã OTP to rõ vào console log để không làm nghẽn luồng đăng ký
        log.info("\n"
                + "=================================================================\n"
                + "⚡ [TECHSTORE OTP NOTIFICATION]\n"
                + "📧 Người nhận: {}\n"
                + "🔑 MÃ OTP XÁC THỰC (Hiệu lực 10 phút): {}\n"
                + "ℹ️ Trạng thái gửi mail thật: {}\n"
                + "=================================================================",
                toEmail, otpCode, sent ? "THÀNH CÔNG" : "LẤY MÃ TRỰC TIẾP TẠI ĐÂY");
    }

    private boolean trySendViaBrevo(String apiKey, String toEmail, String subject, String htmlContent) {
        try {
            log.info("Đang gửi email xác thực qua Brevo HTTPS API tới: {}...", toEmail);
            org.springframework.web.client.RestTemplate restTemplate = new org.springframework.web.client.RestTemplate();
            org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
            headers.setContentType(org.springframework.http.MediaType.APPLICATION_JSON);
            headers.set("api-key", apiKey);
            headers.set("Accept", "application/json");

            String senderEmail = (brevoSenderEmail != null && !brevoSenderEmail.isBlank())
                    ? brevoSenderEmail.trim()
                    : "phankeduy112005@gmail.com";
            String senderName = (brevoSenderName != null && !brevoSenderName.isBlank())
                    ? brevoSenderName.trim()
                    : "TechStore";

            java.util.Map<String, Object> body = java.util.Map.of(
                    "sender", java.util.Map.of("name", senderName, "email", senderEmail),
                    "to", java.util.List.of(java.util.Map.of("email", toEmail)),
                    "subject", subject,
                    "htmlContent", htmlContent
            );

            org.springframework.http.HttpEntity<java.util.Map<String, Object>> entity = new org.springframework.http.HttpEntity<>(body, headers);
            org.springframework.http.ResponseEntity<String> res = restTemplate.postForEntity("https://api.brevo.com/v3/smtp/email", entity, String.class);
            log.info("Đã gửi email xác thực thành công qua Brevo HTTPS tới: {} (Response: {})", toEmail, res.getBody());
            return true;
        } catch (org.springframework.web.client.HttpStatusCodeException ex) {
            log.warn("Brevo API phản hồi lỗi (HTTP {}): {}", ex.getStatusCode(), ex.getResponseBodyAsString());
            return false;
        } catch (Exception e) {
            log.warn("Gửi mail qua Brevo thất bại: {}", e.getMessage());
            return false;
        }
    }

    private boolean trySendViaResend(String apiKey, String toEmail, String subject, String htmlContent) {
        try {
            log.info("Đang gửi email xác thực qua Resend API tới: {}...", toEmail);
            org.springframework.web.client.RestTemplate restTemplate = new org.springframework.web.client.RestTemplate();
            org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
            headers.setContentType(org.springframework.http.MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            java.util.Map<String, Object> body = java.util.Map.of(
                    "from", "TechStore <onboarding@resend.dev>",
                    "to", java.util.List.of(toEmail),
                    "subject", subject,
                    "html", htmlContent
            );

            org.springframework.http.HttpEntity<java.util.Map<String, Object>> entity = new org.springframework.http.HttpEntity<>(body, headers);
            org.springframework.http.ResponseEntity<String> res = restTemplate.postForEntity("https://api.resend.com/emails", entity, String.class);
            log.info("Đã gửi email xác thực thành công qua Resend HTTPS tới: {} (Response: {})", toEmail, res.getBody());
            return true;
        } catch (org.springframework.web.client.HttpStatusCodeException ex) {
            log.warn("Resend API phản hồi lỗi (HTTP {}): {}", ex.getStatusCode(), ex.getResponseBodyAsString());
            return false;
        } catch (Exception e) {
            log.warn("Gửi mail qua Resend thất bại: {}", e.getMessage());
            return false;
        }
    }

    private String buildHtmlTemplate(String title, String description, String otpCode, String note) {
        return "<!DOCTYPE html>"
                + "<html>"
                + "<head>"
                + "<meta charset='UTF-8'>"
                + "<meta name='viewport' content='width=device-width, initial-scale=1.0'>"
                + "<style>"
                + "  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }"
                + "  .container { max-width: 520px; margin: 0 auto; background: #FFFFFF; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.06); border: 1px solid #E2E8F0; }"
                + "  .header { background: linear-gradient(135deg, #0F172A 0%, #1E293B 50%, #2563EB 100%); padding: 32px 24px; text-align: center; color: #FFFFFF; }"
                + "  .logo { font-size: 26px; font-weight: 800; letter-spacing: 2px; color: #38BDF8; margin-bottom: 6px; }"
                + "  .sub-logo { font-size: 13px; color: #94A3B8; text-transform: uppercase; letter-spacing: 1px; }"
                + "  .body { padding: 32px 24px; }"
                + "  .title { font-size: 20px; font-weight: 700; color: #0F172A; margin-top: 0; margin-bottom: 12px; }"
                + "  .desc { font-size: 14px; line-height: 1.6; color: #475569; margin-bottom: 24px; }"
                + "  .otp-box { background: #F1F5F9; border: 2px dashed #CBD5E1; border-radius: 12px; padding: 18px; text-align: center; margin-bottom: 24px; }"
                + "  .otp-label { font-size: 12px; text-transform: uppercase; font-weight: 600; color: #64748B; letter-spacing: 1px; margin-bottom: 6px; }"
                + "  .otp-code { font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #2563EB; font-family: 'Courier New', monospace; }"
                + "  .note { font-size: 13px; line-height: 1.5; color: #64748B; background: #FFFBEB; border-left: 4px solid #F59E0B; padding: 12px 14px; border-radius: 6px; margin-bottom: 24px; }"
                + "  .footer { background: #F8FAFC; padding: 20px 24px; text-align: center; font-size: 12px; color: #94A3B8; border-top: 1px solid #E2E8F0; }"
                + "</style>"
                + "</head>"
                + "<body>"
                + "  <div class='container'>"
                + "    <div class='header'>"
                + "      <div class='logo'>⚡ TECHSTORE</div>"
                + "      <div class='sub-logo'>Hệ thống công nghệ chính hãng</div>"
                + "    </div>"
                + "    <div class='body'>"
                + "      <h2 class='title'>" + title + "</h2>"
                + "      <p class='desc'>" + description + "</p>"
                + "      <div class='otp-box'>"
                + "        <div class='otp-label'>Mã xác thực của bạn</div>"
                + "        <div class='otp-code'>" + otpCode + "</div>"
                + "      </div>"
                + "      <div class='note'>" + note + "</div>"
                + "    </div>"
                + "    <div class='footer'>"
                + "      Email này được gửi tự động từ hệ thống TechStore.<br>"
                + "      Vui lòng không trả lời trực tiếp email này. Hỗ trợ kỹ thuật: 1900 8888"
                + "    </div>"
                + "  </div>"
                + "</body>"
                + "</html>";
    }
}
