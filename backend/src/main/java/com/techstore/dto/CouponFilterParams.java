package com.techstore.dto;

import com.techstore.enums.DiscountType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CouponFilterParams {

    private String search;
    private DiscountType discountType;
    private Boolean isActive;
}


