package com.techstore.repository;

import com.techstore.entity.Coupon;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CouponRepository extends JpaRepository<Coupon, Long>, JpaSpecificationExecutor<Coupon> {
    Optional<Coupon> findByCode(String code);
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select c from Coupon c where c.code = :code")
    Optional<Coupon> findByCodeWithLock(@org.springframework.data.repository.query.Param("code") String code);
    boolean existsByCode(String code);

    long countByIsActiveTrueAndEndDateAfter(java.time.LocalDateTime now);

    long countByEndDateBefore(java.time.LocalDateTime now);

    @org.springframework.data.jpa.repository.Query("select coalesce(sum(c.usedCount), 0) from Coupon c")
    long sumTotalUsed();

    @org.springframework.data.jpa.repository.Query("select c from Coupon c where c.isActive = true and c.startDate <= :now and c.endDate >= :now and c.usedCount < c.usageLimit order by c.createdAt desc")
    java.util.List<Coupon> findAvailableCoupons(@org.springframework.data.repository.query.Param("now") java.time.LocalDateTime now);
}


