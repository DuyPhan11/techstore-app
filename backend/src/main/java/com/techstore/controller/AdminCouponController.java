package com.techstore.controller;

import com.techstore.dto.ApiResponse;
import com.techstore.dto.*;
import com.techstore.service.CouponService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin/coupons")
@RequiredArgsConstructor
public class AdminCouponController {

    private final CouponService couponService;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<CouponResponseDto>>> getCoupons(
            @ModelAttribute CouponFilterParams filter,
            @PageableDefault(size = 15, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        Page<CouponResponseDto> response = couponService.getCoupons(filter, pageable);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách mã giảm giá thành công", response));
    }

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<AdminCouponStatsDto>> getCouponStats() {
        AdminCouponStatsDto response = couponService.getAdminCouponStats();
        return ResponseEntity.ok(ApiResponse.ok("Lấy thống kê mã giảm giá thành công", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<CouponResponseDto>> getCouponById(@PathVariable Long id) {
        CouponResponseDto response = couponService.getCouponById(id);
        return ResponseEntity.ok(ApiResponse.ok("Lấy thông tin mã giảm giá thành công", response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CouponResponseDto>> createCoupon(
            @Valid @RequestBody CreateCouponRequest request) {
        CouponResponseDto response = couponService.createCoupon(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Tạo mã giảm giá thành công", response));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<CouponResponseDto>> updateCoupon(
            @PathVariable Long id,
            @Valid @RequestBody UpdateCouponRequest request) {
        CouponResponseDto response = couponService.updateCoupon(id, request);
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật mã giảm giá thành công", response));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<CouponResponseDto>> toggleStatus(
            @PathVariable Long id,
            @RequestBody Map<String, Boolean> payload) {
        boolean active = payload.getOrDefault("active", true);
        CouponResponseDto response = couponService.toggleCouponStatus(id, active);
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật trạng thái mã giảm giá thành công", response));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteCoupon(@PathVariable Long id) {
        couponService.deleteCoupon(id);
        return ResponseEntity.ok(ApiResponse.ok("Xóa mã giảm giá thành công", null));
    }
}


