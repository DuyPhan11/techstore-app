package com.techstore.dto;

import com.techstore.entity.Coupon;
import com.techstore.enums.DiscountType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CouponResponseDto {

    private Long id;
    private String code;
    private DiscountType discountType;
    private BigDecimal discountValue;
    private BigDecimal minOrderAmount;
    private BigDecimal maxDiscountAmount;
    private Integer usageLimit;
    private Integer usedCount;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
    private Boolean isActive;
    private boolean isExpired;
    private boolean isFullyUsed;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static CouponResponseDto fromEntity(Coupon coupon) {
        if (coupon == null) return null;

        LocalDateTime now = LocalDateTime.now();
        boolean expired = now.isAfter(coupon.getEndDate());
        boolean fullyUsed = coupon.getUsedCount() >= coupon.getUsageLimit();

        return CouponResponseDto.builder()
                .id(coupon.getId())
                .code(coupon.getCode())
                .discountType(coupon.getDiscountType())
                .discountValue(coupon.getDiscountValue())
                .minOrderAmount(coupon.getMinOrderAmount())
                .maxDiscountAmount(coupon.getMaxDiscountAmount())
                .usageLimit(coupon.getUsageLimit())
                .usedCount(coupon.getUsedCount())
                .startDate(coupon.getStartDate())
                .endDate(coupon.getEndDate())
                .isActive(coupon.getIsActive())
                .isExpired(expired)
                .isFullyUsed(fullyUsed)
                .createdAt(coupon.getCreatedAt())
                .updatedAt(coupon.getUpdatedAt())
                .build();
    }
}


