package com.techstore.dto;

import com.techstore.entity.ProductImage;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductImageDto {

    private Long id;
    private String imageUrl;
    private Boolean isPrimary;
    private Integer displayOrder;

    public static ProductImageDto fromEntity(ProductImage image) {
        if (image == null) {
            return null;
        }
        return ProductImageDto.builder()
                .id(image.getId())
                .imageUrl(image.getImageUrl())
                .isPrimary(image.getIsPrimary())
                .displayOrder(image.getDisplayOrder())
                .build();
    }
}


