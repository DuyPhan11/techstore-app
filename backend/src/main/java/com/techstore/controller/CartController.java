package com.techstore.controller;

import com.techstore.dto.AddToCartRequest;
import com.techstore.dto.CartDto;
import com.techstore.dto.UpdateCartItemRequest;
import com.techstore.service.CartService;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.exception.UnauthorizedException;
import com.techstore.dto.ApiResponse;
import com.techstore.security.CustomUserDetails;
import com.techstore.entity.User;
import com.techstore.repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/cart")
@RequiredArgsConstructor
public class CartController {

    private final CartService cartService;
    private final UserRepository userRepository;

    private User getAuthenticatedUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new UnauthorizedException("Vui lòng đăng nhập để thao tác giỏ hàng.");
        }

        if (authentication.getPrincipal() instanceof CustomUserDetails userDetails) {
            return userDetails.getUser();
        }

        String username = authentication.getName();
        return userRepository.findByEmail(username)
                .or(() -> userRepository.findByPhone(username))
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông tin tài khoản: " + username));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<CartDto>> getCart() {
        User user = getAuthenticatedUser();
        CartDto cart = cartService.getCartForUser(user);
        return ResponseEntity.ok(ApiResponse.ok("Lấy thông tin giỏ hàng thành công", cart));
    }

    @PostMapping("/items")
    public ResponseEntity<ApiResponse<CartDto>> addToCart(@Valid @RequestBody AddToCartRequest request) {
        User user = getAuthenticatedUser();
        CartDto cart = cartService.addToCart(user, request);
        return ResponseEntity.ok(ApiResponse.ok("Đã thêm sản phẩm vào giỏ hàng", cart));
    }

    @PutMapping("/items/{productId}")
    public ResponseEntity<ApiResponse<CartDto>> updateItemQuantity(
            @PathVariable Long productId,
            @Valid @RequestBody UpdateCartItemRequest request) {
        User user = getAuthenticatedUser();
        CartDto cart = cartService.updateItemQuantity(user, productId, request.getQuantity());
        return ResponseEntity.ok(ApiResponse.ok("Đã cập nhật số lượng sản phẩm", cart));
    }

    @DeleteMapping("/items/{productId}")
    public ResponseEntity<ApiResponse<CartDto>> removeItem(@PathVariable Long productId) {
        User user = getAuthenticatedUser();
        CartDto cart = cartService.removeItem(user, productId);
        return ResponseEntity.ok(ApiResponse.ok("Đã xóa sản phẩm khỏi giỏ hàng", cart));
    }

    @DeleteMapping
    public ResponseEntity<ApiResponse<Void>> clearCart() {
        User user = getAuthenticatedUser();
        cartService.clearCart(user);
        return ResponseEntity.ok(ApiResponse.ok("Đã làm trống giỏ hàng", null));
    }

    @DeleteMapping("/items")
    public ResponseEntity<ApiResponse<Void>> clearCartAlias() {
        User user = getAuthenticatedUser();
        cartService.clearCart(user);
        return ResponseEntity.ok(ApiResponse.ok("Đã làm trống giỏ hàng", null));
    }
}


