package com.techstore.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CategoryRevenueDto {
    private Long categoryId;
    private String categoryName;
    private BigDecimal revenue;
    private Long quantitySold;
    private Double percentage;
}

