package com.techstore.dto;

import com.techstore.entity.Brand;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BrandDto {

    private Long id;
    private String name;
    private String slug;
    private String logoUrl;
    private String description;
    private String status;

    public static BrandDto fromEntity(Brand brand) {
        if (brand == null) {
            return null;
        }
        return BrandDto.builder()
                .id(brand.getId())
                .name(brand.getName())
                .slug(brand.getSlug())
                .logoUrl(brand.getLogoUrl())
                .description(brand.getDescription())
                .status(brand.getStatus())
                .build();
    }
}


