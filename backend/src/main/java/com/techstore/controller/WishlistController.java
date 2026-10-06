package com.techstore.controller;

import com.techstore.dto.ApiResponse;
import com.techstore.dto.ProductSummaryDto;
import com.techstore.entity.User;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.exception.UnauthorizedException;
import com.techstore.repository.UserRepository;
import com.techstore.security.CustomUserDetails;
import com.techstore.service.WishlistService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/wishlist")
@RequiredArgsConstructor
public class WishlistController {

    private final WishlistService wishlistService;
    private final UserRepository userRepository;

    private User getAuthenticatedUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new UnauthorizedException("Vui lòng đăng nhập để thao tác với danh sách yêu thích.");
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
    public ResponseEntity<ApiResponse<List<ProductSummaryDto>>> getWishlist() {
        User user = getAuthenticatedUser();
        List<ProductSummaryDto> products = wishlistService.getWishlistProducts(user);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách yêu thích thành công", products));
    }

    @GetMapping("/ids")
    public ResponseEntity<ApiResponse<List<Long>>> getWishlistIds() {
        User user = getAuthenticatedUser();
        List<Long> ids = wishlistService.getWishlistProductIds(user);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách ID yêu thích thành công", ids));
    }

    @PostMapping("/{productId}")
    public ResponseEntity<ApiResponse<Void>> addToWishlist(@PathVariable Long productId) {
        User user = getAuthenticatedUser();
        wishlistService.addToWishlist(user, productId);
        return ResponseEntity.ok(ApiResponse.ok("Đã thêm sản phẩm vào danh sách yêu thích", null));
    }

    @DeleteMapping("/{productId}")
    public ResponseEntity<ApiResponse<Void>> removeFromWishlist(@PathVariable Long productId) {
        User user = getAuthenticatedUser();
        wishlistService.removeFromWishlist(user, productId);
        return ResponseEntity.ok(ApiResponse.ok("Đã xóa sản phẩm khỏi danh sách yêu thích", null));
    }

    @PostMapping("/toggle/{productId}")
    public ResponseEntity<ApiResponse<Boolean>> toggleWishlist(@PathVariable Long productId) {
        User user = getAuthenticatedUser();
        boolean isAdded = wishlistService.toggleWishlist(user, productId);
        String message = isAdded ? "Đã thêm vào danh sách yêu thích" : "Đã bỏ yêu thích";
        return ResponseEntity.ok(ApiResponse.ok(message, isAdded));
    }
}
