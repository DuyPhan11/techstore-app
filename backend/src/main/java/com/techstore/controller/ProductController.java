package com.techstore.controller;

import com.techstore.dto.ApiResponse;
import com.techstore.dto.PageResponse;
import com.techstore.dto.*;
import com.techstore.enums.ProductStatus;
import com.techstore.service.ProductService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

@RestController
@RequestMapping("/api/v1/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService;

    @GetMapping("/management")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ApiResponse<PageResponse<ProductSummaryDto>> getManagementProducts(@ModelAttribute ProductFilterParams params) {
        return ApiResponse.ok(productService.getManagementProducts(params));
    }

    @GetMapping("/{id}/management")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ApiResponse<ProductDetailDto> getProductForManagement(@PathVariable Long id) {
        return ApiResponse.ok(productService.getProductForManagement(id));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ProductSummaryDto>>> getProducts(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Long brandId,
            @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice,
            @RequestParam(required = false) ProductStatus status,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "12") Integer size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {

        String effectiveKeyword = (keyword != null && !keyword.trim().isEmpty())
                ? keyword.trim()
                : (search != null && !search.trim().isEmpty() ? search.trim() : null);

        ProductFilterParams params = ProductFilterParams.builder()
                .keyword(effectiveKeyword)
                .search(effectiveKeyword)
                .categoryId(categoryId)
                .brandId(brandId)
                .minPrice(minPrice)
                .maxPrice(maxPrice)
                .status(status)
                .page(page)
                .size(size)
                .sortBy(sortBy)
                .sortDir(sortDir)
                .build();

        PageResponse<ProductSummaryDto> response = productService.getProducts(params);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách sản phẩm thành công", response));
    }

    @GetMapping("/recommendations")
    public ResponseEntity<ApiResponse<java.util.List<ProductSummaryDto>>> getRecommendations(
            @RequestParam(required = false) java.util.List<Long> viewedIds,
            @RequestParam(defaultValue = "6") Integer limit) {
        java.util.List<ProductSummaryDto> response = productService.getRecommendations(viewedIds, limit);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách gợi ý sản phẩm thành công", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ProductDetailDto>> getProductById(@PathVariable Long id) {
        ProductDetailDto product = productService.getProductById(id);
        return ResponseEntity.ok(ApiResponse.ok("Lấy thông tin sản phẩm thành công", product));
    }

    @GetMapping("/slug/{slug}")
    public ResponseEntity<ApiResponse<ProductDetailDto>> getProductBySlug(@PathVariable String slug) {
        ProductDetailDto product = productService.getProductBySlug(slug);
        return ResponseEntity.ok(ApiResponse.ok("Lấy thông tin sản phẩm thành công", product));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('STAFF', 'ADMIN')")
    public ResponseEntity<ApiResponse<ProductDetailDto>> createProduct(@Valid @RequestBody ProductCreateRequest request) {
        ProductDetailDto created = productService.createProduct(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Tạo sản phẩm thành công", created));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('STAFF', 'ADMIN')")
    public ResponseEntity<ApiResponse<ProductDetailDto>> updateProduct(
            @PathVariable Long id,
            @Valid @RequestBody ProductUpdateRequest request) {
        ProductDetailDto updated = productService.updateProduct(id, request);
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật sản phẩm thành công", updated));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('STAFF', 'ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteProduct(@PathVariable Long id) {
        productService.deleteProduct(id);
        return ResponseEntity.ok(ApiResponse.ok("Ẩn sản phẩm thành công", null));
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('STAFF', 'ADMIN')")
    public ResponseEntity<ApiResponse<ProductDetailDto>> updateProductStatus(
            @PathVariable Long id,
            @RequestParam(required = false) com.techstore.enums.ProductStatus status) {
        ProductDetailDto updated = productService.updateProductStatus(id, status);
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật trạng thái hiển thị sản phẩm thành công", updated));
    }

    @PostMapping("/{id}/images")
    @PreAuthorize("hasAnyRole('STAFF', 'ADMIN')")
    public ResponseEntity<ApiResponse<ProductImageDto>> addProductImage(
            @PathVariable Long id,
            @Valid @RequestBody ProductImageRequest request) {
        ProductImageDto image = productService.addProductImage(id, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Thêm ảnh sản phẩm thành công", image));
    }

    @DeleteMapping("/{id}/images/{imageId}")
    @PreAuthorize("hasAnyRole('STAFF', 'ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteProductImage(
            @PathVariable Long id,
            @PathVariable Long imageId) {
        productService.deleteProductImage(id, imageId);
        return ResponseEntity.ok(ApiResponse.ok("Xóa ảnh sản phẩm thành công", null));
    }

    @PutMapping("/{id}/images/{imageId}/primary")
    @PreAuthorize("hasAnyRole('STAFF', 'ADMIN')")
    public ResponseEntity<ApiResponse<Void>> setPrimaryImage(
            @PathVariable Long id,
            @PathVariable Long imageId) {
        productService.setPrimaryImage(id, imageId);
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật ảnh đại diện thành công", null));
    }
}


