package com.techstore.dto;

import com.techstore.enums.ProductStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductFilterParams {

    private String keyword;
    private String search;
    private Long categoryId;
    private Long brandId;
    private BigDecimal minPrice;
    private BigDecimal maxPrice;
    private ProductStatus status;

    public String getKeyword() {
        if (keyword != null && !keyword.trim().isEmpty()) {
            return keyword.trim();
        }
        if (search != null && !search.trim().isEmpty()) {
            return search.trim();
        }
        return null;
    }

    @Builder.Default
    private Integer page = 0;

    @Builder.Default
    private Integer size = 12;

    @Builder.Default
    private String sortBy = "createdAt";

    @Builder.Default
    private String sortDir = "desc";
}


