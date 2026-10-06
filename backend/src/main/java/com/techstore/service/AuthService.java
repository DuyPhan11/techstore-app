package com.techstore.service;

import com.techstore.dto.*;

public interface AuthService {
    AuthResponse register(RegisterRequest request);
    AuthResponse login(LoginRequest request);
    AuthResponse loginWithGoogle(GoogleLoginRequest request);
    void forgotPassword(ForgotPasswordRequest request);
    void resetPassword(ResetPasswordRequest request);
    UserSummaryDto getCurrentUser();
    UserSummaryDto updateProfile(UpdateProfileRequest request);
    AuthResponse verifyEmail(VerifyOtpRequest request);
    void resendOtp(ResendOtpRequest request);
    void forgotPasswordWithOtp(ForgotPasswordRequest request);
    void resetPasswordWithOtp(ResetPasswordWithOtpRequest request);
}


