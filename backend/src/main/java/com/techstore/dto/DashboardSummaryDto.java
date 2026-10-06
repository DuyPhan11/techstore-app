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
public class DashboardSummaryDto {
    private Long totalOrders;
    private BigDecimal totalRevenue;
    private Long completedOrders;
    private Long cancelledOrders;
    private Long newCustomers;
    private Long totalCustomers;
    private String startDate;
    private String endDate;

    @Builder.Default
    private List<RevenueTimePointDto> revenueOverTime = new ArrayList<>();

    @Builder.Default
    private List<CategoryRevenueDto> revenueByCategory = new ArrayList<>();

    @Builder.Default
    private List<BranchRevenueDto> revenueByBranch = new ArrayList<>();

    @Builder.Default
    private List<BestSellingProductDto> bestSellingProducts = new ArrayList<>();
}

