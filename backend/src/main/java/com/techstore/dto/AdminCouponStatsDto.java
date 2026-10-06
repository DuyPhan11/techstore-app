package com.techstore.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminCouponStatsDto {
    private long totalCoupons;
    private long activeCoupons;
    private long expiredCoupons;
    private long totalUsed;
}
