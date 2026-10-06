package com.techstore.service;

import com.techstore.dto.PageResponse;
import com.techstore.dto.*;

public interface ProductService {

    PageResponse<ProductSummaryDto> getProducts(ProductFilterParams params);
    PageResponse<ProductSummaryDto> getManagementProducts(ProductFilterParams params);
    java.util.List<ProductSummaryDto> getRecommendations(java.util.List<Long> viewedIds, Integer limit);

    ProductDetailDto getProductById(Long id);
    ProductDetailDto getProductForManagement(Long id);

    ProductDetailDto getProductBySlug(String slug);

    ProductDetailDto createProduct(ProductCreateRequest request);

    ProductDetailDto updateProduct(Long id, ProductUpdateRequest request);

    void deleteProduct(Long id);

    ProductDetailDto updateProductStatus(Long id, com.techstore.enums.ProductStatus status);

    ProductImageDto addProductImage(Long productId, ProductImageRequest request);

    void deleteProductImage(Long productId, Long imageId);

    void setPrimaryImage(Long productId, Long imageId);
}


