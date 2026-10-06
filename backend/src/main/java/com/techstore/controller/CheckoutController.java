package com.techstore.controller;

import com.techstore.exception.ResourceNotFoundException;
import com.techstore.exception.UnauthorizedException;
import com.techstore.dto.ApiResponse;
import com.techstore.dto.CheckoutRequest;
import com.techstore.dto.OrderResponseDto;
import com.techstore.service.CheckoutService;
import com.techstore.dto.CouponValidationRequest;
import com.techstore.dto.CouponValidationResponse;
import com.techstore.security.CustomUserDetails;
import com.techstore.entity.User;
import com.techstore.repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/checkout")
@RequiredArgsConstructor
public class CheckoutController {

    private final CheckoutService checkoutService;
    private final UserRepository userRepository;

    private User getAuthenticatedUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new UnauthorizedException("Vui lòng đăng nhập để tiến hành đặt hàng.");
        }

        if (authentication.getPrincipal() instanceof CustomUserDetails userDetails) {
            return userDetails.getUser();
        }

        String username = authentication.getName();
        return userRepository.findByEmail(username)
                .or(() -> userRepository.findByPhone(username))
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông tin tài khoản: " + username));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<OrderResponseDto>> checkout(@Valid @RequestBody CheckoutRequest request) {
        User user = getAuthenticatedUser();
        OrderResponseDto response = checkoutService.checkout(user, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Đặt hàng thành công", response));
    }

    @PostMapping("/validate-coupon")
    public ResponseEntity<ApiResponse<CouponValidationResponse>> validateCoupon(
            @Valid @RequestBody CouponValidationRequest request) {
        User user = getAuthenticatedUser();
        CouponValidationResponse response = checkoutService.validateCoupon(user, request);
        return ResponseEntity.ok(ApiResponse.ok("Kiểm tra mã giảm giá thành công", response));
    }
}


