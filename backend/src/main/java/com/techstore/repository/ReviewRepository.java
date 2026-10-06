package com.techstore.repository;

import com.techstore.entity.Review;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ReviewRepository extends JpaRepository<Review, Long>, JpaSpecificationExecutor<Review> {
    Page<Review> findByProductId(Long productId, Pageable pageable);
    Optional<Review> findByUserIdAndProductIdAndOrderId(Long userId, Long productId, Long orderId);
    boolean existsByUserIdAndProductIdAndOrderId(Long userId, Long productId, Long orderId);

    @Query("SELECT COALESCE(AVG(r.rating), 0.0) FROM Review r WHERE r.product.id = :productId")
    Double getAverageRatingByProductId(@Param("productId") Long productId);

    long countByProductId(Long productId);

    java.util.List<Review> findByUserIdOrderByCreatedAtDesc(Long userId);
    Page<Review> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);
    long countByUserId(Long userId);

    @Query("SELECT COALESCE(AVG(r.rating), 0.0) FROM Review r")
    Double getOverallAverageRating();

    @Query("SELECT r.rating, COUNT(r) FROM Review r GROUP BY r.rating")
    java.util.List<Object[]> countReviewsByRatingGroup();
}


