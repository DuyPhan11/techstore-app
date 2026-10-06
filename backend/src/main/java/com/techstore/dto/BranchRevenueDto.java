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
public class BranchRevenueDto {
    private Long branchId;
    private String branchName;
    private BigDecimal revenue;
    private Long orderCount;
}

