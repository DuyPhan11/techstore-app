package com.techstore.controller;

import com.techstore.dto.ApiResponse;
import com.techstore.dto.BannerResponseDto;
import com.techstore.dto.CreateBannerRequest;
import com.techstore.dto.UpdateBannerRequest;
import com.techstore.service.BannerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin/banners")
@RequiredArgsConstructor
public class AdminBannerController {

    private final BannerService bannerService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<BannerResponseDto>>> getAllBanners() {
        List<BannerResponseDto> banners = bannerService.getAllBanners();
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách tất cả banner thành công", banners));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<BannerResponseDto>> getBannerById(@PathVariable Long id) {
        BannerResponseDto banner = bannerService.getBannerById(id);
        return ResponseEntity.ok(ApiResponse.ok("Lấy thông tin banner thành công", banner));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<BannerResponseDto>> createBanner(@Valid @RequestBody CreateBannerRequest request) {
        BannerResponseDto created = bannerService.createBanner(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Tạo banner thành công", created));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<BannerResponseDto>> updateBanner(
            @PathVariable Long id,
            @Valid @RequestBody UpdateBannerRequest request) {
        BannerResponseDto updated = bannerService.updateBanner(id, request);
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật banner thành công", updated));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<BannerResponseDto>> toggleStatus(
            @PathVariable Long id,
            @RequestBody Map<String, Boolean> payload) {
        boolean active = payload.getOrDefault("active", true);
        BannerResponseDto updated = bannerService.toggleStatus(id, active);
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật trạng thái banner thành công", updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteBanner(@PathVariable Long id) {
        bannerService.deleteBanner(id);
        return ResponseEntity.ok(ApiResponse.ok("Xóa banner thành công", null));
    }

    @PostMapping("/seed")
    public ResponseEntity<ApiResponse<List<BannerResponseDto>>> seedBanners() {
        bannerService.seedDefaultBannersIfEmpty();
        List<BannerResponseDto> banners = bannerService.getAllBanners();
        return ResponseEntity.ok(ApiResponse.ok("Khởi tạo dữ liệu banner mẫu thành công", banners));
    }
}
