package com.techstore.dto;

import com.techstore.enums.AdjustmentType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockAdjustmentRequest {

    @NotNull(message = "ID sản phẩm không được để trống")
    private Long productId;

    @NotNull(message = "ID chi nhánh không được để trống")
    private Long branchId;

    @NotNull(message = "Loại điều chỉnh không được để trống (ADD, SUBTRACT, SET)")
    private AdjustmentType adjustmentType;

    @NotNull(message = "Số lượng không được để trống")
    @Min(value = 0, message = "Số lượng điều chỉnh không thể âm")
    private Integer quantity;

    private String reason;
}


