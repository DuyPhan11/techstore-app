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

    private void sendHtmlMail(String toEmail, String subject, String htmlContent, String otpCode) throws MailException {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(mailFrom);
            helper.setTo(toEmail);
            helper.setSubject(subject);
            helper.setText(htmlContent, true);

            mailSender.send(message);
            log.info("Đã gửi email xác thực thành công tới: {}", toEmail);
        } catch (Exception ex) {
            log.error("Không thể gửi email qua SMTP tới: {}", toEmail, ex);
            if (ex instanceof MailException mailException) {
                throw mailException;
            }
            throw new org.springframework.mail.MailSendException("Không thể gửi email xác thực.", ex);
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
