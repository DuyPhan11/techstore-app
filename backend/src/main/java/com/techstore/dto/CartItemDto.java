package com.techstore.dto;

import com.techstore.entity.CartItem;
import com.techstore.entity.Product;
import com.techstore.entity.ProductImage;
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
public class CartItemDto {

    private Long id;
    private Long productId;
    private String productName;
    private String productSlug;
    private String productSku;
    private String primaryImageUrl;
    private BigDecimal unitPrice;
    private Integer quantity;
    private BigDecimal subtotal;
    private Integer availableStock;
    private Boolean inStock;
    private Boolean isActive;

    public static CartItemDto fromEntity(CartItem item, Integer availableStock) {
        if (item == null || item.getProduct() == null) {
            return null;
        }

        Product product = item.getProduct();
        int stock = (availableStock != null) ? availableStock : 0;
        BigDecimal price = product.getPrice() != null ? product.getPrice() : BigDecimal.ZERO;
        int qty = item.getQuantity() != null ? item.getQuantity() : 1;
        BigDecimal subtotal = price.multiply(BigDecimal.valueOf(qty));

        String primaryImg = null;
        if (product.getImages() != null && !product.getImages().isEmpty()) {
            primaryImg = product.getImages().stream()
                    .filter(img -> Boolean.TRUE.equals(img.getIsPrimary()))
                    .findFirst()
                    .map(ProductImage::getImageUrl)
                    .orElseGet(() -> product.getImages().get(0).getImageUrl());
        }

        return CartItemDto.builder()
                .id(item.getId())
                .productId(product.getId())
                .productName(product.getName())
                .productSlug(product.getSlug())
                .productSku(product.getSku())
                .primaryImageUrl(primaryImg)
                .unitPrice(price)
                .quantity(qty)
                .subtotal(subtotal)
                .availableStock(stock)
                .inStock(stock >= qty)
                .isActive(product.getStatus() == ProductStatus.ACTIVE)
                .build();
    }
}


