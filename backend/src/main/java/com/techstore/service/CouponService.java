package com.techstore.service;

import com.techstore.dto.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface CouponService {

    Page<CouponResponseDto> getCoupons(CouponFilterParams filter, Pageable pageable);

    CouponResponseDto getCouponById(Long id);

    CouponResponseDto createCoupon(CreateCouponRequest request);

    CouponResponseDto updateCoupon(Long id, UpdateCouponRequest request);

    CouponResponseDto toggleCouponStatus(Long id, boolean active);

    void deleteCoupon(Long id);

    AdminCouponStatsDto getAdminCouponStats();

    java.util.List<CouponResponseDto> getAvailableCoupons();
}


