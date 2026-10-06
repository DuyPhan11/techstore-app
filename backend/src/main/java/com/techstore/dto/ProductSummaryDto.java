package com.techstore.dto;

import com.techstore.dto.BrandDto;
import com.techstore.dto.CategoryDto;
import com.techstore.entity.Product;
import com.techstore.entity.ProductImage;
import com.techstore.enums.ProductStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductSummaryDto {

    private Long id;
    private String name;
    private String slug;
    private String sku;
    private BigDecimal price;
    private ProductStatus status;
    private CategoryDto category;
    private BrandDto brand;
    private String primaryImageUrl;
    private Integer totalStock;
    private Integer warrantyMonths;
    private List<BranchStockDto> branchInventories;
    private LocalDateTime createdAt;

    public static ProductSummaryDto fromEntity(Product product, Integer totalStock) {
        return fromEntity(product, totalStock, null);
    }

    public static ProductSummaryDto fromEntity(Product product, Integer totalStock, List<BranchStockDto> branchInventories) {
        if (product == null) {
            return null;
        }

        String primaryImg = null;
        if (product.getImages() != null && !product.getImages().isEmpty()) {
            primaryImg = product.getImages().stream()
                    .filter(img -> Boolean.TRUE.equals(img.getIsPrimary()))
                    .findFirst()
                    .map(ProductImage::getImageUrl)
                    .orElseGet(() -> product.getImages().get(0).getImageUrl());
        }

        return ProductSummaryDto.builder()
                .id(product.getId())
                .name(product.getName())
                .slug(product.getSlug())
                .sku(product.getSku())
                .price(product.getPrice())
                .status(product.getStatus())
                .category(CategoryDto.fromEntity(product.getCategory()))
                .brand(BrandDto.fromEntity(product.getBrand()))
                .primaryImageUrl(primaryImg)
                .totalStock(totalStock != null ? totalStock : 0)
                .warrantyMonths(product.getWarrantyMonths() != null ? product.getWarrantyMonths() : 12)
                .branchInventories(branchInventories != null ? branchInventories : Collections.emptyList())
                .createdAt(product.getCreatedAt())
                .build();
    }
}


