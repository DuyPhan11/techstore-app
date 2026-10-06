package com.techstore.controller;

import com.techstore.exception.ResourceNotFoundException;
import com.techstore.exception.UnauthorizedException;
import com.techstore.dto.ApiResponse;
import com.techstore.dto.*;
import com.techstore.service.ReviewService;
import com.techstore.security.CustomUserDetails;
import com.techstore.entity.User;
import com.techstore.repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;
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

    private User getOptionalUser() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null && authentication.isAuthenticated() && !"anonymousUser".equals(authentication.getPrincipal())) {
                if (authentication.getPrincipal() instanceof CustomUserDetails userDetails) {
                    return userDetails.getUser();
                }
                String username = authentication.getName();
                return userRepository.findByEmail(username).or(() -> userRepository.findByPhone(username)).orElse(null);
            }
        } catch (Exception ignored) {
        }
        return null;
    }

    @GetMapping("/products/{productId}/reviews")
    public ResponseEntity<ApiResponse<ProductRatingSummaryDto>> getProductReviews(
            @PathVariable Long productId,
            @PageableDefault(size = 10, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        User currentUser = getOptionalUser();
        ProductRatingSummaryDto response = reviewService.getProductReviews(productId, pageable, currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách đánh giá thành công", response));
    }

    @GetMapping("/products/{productId}/reviews/eligibility")
    public ResponseEntity<ApiResponse<ReviewEligibilityResponse>> checkEligibility(@PathVariable Long productId) {
        User user = getAuthenticatedUser();
        ReviewEligibilityResponse response = reviewService.checkReviewEligibility(user, productId);
        return ResponseEntity.ok(ApiResponse.ok("Kiểm tra điều kiện đánh giá thành công", response));
    }

    @PostMapping("/products/{productId}/reviews")
    public ResponseEntity<ApiResponse<ReviewResponseDto>> createReview(
            @PathVariable Long productId,
            @Valid @RequestBody CreateReviewRequest request) {
        User user = getAuthenticatedUser();
        ReviewResponseDto response = reviewService.createReview(user, productId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Đánh giá sản phẩm thành công", response));
    }

    @PutMapping("/reviews/{reviewId}")
    public ResponseEntity<ApiResponse<ReviewResponseDto>> updateReview(
            @PathVariable Long reviewId,
            @Valid @RequestBody UpdateReviewRequest request) {
        User user = getAuthenticatedUser();
        ReviewResponseDto response = reviewService.updateReview(user, reviewId, request);
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật đánh giá thành công", response));
    }

    @DeleteMapping("/reviews/{reviewId}")
    public ResponseEntity<ApiResponse<Void>> deleteReview(@PathVariable Long reviewId) {
        User user = getAuthenticatedUser();
        reviewService.deleteReview(user, reviewId);
        return ResponseEntity.ok(ApiResponse.ok("Xóa đánh giá thành công", null));
    }

    @GetMapping("/reviews/my/pending")
    public ResponseEntity<ApiResponse<java.util.List<PendingReviewItemDto>>> getMyPendingReviews() {
        User user = getAuthenticatedUser();
        java.util.List<PendingReviewItemDto> list = reviewService.getMyPendingReviews(user);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách chờ đánh giá thành công", list));
    }

    @GetMapping("/reviews/my")
    public ResponseEntity<ApiResponse<org.springframework.data.domain.Page<ReviewResponseDto>>> getMyReviews(
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        User user = getAuthenticatedUser();
        org.springframework.data.domain.Page<ReviewResponseDto> page = reviewService.getMyReviews(user, pageable);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách đánh giá của tôi thành công", page));
    }

    @GetMapping("/reviews/my/counts")
    public ResponseEntity<ApiResponse<java.util.Map<String, Long>>> getMyReviewCounts() {
        User user = getAuthenticatedUser();
        java.util.Map<String, Long> counts = reviewService.getMyReviewCounts(user);
        return ResponseEntity.ok(ApiResponse.ok("Lấy số lượng đánh giá thành công", counts));
    }

    @GetMapping("/admin/reviews")
    public ResponseEntity<ApiResponse<org.springframework.data.domain.Page<ReviewResponseDto>>> getAdminReviews(
            @RequestParam(required = false) Integer rating,
            @RequestParam(required = false) String search,
            @PageableDefault(size = 15, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        getAuthenticatedUser();
        org.springframework.data.domain.Page<ReviewResponseDto> page = reviewService.getAdminReviews(rating, search, pageable);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách đánh giá quản trị thành công", page));
    }

    @GetMapping("/admin/reviews/stats")
    public ResponseEntity<ApiResponse<AdminReviewStatsDto>> getAdminReviewStats() {
        getAuthenticatedUser();
        AdminReviewStatsDto stats = reviewService.getAdminReviewStats();
        return ResponseEntity.ok(ApiResponse.ok("Lấy thống kê đánh giá thành công", stats));
    }

    @PostMapping("/admin/reviews/{reviewId}/reply")
    public ResponseEntity<ApiResponse<ReviewResponseDto>> replyReview(
            @PathVariable Long reviewId,
            @Valid @RequestBody AdminReplyReviewRequest request) {
        getAuthenticatedUser();
        ReviewResponseDto response = reviewService.replyReview(reviewId, request);
        return ResponseEntity.ok(ApiResponse.ok("Phản hồi đánh giá thành công", response));
    }
}


