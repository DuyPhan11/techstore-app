package com.techstore.service;

import com.techstore.dto.*;
import com.techstore.entity.User;
import org.springframework.data.domain.Pageable;

public interface ReviewService {

    ReviewResponseDto createReview(User user, Long productId, CreateReviewRequest request);

    ReviewResponseDto updateReview(User user, Long reviewId, UpdateReviewRequest request);

    void deleteReview(User user, Long reviewId);

    ProductRatingSummaryDto getProductReviews(Long productId, Pageable pageable, User currentUser);

    ReviewEligibilityResponse checkReviewEligibility(User user, Long productId);

    java.util.List<PendingReviewItemDto> getMyPendingReviews(User user);

    org.springframework.data.domain.Page<ReviewResponseDto> getMyReviews(User user, Pageable pageable);

    java.util.Map<String, Long> getMyReviewCounts(User user);

    org.springframework.data.domain.Page<ReviewResponseDto> getAdminReviews(Integer rating, String search, Pageable pageable);

    AdminReviewStatsDto getAdminReviewStats();

    ReviewResponseDto replyReview(Long reviewId, AdminReplyReviewRequest request);
}


