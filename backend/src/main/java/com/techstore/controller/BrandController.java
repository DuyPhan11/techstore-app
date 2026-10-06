package com.techstore.controller;

import com.techstore.dto.BrandDto;
import com.techstore.dto.BrandRequest;
import com.techstore.service.BrandService;
import com.techstore.dto.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/brands")
@RequiredArgsConstructor
public class BrandController {

    private final BrandService brandService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<BrandDto>>> getAllBrands(
            @RequestParam(required = false) String status) {
        List<BrandDto> brands = brandService.getAllBrands(status);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách thương hiệu thành công", brands));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<BrandDto>> getBrandById(@PathVariable Long id) {
        BrandDto brand = brandService.getBrandById(id);
        return ResponseEntity.ok(ApiResponse.ok("Lấy thông tin thương hiệu thành công", brand));
    }

    @GetMapping("/slug/{slug}")
    public ResponseEntity<ApiResponse<BrandDto>> getBrandBySlug(@PathVariable String slug) {
        BrandDto brand = brandService.getBrandBySlug(slug);
        return ResponseEntity.ok(ApiResponse.ok("Lấy thông tin thương hiệu thành công", brand));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<BrandDto>> createBrand(@Valid @RequestBody BrandRequest request) {
        BrandDto created = brandService.createBrand(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Tạo thương hiệu thành công", created));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<BrandDto>> updateBrand(
            @PathVariable Long id,
            @Valid @RequestBody BrandRequest request) {
        BrandDto updated = brandService.updateBrand(id, request);
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật thương hiệu thành công", updated));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteBrand(@PathVariable Long id) {
        brandService.deleteBrand(id);
        return ResponseEntity.ok(ApiResponse.ok("Xóa thương hiệu thành công", null));
    }
}


