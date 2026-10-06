package com.techstore.repository;

import com.techstore.entity.CouponUsage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CouponUsageRepository extends JpaRepository<CouponUsage, Long> {
    List<CouponUsage> findByUserId(Long userId);
    List<CouponUsage> findByCouponId(Long couponId);
    boolean existsByCouponIdAndUserId(Long couponId, Long userId);
    long countByCouponIdAndUserId(Long couponId, Long userId);
}


