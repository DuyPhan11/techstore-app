package com.techstore.dto;

import com.techstore.dto.BrandDto;
import com.techstore.dto.CategoryDto;
import com.techstore.entity.Product;
import com.techstore.enums.ProductStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductDetailDto {

    private Long id;
    private String name;
    private String slug;
    private String sku;
    private BigDecimal price;
    @com.fasterxml.jackson.annotation.JsonInclude(com.fasterxml.jackson.annotation.JsonInclude.Include.NON_NULL)
    private BigDecimal costPrice;
    private String description;
    private String specifications;
    private ProductStatus status;
    private CategoryDto category;
    private BrandDto brand;
    private List<ProductImageDto> images;
    private Integer totalStock;
    private Integer warrantyMonths;
    private List<BranchStockDto> branchInventories;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static ProductDetailDto fromEntity(Product product, Integer totalStock) {
        return fromEntity(product, totalStock, null);
    }

    public static ProductDetailDto fromEntity(Product product, Integer totalStock, List<BranchStockDto> branchInventories) {
        if (product == null) {
            return null;
        }

        List<ProductImageDto> imageDtos = Collections.emptyList();
        if (product.getImages() != null) {
            imageDtos = product.getImages().stream()
                    .sorted(Comparator.comparing(img -> img.getDisplayOrder() != null ? img.getDisplayOrder() : 0))
                    .map(ProductImageDto::fromEntity)
                    .collect(Collectors.toList());
        }

        return ProductDetailDto.builder()
                .id(product.getId())
                .name(product.getName())
                .slug(product.getSlug())
                .sku(product.getSku())
                .price(product.getPrice())
                .description(product.getDescription())
                .specifications(product.getSpecifications())
                .status(product.getStatus())
                .category(CategoryDto.fromEntity(product.getCategory()))
                .brand(BrandDto.fromEntity(product.getBrand()))
                .images(imageDtos)
                .totalStock(totalStock != null ? totalStock : 0)
                .warrantyMonths(product.getWarrantyMonths() != null ? product.getWarrantyMonths() : 12)
                .branchInventories(branchInventories != null ? branchInventories : Collections.emptyList())
                .createdAt(product.getCreatedAt())
                .updatedAt(product.getUpdatedAt())
                .build();
    }
}


