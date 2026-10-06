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
public class BestSellingProductDto {
    private Long productId;
    private String productName;
    private String productSku;
    private String productImage;
    private Long quantitySold;
    private BigDecimal totalRevenue;
}

