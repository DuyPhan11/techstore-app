package com.techstore.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class PasswordResetMailService {
    private final JavaMailSender mailSender;
    @Value("${app.frontend-url}")
    private String frontendUrl;
    @Value("${app.mail-from}")
    private String from;

    public void send(String email, String token) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(email);
        message.setSubject("TechStore - Đặt lại mật khẩu");
        message.setText("Mở liên kết sau để đặt lại mật khẩu trong vòng 15 phút:\n"
                + frontendUrl.replaceAll("/+$", "") + "/pages/auth/forgot-password.html#token=" + token
                + "\nNếu bạn không yêu cầu, hãy bỏ qua email này.");
        mailSender.send(message);
    }
}
