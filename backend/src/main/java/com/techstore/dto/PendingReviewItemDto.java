package com.techstore.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PendingReviewItemDto {
    private Long orderId;
    private String orderCode;
    private LocalDateTime orderDate;
    private Long productId;
    private String productName;
    private String productSku;
    private String productImage;
    private BigDecimal unitPrice;
    private Integer quantity;
}
