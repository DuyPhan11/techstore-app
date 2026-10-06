package com.techstore.controller;

import com.techstore.dto.ApiResponse;
import com.techstore.dto.BannerResponseDto;
import com.techstore.service.BannerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/banners")
@RequiredArgsConstructor
public class BannerController {

    private final BannerService bannerService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<BannerResponseDto>>> getActiveBanners() {
        List<BannerResponseDto> banners = bannerService.getActiveBanners();
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách banner thành công", banners));
    }
}
