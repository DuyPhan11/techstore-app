package com.techstore.service;

import com.techstore.dto.CheckoutRequest;
import com.techstore.dto.OrderResponseDto;
import com.techstore.dto.CouponValidationRequest;
import com.techstore.dto.CouponValidationResponse;
import com.techstore.entity.User;

public interface CheckoutService {

    OrderResponseDto checkout(User user, CheckoutRequest request);

    CouponValidationResponse validateCoupon(User user, CouponValidationRequest request);
}


