package com.techstore.controller;

import com.techstore.dto.ApiResponse;
import com.techstore.dto.CouponResponseDto;
import com.techstore.service.CouponService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/coupons")
@RequiredArgsConstructor
public class CouponController {

    private final CouponService couponService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<CouponResponseDto>>> getAvailableCoupons() {
        List<CouponResponseDto> response = couponService.getAvailableCoupons();
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách mã giảm giá khả dụng thành công", response));
    }
}
