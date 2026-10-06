package com.techstore.dto;

import com.techstore.enums.DiscountType;
import jakarta.validation.constraints.*;
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
public class CreateCouponRequest {

    @NotBlank(message = "Mã giảm giá không được để trống")
    @Pattern(regexp = "^[A-Za-z0-9_-]{3,50}$", message = "Mã giảm giá từ 3-50 ký tự, chỉ gồm chữ, số, dấu gạch ngang hoặc gạch dưới")
    private String code;

    @NotNull(message = "Loại giảm giá không được để trống")
    private DiscountType discountType;

    @NotNull(message = "Giá trị giảm giá không được để trống")
    @DecimalMin(value = "0.01", message = "Giá trị giảm giá phải lớn hơn 0")
    private BigDecimal discountValue;

    @Builder.Default
    private BigDecimal minOrderAmount = BigDecimal.ZERO;

    private BigDecimal maxDiscountAmount;

    @NotNull(message = "Giới hạn lượt sử dụng không được để trống")
    @Min(value = 1, message = "Giới hạn sử dụng tối thiểu là 1")
    private Integer usageLimit;

    @NotNull(message = "Thời gian bắt đầu không được để trống")
    private LocalDateTime startDate;

    @NotNull(message = "Thời gian kết thúc không được để trống")
    private LocalDateTime endDate;

    @Builder.Default
    private Boolean isActive = true;
}


