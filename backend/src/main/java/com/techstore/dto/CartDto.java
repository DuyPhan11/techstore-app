package com.techstore.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CartDto {

    private Long id;

    @Builder.Default
    private List<CartItemDto> items = new ArrayList<>();

    @Builder.Default
    private Integer totalItems = 0;

    @Builder.Default
    private Integer itemCount = 0;

    @Builder.Default
    private BigDecimal totalPrice = BigDecimal.ZERO;

    public static CartDto of(Long cartId, List<CartItemDto> items) {
        if (items == null) {
            items = new ArrayList<>();
        }

        int totalQty = items.stream()
                .mapToInt(i -> i.getQuantity() != null ? i.getQuantity() : 0)
                .sum();

        BigDecimal total = items.stream()
                .map(i -> i.getSubtotal() != null ? i.getSubtotal() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return CartDto.builder()
                .id(cartId)
                .items(items)
                .totalItems(totalQty)
                .itemCount(items.size())
                .totalPrice(total)
                .build();
    }
}

