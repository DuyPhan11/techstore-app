package com.techstore.service.impl;

import com.techstore.exception.BadRequestException;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.entity.Order;
import com.techstore.repository.OrderRepository;
import com.techstore.entity.Product;
import com.techstore.repository.ProductRepository;
import com.techstore.dto.*;
import com.techstore.entity.Review;
import com.techstore.repository.ReviewRepository;
import com.techstore.service.ReviewService;
import com.techstore.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class ReviewServiceImpl implements ReviewService {

    private final ReviewRepository reviewRepository;
    private final ProductRepository productRepository;
    private final OrderRepository orderRepository;

    @Override
    @Transactional
    public ReviewResponseDto createReview(User user, Long productId, CreateReviewRequest request) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm với ID: " + productId));

        List<Order> completedOrders = orderRepository.findCompletedOrdersByUserAndProduct(user.getId(), productId);
        if (completedOrders.isEmpty()) {
            throw new BadRequestException("Bạn chỉ có thể đánh giá sản phẩm này sau khi đã mua và đơn hàng ở trạng thái HOÀN THÀNH (COMPLETED).");
        }

        Order eligibleOrder;
        if (request.getOrderId() != null) {
            eligibleOrder = completedOrders.stream()
                    .filter(o -> o.getId().equals(request.getOrderId()))
                    .findFirst()
                    .orElseThrow(() -> new BadRequestException("Đơn hàng chỉ định không hợp lệ hoặc chưa hoàn thành đối với sản phẩm này."));

            if (reviewRepository.existsByUserIdAndProductIdAndOrderId(user.getId(), productId, eligibleOrder.getId())) {
                throw new BadRequestException("Bạn đã đánh giá sản phẩm này cho đơn hàng #" + eligibleOrder.getOrderCode() + " rồi.");
            }
        } else {
            eligibleOrder = completedOrders.stream()
                    .filter(o -> !reviewRepository.existsByUserIdAndProductIdAndOrderId(user.getId(), productId, o.getId()))
                    .findFirst()
                    .orElseThrow(() -> new BadRequestException("Bạn đã đánh giá sản phẩm này cho tất cả các đơn hàng đã mua."));
        }

        Review review = Review.builder()
                .user(user)
                .product(product)
                .order(eligibleOrder)
                .rating(request.getRating())
                .comment(request.getComment().trim())
                .build();

        Review savedReview = reviewRepository.save(review);
        log.info("User {} reviewed product {} with rating {} on order {}",
                user.getEmail(), productId, request.getRating(), eligibleOrder.getOrderCode());

        return ReviewResponseDto.fromEntity(savedReview, user.getId());
    }

    @Override
    @Transactional
    public ReviewResponseDto updateReview(User user, Long reviewId, UpdateReviewRequest request) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đánh giá với ID: " + reviewId));

        if (!review.getUser().getId().equals(user.getId())) {
            throw new com.techstore.exception.ForbiddenException("Bạn không có quyền chỉnh sửa đánh giá này.");
        }

        review.setRating(request.getRating());
        review.setComment(request.getComment().trim());

        Review updatedReview = reviewRepository.save(review);
        log.info("User {} updated review ID {}", user.getEmail(), reviewId);

        return ReviewResponseDto.fromEntity(updatedReview, user.getId());
    }

    @Override
    @Transactional
    public void deleteReview(User user, Long reviewId) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đánh giá với ID: " + reviewId));

        boolean isOwner = review.getUser().getId().equals(user.getId());
        boolean isAdmin = user.getRoles() != null && user.getRoles().stream()
                .anyMatch(r -> r.getName() == com.techstore.enums.RoleName.ROLE_ADMIN || "ROLE_ADMIN".equals(r.getName().name()));

        if (!isOwner && !isAdmin) {
            throw new com.techstore.exception.ForbiddenException("Bạn không có quyền xóa đánh giá này.");
        }

        reviewRepository.delete(review);
        log.info("Review ID {} deleted by user {} (isAdmin={})", reviewId, user.getEmail(), isAdmin);
    }

    @Override
    @Transactional(readOnly = true)
    public ProductRatingSummaryDto getProductReviews(Long productId, Pageable pageable, User currentUser) {
        if (!productRepository.existsById(productId)) {
            throw new ResourceNotFoundException("Không tìm thấy sản phẩm với ID: " + productId);
        }

        Double avg = reviewRepository.getAverageRatingByProductId(productId);
        long total = reviewRepository.countByProductId(productId);
        Long currentUserId = currentUser != null ? currentUser.getId() : null;

        Page<ReviewResponseDto> page = reviewRepository.findByProductId(productId, pageable)
                .map(r -> ReviewResponseDto.fromEntity(r, currentUserId));

        double roundedAvg = (avg != null && !avg.isNaN()) ? (Math.round(avg * 10.0) / 10.0) : 0.0;

        return ProductRatingSummaryDto.builder()
                .averageRating(roundedAvg)
                .totalReviews(total)
                .reviews(page)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public ReviewEligibilityResponse checkReviewEligibility(User user, Long productId) {
        if (!productRepository.existsById(productId)) {
            throw new ResourceNotFoundException("Không tìm thấy sản phẩm với ID: " + productId);
        }

        List<Order> completedOrders = orderRepository.findCompletedOrdersByUserAndProduct(user.getId(), productId);
        if (completedOrders.isEmpty()) {
            return ReviewEligibilityResponse.builder()
                    .eligible(false)
                    .reason("Bạn chỉ có thể đánh giá sản phẩm sau khi đã mua và đơn hàng ở trạng thái HOÀN THÀNH (COMPLETED).")
                    .build();
        }

        Optional<Order> unreviewedOrder = completedOrders.stream()
                .filter(o -> !reviewRepository.existsByUserIdAndProductIdAndOrderId(user.getId(), productId, o.getId()))
                .findFirst();

        if (unreviewedOrder.isPresent()) {
            Order o = unreviewedOrder.get();
            return ReviewEligibilityResponse.builder()
                    .eligible(true)
                    .orderId(o.getId())
                    .orderCode(o.getOrderCode())
                    .reason("Đủ điều kiện đánh giá")
                    .build();
        }

        return ReviewEligibilityResponse.builder()
                .eligible(false)
                .reason("Bạn đã đánh giá sản phẩm này cho tất cả các đơn hàng đã mua.")
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public List<PendingReviewItemDto> getMyPendingReviews(User user) {
        List<Order> completedOrders = orderRepository.findByUserIdAndStatusOrderByCreatedAtDesc(user.getId(), com.techstore.enums.OrderStatus.COMPLETED);
        List<PendingReviewItemDto> pendingList = new java.util.ArrayList<>();

        for (Order order : completedOrders) {
            if (order.getItems() != null) {
                for (com.techstore.entity.OrderItem item : order.getItems()) {
                    if (item.getProduct() != null) {
                        Long productId = item.getProduct().getId();
                        boolean alreadyReviewed = reviewRepository.existsByUserIdAndProductIdAndOrderId(user.getId(), productId, order.getId());
                        if (!alreadyReviewed) {
                            pendingList.add(PendingReviewItemDto.builder()
                                    .orderId(order.getId())
                                    .orderCode(order.getOrderCode())
                                    .orderDate(order.getCreatedAt())
                                    .productId(productId)
                                    .productName(item.getProductName())
                                    .productSku(item.getProductSku())
                                    .productImage(item.getProductImage())
                                    .unitPrice(item.getUnitPrice())
                                    .quantity(item.getQuantity())
                                    .build());
                        }
                    }
                }
            }
        }
        return pendingList;
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ReviewResponseDto> getMyReviews(User user, Pageable pageable) {
        return reviewRepository.findByUserIdOrderByCreatedAtDesc(user.getId(), pageable)
                .map(r -> ReviewResponseDto.fromEntity(r, user.getId()));
    }

    @Override
    @Transactional(readOnly = true)
    public java.util.Map<String, Long> getMyReviewCounts(User user) {
        long pendingCount = getMyPendingReviews(user).size();
        long reviewedCount = reviewRepository.countByUserId(user.getId());
        java.util.Map<String, Long> counts = new java.util.HashMap<>();
        counts.put("pendingCount", pendingCount);
        counts.put("reviewedCount", reviewedCount);
        return counts;
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ReviewResponseDto> getAdminReviews(Integer rating, String search, Pageable pageable) {
        org.springframework.data.jpa.domain.Specification<Review> spec = (root, query, cb) -> {
            java.util.List<jakarta.persistence.criteria.Predicate> predicates = new java.util.ArrayList<>();

            if (rating != null && rating > 0) {
                predicates.add(cb.equal(root.get("rating"), rating));
            }

            if (search != null && !search.isBlank()) {
                String searchPattern = "%" + search.trim().toLowerCase() + "%";
                jakarta.persistence.criteria.Join<Review, Product> productJoin = root.join("product", jakarta.persistence.criteria.JoinType.LEFT);
                jakarta.persistence.criteria.Join<Review, User> userJoin = root.join("user", jakarta.persistence.criteria.JoinType.LEFT);
                jakarta.persistence.criteria.Join<Review, Order> orderJoin = root.join("order", jakarta.persistence.criteria.JoinType.LEFT);

                jakarta.persistence.criteria.Predicate commentMatch = cb.like(cb.lower(root.get("comment")), searchPattern);
                jakarta.persistence.criteria.Predicate productNameMatch = cb.like(cb.lower(productJoin.get("name")), searchPattern);
                jakarta.persistence.criteria.Predicate userNameMatch = cb.like(cb.lower(userJoin.get("fullName")), searchPattern);
                jakarta.persistence.criteria.Predicate userEmailMatch = cb.like(cb.lower(userJoin.get("email")), searchPattern);
                jakarta.persistence.criteria.Predicate orderCodeMatch = cb.like(cb.lower(orderJoin.get("orderCode")), searchPattern);

                predicates.add(cb.or(commentMatch, productNameMatch, userNameMatch, userEmailMatch, orderCodeMatch));
            }

            return cb.and(predicates.toArray(new jakarta.persistence.criteria.Predicate[0]));
        };

        return reviewRepository.findAll(spec, pageable)
                .map(r -> ReviewResponseDto.fromEntity(r, null));
    }

    @Override
    @Transactional(readOnly = true)
    public AdminReviewStatsDto getAdminReviewStats() {
        Double avg = reviewRepository.getOverallAverageRating();
        long total = reviewRepository.count();

        long c1 = 0, c2 = 0, c3 = 0, c4 = 0, c5 = 0;
        java.util.List<Object[]> groups = reviewRepository.countReviewsByRatingGroup();
        for (Object[] g : groups) {
            if (g[0] != null && g[1] != null) {
                int r = ((Number) g[0]).intValue();
                long count = ((Number) g[1]).longValue();
                switch (r) {
                    case 1 -> c1 = count;
                    case 2 -> c2 = count;
                    case 3 -> c3 = count;
                    case 4 -> c4 = count;
                    case 5 -> c5 = count;
                }
            }
        }

        double roundedAvg = (avg != null && !avg.isNaN()) ? (Math.round(avg * 10.0) / 10.0) : 0.0;

        return AdminReviewStatsDto.builder()
                .averageRating(roundedAvg)
                .totalReviews(total)
                .count1Star(c1)
                .count2Star(c2)
                .count3Star(c3)
                .count4Star(c4)
                .count5Star(c5)
                .build();
    }

    @Override
    @Transactional
    public ReviewResponseDto replyReview(Long reviewId, AdminReplyReviewRequest request) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đánh giá với ID: " + reviewId));

        review.setAdminReply(request.getReply().trim());
        review.setAdminReplyAt(java.time.LocalDateTime.now());
        Review saved = reviewRepository.save(review);
        log.info("Admin replied to review ID {}: {}", reviewId, request.getReply().trim());

        return ReviewResponseDto.fromEntity(saved, null);
    }
}


