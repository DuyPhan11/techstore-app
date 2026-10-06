package com.techstore.service.impl;

import com.techstore.dto.*;
import com.techstore.entity.PasswordResetToken;
import com.techstore.repository.PasswordResetTokenRepository;
import com.techstore.service.AuthService;
import com.techstore.entity.Cart;
import com.techstore.repository.CartRepository;
import com.techstore.exception.BadRequestException;
import com.techstore.exception.ConflictException;
import com.techstore.exception.ForbiddenException;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.exception.UnauthorizedException;
import com.techstore.security.CustomUserDetails;
import com.techstore.security.JwtService;
import com.techstore.security.SecurityConstants;
import com.techstore.entity.Role;
import com.techstore.entity.User;
import com.techstore.enums.RoleName;
import com.techstore.enums.UserStatus;
import com.techstore.repository.RoleRepository;
import com.techstore.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.techstore.entity.VerificationCode;
import com.techstore.enums.VerificationType;
import com.techstore.repository.VerificationCodeRepository;
import com.techstore.service.EmailService;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final CartRepository cartRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final com.techstore.service.PasswordResetMailService passwordResetMailService;
    private final VerificationCodeRepository verificationCodeRepository;
    private final EmailService emailService;

    private String generate6DigitOtp() {
        java.util.concurrent.ThreadLocalRandom random = java.util.concurrent.ThreadLocalRandom.current();
        return String.format("%06d", random.nextInt(1000000));
    }

    @Override
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        String phone = request.getPhone() != null && !request.getPhone().isBlank() ? request.getPhone().trim() : null;

        Optional<User> existingUserOpt = userRepository.findByEmail(email);
        if (existingUserOpt.isPresent() && existingUserOpt.get().getStatus() == UserStatus.ACTIVE) {
            throw new ConflictException("Email đã được đăng ký bởi một tài khoản khác.");
        }

        if (phone != null) {
            Optional<User> phoneUserOpt = userRepository.findByPhone(phone);
            if (phoneUserOpt.isPresent()) {
                User pu = phoneUserOpt.get();
                if (existingUserOpt.isEmpty() || !pu.getId().equals(existingUserOpt.get().getId())) {
                    if (pu.getStatus() == UserStatus.ACTIVE) {
                        throw new ConflictException("Số điện thoại đã được đăng ký bởi tài khoản khác.");
                    }
                }
            }
        }

        Role customerRole = roleRepository.findByName(RoleName.ROLE_CUSTOMER)
                .orElseGet(() -> roleRepository.save(Role.builder().name(RoleName.ROLE_CUSTOMER).build()));

        User user;
        if (existingUserOpt.isPresent()) {
            user = existingUserOpt.get();
            user.setFullName(request.getFullName().trim());
            user.setPhone(phone);
            user.setPassword(passwordEncoder.encode(request.getPassword()));
            user.setStatus(UserStatus.PENDING_VERIFICATION);
        } else {
            user = User.builder()
                    .fullName(request.getFullName().trim())
                    .email(email)
                    .phone(phone)
                    .password(passwordEncoder.encode(request.getPassword()))
                    .status(UserStatus.PENDING_VERIFICATION)
                    .roles(Set.of(customerRole))
                    .build();
        }

        User savedUser = userRepository.save(user);

        // Sinh mã OTP 6 số và lưu vào bảng verification_codes
        verificationCodeRepository.deleteAllByEmailAndType(email, VerificationType.REGISTER);
        String otp = generate6DigitOtp();
        VerificationCode vc = VerificationCode.builder()
                .email(email)
                .code(otp)
                .type(VerificationType.REGISTER)
                .expiryDate(LocalDateTime.now().plusMinutes(10))
                .isUsed(false)
                .build();
        verificationCodeRepository.save(vc);

        // Gửi email HTML tới Gmail thật của người dùng
        emailService.sendRegistrationOtp(email, otp);

        return AuthResponse.builder()
                .token(null)
                .tokenType("PENDING_VERIFICATION")
                .expiresIn(0L)
                .user(mapToUserSummary(savedUser))
                .build();
    }

    @Override
    @Transactional
    public AuthResponse verifyEmail(VerifyOtpRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        String otp = request.getOtp().trim();

        VerificationCode vc = verificationCodeRepository.findFirstByEmailAndCodeAndTypeAndIsUsedFalseAndExpiryDateAfterOrderByCreatedAtDesc(
                email, otp, VerificationType.REGISTER, LocalDateTime.now()
        ).orElseThrow(() -> new BadRequestException("Mã OTP không hợp lệ hoặc đã hết hạn (chỉ có hiệu lực trong 10 phút)."));

        vc.setIsUsed(true);
        verificationCodeRepository.save(vc);

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông tin tài khoản cần xác thực."));

        user.setStatus(UserStatus.ACTIVE);
        User savedUser = userRepository.save(user);

        // Khởi tạo giỏ hàng rỗng nếu chưa có
        if (!cartRepository.existsByUserId(savedUser.getId())) {
            Cart cart = Cart.builder().user(savedUser).build();
            cartRepository.save(cart);
        }

        CustomUserDetails userDetails = new CustomUserDetails(savedUser);
        Map<String, Object> extraClaims = Map.of(
                "userId", savedUser.getId(),
                "fullName", savedUser.getFullName(),
                "roles", userDetails.getAuthorities().stream().map(Object::toString).collect(Collectors.toSet())
        );
        String token = jwtService.generateToken(userDetails, extraClaims);

        log.info("Xác thực email và kích hoạt tài khoản thành công: {}", email);

        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .expiresIn(SecurityConstants.EXPIRATION_TIME / 1000)
                .user(mapToUserSummary(savedUser))
                .build();
    }

    @Override
    @Transactional
    public void resendOtp(ResendOtpRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        VerificationType type = request.getType();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Email này chưa được đăng ký trong hệ thống."));

        if (type == VerificationType.REGISTER && user.getStatus() == UserStatus.ACTIVE) {
            throw new BadRequestException("Tài khoản này đã được kích hoạt trước đó, bạn có thể đăng nhập ngay.");
        }

        verificationCodeRepository.deleteAllByEmailAndType(email, type);
        String otp = generate6DigitOtp();
        VerificationCode vc = VerificationCode.builder()
                .email(email)
                .code(otp)
                .type(type)
                .expiryDate(LocalDateTime.now().plusMinutes(10))
                .isUsed(false)
                .build();
        verificationCodeRepository.save(vc);

        if (type == VerificationType.REGISTER) {
            emailService.sendRegistrationOtp(email, otp);
        } else {
            emailService.sendForgotPasswordOtp(email, otp);
        }
    }

    @Override
    @Transactional
    public void forgotPasswordWithOtp(ForgotPasswordRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null) {
            return;
        }

        if (user.getStatus() == UserStatus.LOCKED) {
            throw new ForbiddenException("Tài khoản của bạn đã bị khóa. Vui lòng liên hệ ban quản trị.");
        }

        verificationCodeRepository.deleteAllByEmailAndType(email, VerificationType.FORGOT_PASSWORD);
        String otp = generate6DigitOtp();
        VerificationCode vc = VerificationCode.builder()
                .email(email)
                .code(otp)
                .type(VerificationType.FORGOT_PASSWORD)
                .expiryDate(LocalDateTime.now().plusMinutes(10))
                .isUsed(false)
                .build();
        verificationCodeRepository.save(vc);

        emailService.sendForgotPasswordOtp(email, otp);
    }

    @Override
    @Transactional
    public void resetPasswordWithOtp(ResetPasswordWithOtpRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        String otp = request.getOtp().trim();

        VerificationCode vc = verificationCodeRepository.findFirstByEmailAndCodeAndTypeAndIsUsedFalseAndExpiryDateAfterOrderByCreatedAtDesc(
                email, otp, VerificationType.FORGOT_PASSWORD, LocalDateTime.now()
        ).orElseThrow(() -> new BadRequestException("Mã OTP không hợp lệ hoặc đã hết hạn (chỉ có hiệu lực trong 10 phút)."));

        vc.setIsUsed(true);
        verificationCodeRepository.save(vc);

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông tin tài khoản."));

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        log.info("Đặt lại mật khẩu thành công qua mã OTP cho email: {}", email);
    }

    @Override
    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        if (request.getUsername() == null || request.getUsername().isBlank()) {
            throw new BadRequestException("Tài khoản (Email hoặc SĐT) không được để trống.");
        }
        String username = request.getUsername().trim();

        User user = userRepository.findByEmail(username)
                .or(() -> userRepository.findByPhone(username))
                .orElseThrow(() -> new UnauthorizedException("Email/SĐT hoặc mật khẩu không chính xác."));

        if (user.getStatus() == UserStatus.PENDING_VERIFICATION) {
            throw new ForbiddenException("Tài khoản chưa được kích hoạt. Vui lòng xác thực mã OTP được gửi về Gmail của bạn.");
        }

        if (user.getStatus() == UserStatus.LOCKED) {
            throw new ForbiddenException("Tài khoản của bạn đã bị khóa. Vui lòng liên hệ ban quản trị.");
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new UnauthorizedException("Email/SĐT hoặc mật khẩu không chính xác.");
        }

        CustomUserDetails userDetails = new CustomUserDetails(user);
        Map<String, Object> extraClaims = Map.of(
                "userId", user.getId(),
                "fullName", user.getFullName(),
                "roles", userDetails.getAuthorities().stream().map(Object::toString).collect(Collectors.toSet())
        );
        String token = jwtService.generateToken(userDetails, extraClaims);

        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .expiresIn(SecurityConstants.EXPIRATION_TIME / 1000)
                .user(mapToUserSummary(user))
                .build();
    }

    @Override
    @Transactional
    public AuthResponse loginWithGoogle(GoogleLoginRequest request) {
        if (request.getIdToken() == null || request.getIdToken().isBlank()) {
            throw new BadRequestException("ID Token của Google không được để trống.");
        }

        GoogleUserInfo googleUser = verifyGoogleOrFirebaseToken(request.getIdToken());
        if (googleUser == null || googleUser.getEmail() == null || googleUser.getEmail().isBlank()) {
            throw new UnauthorizedException("Xác thực tài khoản Google thất bại. Token không hợp lệ hoặc đã hết hạn.");
        }

        String email = googleUser.getEmail().trim().toLowerCase();
        User user = userRepository.findByEmail(email).orElse(null);

        if (user == null) {
            Role customerRole = roleRepository.findByName(RoleName.ROLE_CUSTOMER)
                    .orElseGet(() -> roleRepository.save(Role.builder().name(RoleName.ROLE_CUSTOMER).build()));

            String fullName = googleUser.getName();
            if (fullName == null || fullName.isBlank()) {
                fullName = email.split("@")[0];
            }

            user = User.builder()
                    .fullName(fullName)
                    .email(email)
                    .avatarUrl(googleUser.getPicture())
                    .status(UserStatus.ACTIVE)
                    .roles(Set.of(customerRole))
                    .build();

            user = userRepository.save(user);

            // Automatically initialize empty cart for customer
            Cart cart = Cart.builder()
                    .user(user)
                    .build();
            cartRepository.save(cart);
            log.info("Đã tạo mới tài khoản người dùng qua Google: {}", email);
        } else {
            if (user.getStatus() == UserStatus.LOCKED) {
                throw new ForbiddenException("Tài khoản của bạn đã bị khóa. Vui lòng liên hệ ban quản trị.");
            }
            if (user.getAvatarUrl() == null && googleUser.getPicture() != null) {
                user.setAvatarUrl(googleUser.getPicture());
                userRepository.save(user);
            }
            log.info("Người dùng đăng nhập thành công qua Google: {}", email);
        }

        CustomUserDetails userDetails = new CustomUserDetails(user);
        Map<String, Object> extraClaims = Map.of(
                "userId", user.getId(),
                "fullName", user.getFullName(),
                "roles", userDetails.getAuthorities().stream().map(Object::toString).collect(Collectors.toSet())
        );
        String token = jwtService.generateToken(userDetails, extraClaims);

        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .expiresIn(SecurityConstants.EXPIRATION_TIME / 1000)
                .user(mapToUserSummary(user))
                .build();
    }

    @lombok.Data
    @lombok.Builder
    private static class GoogleUserInfo {
        private String email;
        private String name;
        private String picture;
    }

    private GoogleUserInfo verifyGoogleOrFirebaseToken(String idToken) {
        org.springframework.web.client.RestTemplate restTemplate = new org.springframework.web.client.RestTemplate();

        // 1. Check with Google tokeninfo endpoint
        try {
            String url = "https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken;
            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.getForObject(url, Map.class);
            if (response != null && response.containsKey("email")) {
                return GoogleUserInfo.builder()
                        .email((String) response.get("email"))
                        .name((String) response.get("name"))
                        .picture((String) response.get("picture"))
                        .build();
            }
        } catch (Exception e) {
            log.debug("Google tokeninfo check failed, falling back to Firebase accounts lookup: {}", e.getMessage());
        }

        // 2. Check with Firebase Account Lookup
        try {
            String firebaseLookupUrl = "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=AIzaSyA6AjmoGJyDGPm49O_jvqW4mdVqQDGyQP8";
            Map<String, String> body = Map.of("idToken", idToken);
            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.postForObject(firebaseLookupUrl, body, Map.class);
            if (response != null && response.containsKey("users")) {
                @SuppressWarnings("unchecked")
                java.util.List<Map<String, Object>> users = (java.util.List<Map<String, Object>>) response.get("users");
                if (users != null && !users.isEmpty()) {
                    Map<String, Object> u = users.get(0);
                    return GoogleUserInfo.builder()
                            .email((String) u.get("email"))
                            .name((String) u.get("displayName"))
                            .picture((String) u.get("photoUrl"))
                            .build();
                }
            }
        } catch (Exception e) {
            log.error("Firebase token verification failed: {}", e.getMessage());
        }

        return null;
    }

    @Override
    @Transactional
    public void forgotPassword(ForgotPasswordRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null) return;

        // Invalidate previous unused reset tokens
        passwordResetTokenRepository.deleteByUserId(user.getId());

        String resetToken = UUID.randomUUID().toString();
        PasswordResetToken tokenEntity = PasswordResetToken.builder()
                .user(user)
                .token(resetToken)
                .expiryDate(LocalDateTime.now().plusMinutes(15))
                .isUsed(false)
                .build();

        passwordResetTokenRepository.save(tokenEntity);
        passwordResetMailService.send(email, resetToken);
    }

    @Override
    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        PasswordResetToken tokenEntity = passwordResetTokenRepository.findByToken(request.getToken())
                .orElseThrow(() -> new BadRequestException("Mã xác thực không hợp lệ hoặc không tồn tại."));

        if (Boolean.TRUE.equals(tokenEntity.getIsUsed())) {
            throw new BadRequestException("Mã xác thực này đã được sử dụng trước đó.");
        }

        if (tokenEntity.getExpiryDate().isBefore(LocalDateTime.now())) {
            throw new BadRequestException("Mã xác thực đã hết hạn (chỉ có hiệu lực trong 15 phút).");
        }

        User user = tokenEntity.getUser();
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        tokenEntity.setIsUsed(true);
        passwordResetTokenRepository.save(tokenEntity);
        log.info("Password successfully reset for user {}", user.getEmail());
    }

    @Override
    @Transactional(readOnly = true)
    public UserSummaryDto getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new UnauthorizedException("Chưa đăng nhập.");
        }

        String username = authentication.getName();
        User user = userRepository.findByEmail(username)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông tin người dùng."));

        return mapToUserSummary(user);
    }

    @Override
    @Transactional
    public UserSummaryDto updateProfile(UpdateProfileRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new UnauthorizedException("Chưa đăng nhập.");
        }

        String username = authentication.getName();
        User user = userRepository.findByEmail(username)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông tin người dùng."));

        // 1. Cập nhật họ và tên
        if (request.getFullName() != null && !request.getFullName().isBlank()) {
            user.setFullName(request.getFullName().trim());
        }

        // 2. Cập nhật số điện thoại
        String newPhone = request.getPhone() != null ? request.getPhone().trim() : null;
        if (newPhone != null && !newPhone.isBlank()) {
            if (!newPhone.equals(user.getPhone())) {
                java.util.Optional<User> existingUser = userRepository.findByPhone(newPhone);
                if (existingUser.isPresent() && !existingUser.get().getId().equals(user.getId())) {
                    throw new ConflictException("Số điện thoại này đã được sử dụng bởi một tài khoản khác.");
                }
                user.setPhone(newPhone);
            }
        } else if (request.getPhone() != null && request.getPhone().isBlank()) {
            user.setPhone(null);
        }

        // 3. Cập nhật ảnh đại diện (avatar)
        if (request.getAvatarUrl() != null) {
            user.setAvatarUrl(request.getAvatarUrl().trim().isEmpty() ? null : request.getAvatarUrl().trim());
        }

        // 4. Đổi mật khẩu nếu khách hàng có yêu cầu
        if (request.getNewPassword() != null && !request.getNewPassword().isBlank()) {
            if (user.getPassword() != null && !user.getPassword().isBlank()) {
                if (request.getCurrentPassword() == null || request.getCurrentPassword().isBlank()) {
                    throw new BadRequestException("Vui lòng nhập mật khẩu hiện tại để xác nhận đổi mật khẩu.");
                }
                if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
                    throw new BadRequestException("Mật khẩu hiện tại không chính xác.");
                }
            }
            user.setPassword(passwordEncoder.encode(request.getNewPassword()));
            log.info("Người dùng {} đã thay đổi mật khẩu thành công", user.getEmail());
        }

        User updatedUser = userRepository.save(user);
        log.info("Cập nhật thông tin cá nhân thành công cho người dùng: {}", user.getEmail());
        return mapToUserSummary(updatedUser);
    }

    private UserSummaryDto mapToUserSummary(User user) {
        Set<String> roleNames = user.getRoles().stream()
                .map(r -> r.getName().name())
                .collect(Collectors.toSet());

        return UserSummaryDto.builder()
                .id(user.getId())
                .email(user.getEmail())
                .phone(user.getPhone())
                .fullName(user.getFullName())
                .avatarUrl(user.getAvatarUrl())
                .roles(roleNames)
                .build();
    }
}


