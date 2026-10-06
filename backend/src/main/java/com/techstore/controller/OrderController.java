package com.techstore.controller;

import com.techstore.exception.ResourceNotFoundException;
import com.techstore.exception.UnauthorizedException;
import com.techstore.dto.ApiResponse;
import com.techstore.dto.CancelOrderRequest;
import com.techstore.dto.OrderResponseDto;
import com.techstore.service.OrderService;
import com.techstore.security.CustomUserDetails;
import com.techstore.entity.User;
import com.techstore.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;
    private final UserRepository userRepository;

    private User getAuthenticatedUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new UnauthorizedException("Vui lòng đăng nhập để thực hiện thao tác này.");
        }

        if (authentication.getPrincipal() instanceof CustomUserDetails userDetails) {
            return userDetails.getUser();
        }

        String username = authentication.getName();
        return userRepository.findByEmail(username)
                .or(() -> userRepository.findByPhone(username))
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông tin tài khoản: " + username));
    }

    @GetMapping("/my")
    public ResponseEntity<ApiResponse<Page<OrderResponseDto>>> getMyOrders(
            @PageableDefault(size = 10, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        User user = getAuthenticatedUser();
        Page<OrderResponseDto> response = orderService.getMyOrders(user, pageable);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách đơn hàng thành công", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<OrderResponseDto>> getOrderDetail(@PathVariable Long id) {
        User user = getAuthenticatedUser();
        OrderResponseDto response = orderService.getOrderDetail(user, id);
        return ResponseEntity.ok(ApiResponse.ok("Lấy chi tiết đơn hàng thành công", response));
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<OrderResponseDto>> cancelOrder(
            @PathVariable Long id,
            @RequestBody(required = false) CancelOrderRequest request) {
        User user = getAuthenticatedUser();
        OrderResponseDto response = orderService.cancelOrder(user, id, request);
        return ResponseEntity.ok(ApiResponse.ok("Hủy đơn hàng thành công", response));
    }

    @PostMapping("/{id}/return-request")
    public ResponseEntity<ApiResponse<OrderResponseDto>> requestReturn(
            @PathVariable Long id,
            @jakarta.validation.Valid @RequestBody com.techstore.dto.ReturnRequestDto request) {
        User user = getAuthenticatedUser();
        OrderResponseDto response = orderService.requestReturn(user, id, request);
        return ResponseEntity.ok(ApiResponse.ok("Gửi yêu cầu đổi trả thành công", response));
    }
}


