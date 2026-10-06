package com.techstore.dto;

import com.techstore.entity.Inventory;
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
public class InventoryDto {
    private Long id;
    private Long productId;
    private String productName;
    private String productSku;
    private BigDecimal productPrice;
    private Long branchId;
    private String branchName;
    private Integer quantity;
    private Integer minStockAlert;
    private Boolean isLowStock;
    private LocalDateTime updatedAt;

    public static InventoryDto fromEntity(Inventory inv) {
        if (inv == null) return null;
        boolean low = inv.getQuantity() != null && inv.getMinStockAlert() != null
                && inv.getQuantity() <= inv.getMinStockAlert();

        return InventoryDto.builder()
                .id(inv.getId())
                .productId(inv.getProduct() != null ? inv.getProduct().getId() : null)
                .productName(inv.getProduct() != null ? inv.getProduct().getName() : null)
                .productSku(inv.getProduct() != null ? inv.getProduct().getSku() : null)
                .productPrice(inv.getProduct() != null ? inv.getProduct().getPrice() : null)
                .branchId(inv.getBranch() != null ? inv.getBranch().getId() : null)
                .branchName(inv.getBranch() != null ? inv.getBranch().getName() : null)
                .quantity(inv.getQuantity())
                .minStockAlert(inv.getMinStockAlert())
                .isLowStock(low)
                .updatedAt(inv.getUpdatedAt())
                .build();
    }
}


