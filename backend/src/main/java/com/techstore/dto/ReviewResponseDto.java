package com.techstore.dto;

import com.techstore.entity.Review;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReviewResponseDto {

    private Long id;
    private Long productId;
    private String productName;
    private Long orderId;
    private String orderCode;
    private Long userId;
    private String userName;
    private String userAvatar;
    private String productImage;
    private java.math.BigDecimal unitPrice;
    private Integer rating;
    private String comment;
    private String adminReply;
    private LocalDateTime adminReplyAt;
    @com.fasterxml.jackson.annotation.JsonProperty("isOwner")
    private boolean isOwner;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static ReviewResponseDto fromEntity(Review review, Long currentUserId) {
        if (review == null) return null;

        boolean isUserOwner = currentUserId != null && review.getUser() != null && currentUserId.equals(review.getUser().getId());

        String resolvedImage = null;
        java.math.BigDecimal resolvedPrice = null;

        if (review.getOrder() != null && review.getOrder().getItems() != null && review.getProduct() != null) {
            for (com.techstore.entity.OrderItem item : review.getOrder().getItems()) {
                if (item.getProduct() != null && item.getProduct().getId().equals(review.getProduct().getId())) {
                    resolvedImage = item.getProductImage();
                    resolvedPrice = item.getUnitPrice();
                    break;
                }
            }
        }

        if (resolvedImage == null && review.getProduct() != null && review.getProduct().getImages() != null && !review.getProduct().getImages().isEmpty()) {
            resolvedImage = review.getProduct().getImages().stream()
                    .filter(img -> Boolean.TRUE.equals(img.getIsPrimary()))
                    .map(com.techstore.entity.ProductImage::getImageUrl)
                    .findFirst()
                    .orElse(review.getProduct().getImages().get(0).getImageUrl());
        }

        if (resolvedPrice == null && review.getProduct() != null) {
            resolvedPrice = review.getProduct().getPrice();
        }

        return ReviewResponseDto.builder()
                .id(review.getId())
                .productId(review.getProduct() != null ? review.getProduct().getId() : null)
                .productName(review.getProduct() != null ? review.getProduct().getName() : null)
                .productImage(resolvedImage)
                .unitPrice(resolvedPrice)
                .orderId(review.getOrder() != null ? review.getOrder().getId() : null)
                .orderCode(review.getOrder() != null ? review.getOrder().getOrderCode() : null)
                .userId(review.getUser() != null ? review.getUser().getId() : null)
                .userName(review.getUser() != null ? (review.getUser().getFullName() != null ? review.getUser().getFullName() : review.getUser().getEmail()) : "Ẩn danh")
                .userAvatar(review.getUser() != null ? review.getUser().getAvatarUrl() : null)
                .rating(review.getRating())
                .comment(review.getComment())
                .adminReply(review.getAdminReply())
                .adminReplyAt(review.getAdminReplyAt())
                .isOwner(isUserOwner)
                .createdAt(review.getCreatedAt())
                .updatedAt(review.getUpdatedAt())
                .build();
    }
}


