package com.techstore.dto;

import com.techstore.entity.OrderItem;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderItemResponseDto {

    private Long id;
    private Long productId;
    private String productName;
    private String productSku;
    private String productImage;
    private String productThumbnail;
    private BigDecimal unitPrice;
    private Integer quantity;
    private Integer warrantyMonths;
    private BigDecimal subtotalAmount;
    private BigDecimal totalPrice;

    public static OrderItemResponseDto fromEntity(OrderItem item) {
        if (item == null) {
            return null;
        }
        BigDecimal subtotal = item.getSubtotalAmount() != null ? item.getSubtotalAmount()
                : (item.getUnitPrice() != null && item.getQuantity() != null
                    ? item.getUnitPrice().multiply(BigDecimal.valueOf(item.getQuantity()))
                    : BigDecimal.ZERO);
        String image = item.getProductImage();
        Integer warranty = item.getProduct() != null && item.getProduct().getWarrantyMonths() != null
                ? item.getProduct().getWarrantyMonths()
                : 12;
        return OrderItemResponseDto.builder()
                .id(item.getId())
                .productId(item.getProduct() != null ? item.getProduct().getId() : null)
                .productName(item.getProductName())
                .productSku(item.getProductSku())
                .productImage(image)
                .productThumbnail(image)
                .unitPrice(item.getUnitPrice())
                .quantity(item.getQuantity())
                .warrantyMonths(warranty)
                .subtotalAmount(subtotal)
                .totalPrice(subtotal)
                .build();
    }
}


