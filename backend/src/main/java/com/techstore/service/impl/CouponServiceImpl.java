package com.techstore.service.impl;

import com.techstore.exception.BadRequestException;
import com.techstore.exception.ConflictException;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.dto.*;
import com.techstore.entity.Coupon;
import com.techstore.enums.DiscountType;
import com.techstore.repository.CouponRepository;
import com.techstore.service.CouponService;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class CouponServiceImpl implements CouponService {

    private final CouponRepository couponRepository;

    @Override
    @Transactional(readOnly = true)
    public Page<CouponResponseDto> getCoupons(CouponFilterParams filter, Pageable pageable) {
        Specification<Coupon> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (filter != null) {
                if (filter.getSearch() != null && !filter.getSearch().trim().isEmpty()) {
                    predicates.add(cb.like(cb.upper(root.get("code")), "%" + filter.getSearch().trim().toUpperCase() + "%"));
                }
                if (filter.getDiscountType() != null) {
                    predicates.add(cb.equal(root.get("discountType"), filter.getDiscountType()));
                }
                if (filter.getIsActive() != null) {
                    predicates.add(cb.equal(root.get("isActive"), filter.getIsActive()));
                }
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return couponRepository.findAll(spec, pageable).map(CouponResponseDto::fromEntity);
    }

    @Override
    @Transactional(readOnly = true)
    public CouponResponseDto getCouponById(Long id) {
        Coupon coupon = couponRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy mã giảm giá với ID: " + id));
        return CouponResponseDto.fromEntity(coupon);
    }

    @Override
    @Transactional
    public CouponResponseDto createCoupon(CreateCouponRequest request) {
        String code = request.getCode().trim().toUpperCase();

        if (couponRepository.existsByCode(code)) {
            throw new ConflictException("Mã giảm giá '" + code + "' đã tồn tại trong hệ thống.");
        }

        validateCouponBusinessRules(request.getDiscountType(), request.getDiscountValue(),
                request.getStartDate(), request.getEndDate(), request.getMinOrderAmount(), request.getMaxDiscountAmount());

        BigDecimal minOrder = request.getMinOrderAmount() != null ? request.getMinOrderAmount() : BigDecimal.ZERO;

        Coupon coupon = Coupon.builder()
                .code(code)
                .discountType(request.getDiscountType())
                .discountValue(request.getDiscountValue())
                .minOrderAmount(minOrder)
                .maxDiscountAmount(request.getMaxDiscountAmount())
                .usageLimit(request.getUsageLimit())
                .usedCount(0)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .isActive(request.getIsActive() != null ? request.getIsActive() : true)
                .build();

        Coupon saved = couponRepository.save(coupon);
        log.info("Coupon created successfully: code={}", saved.getCode());
        return CouponResponseDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public CouponResponseDto updateCoupon(Long id, UpdateCouponRequest request) {
        Coupon coupon = couponRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy mã giảm giá với ID: " + id));

        validateCouponBusinessRules(request.getDiscountType(), request.getDiscountValue(),
                request.getStartDate(), request.getEndDate(), request.getMinOrderAmount(), request.getMaxDiscountAmount());

        BigDecimal minOrder = request.getMinOrderAmount() != null ? request.getMinOrderAmount() : BigDecimal.ZERO;

        coupon.setDiscountType(request.getDiscountType());
        coupon.setDiscountValue(request.getDiscountValue());
        coupon.setMinOrderAmount(minOrder);
        coupon.setMaxDiscountAmount(request.getMaxDiscountAmount());
        coupon.setUsageLimit(request.getUsageLimit());
        coupon.setStartDate(request.getStartDate());
        coupon.setEndDate(request.getEndDate());
        if (request.getIsActive() != null) {
            coupon.setIsActive(request.getIsActive());
        }

        Coupon saved = couponRepository.save(coupon);
        log.info("Coupon updated successfully: code={}", saved.getCode());
        return CouponResponseDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public CouponResponseDto toggleCouponStatus(Long id, boolean active) {
        Coupon coupon = couponRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy mã giảm giá với ID: " + id));

        coupon.setIsActive(active);
        Coupon saved = couponRepository.save(coupon);
        log.info("Coupon status toggled: code={}, active={}", saved.getCode(), active);
        return CouponResponseDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public void deleteCoupon(Long id) {
        Coupon coupon = couponRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy mã giảm giá với ID: " + id));

        couponRepository.delete(coupon);
        log.info("Coupon deleted: code={}", coupon.getCode());
    }

    @Override
    @Transactional(readOnly = true)
    public AdminCouponStatsDto getAdminCouponStats() {
        java.time.LocalDateTime now = java.time.LocalDateTime.now();
        long total = couponRepository.count();
        long active = couponRepository.countByIsActiveTrueAndEndDateAfter(now);
        long expired = couponRepository.countByEndDateBefore(now);
        long totalUsed = couponRepository.sumTotalUsed();

        return AdminCouponStatsDto.builder()
                .totalCoupons(total)
                .activeCoupons(active)
                .expiredCoupons(expired)
                .totalUsed(totalUsed)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public List<CouponResponseDto> getAvailableCoupons() {
        java.time.LocalDateTime now = java.time.LocalDateTime.now();
        return couponRepository.findAvailableCoupons(now)
                .stream()
                .map(CouponResponseDto::fromEntity)
                .toList();
    }

    private void validateCouponBusinessRules(DiscountType type, BigDecimal value,
                                             java.time.LocalDateTime start, java.time.LocalDateTime end,
                                             BigDecimal minOrder, BigDecimal maxDiscount) {
        if (value.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BadRequestException("Giá trị giảm giá phải lớn hơn 0");
        }

        if (type == DiscountType.PERCENTAGE) {
            if (value.compareTo(BigDecimal.valueOf(100)) > 0) {
                throw new BadRequestException("Phần trăm giảm giá không được vượt quá 100%");
            }
        }

        if (end.isBefore(start) || end.isEqual(start)) {
            throw new BadRequestException("Thời gian kết thúc phải diễn ra sau thời gian bắt đầu");
        }

        if (minOrder != null && minOrder.compareTo(BigDecimal.ZERO) < 0) {
            throw new BadRequestException("Giá trị đơn hàng tối thiểu không được âm");
        }

        if (maxDiscount != null && maxDiscount.compareTo(BigDecimal.ZERO) < 0) {
            throw new BadRequestException("Mức giảm tối đa không được âm");
        }
    }
}


