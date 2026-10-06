package com.techstore.service.impl;

import com.techstore.dto.*;
import com.techstore.service.DashboardService;
import com.techstore.entity.Order;
import com.techstore.enums.OrderStatus;
import com.techstore.repository.OrderItemRepository;
import com.techstore.repository.OrderRepository;
import com.techstore.enums.RoleName;
import com.techstore.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class DashboardServiceImpl implements DashboardService {

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final UserRepository userRepository;

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    @Override
    @Transactional(readOnly = true)
    public DashboardSummaryDto getDashboardSummary(Integer days) {
        return getDashboardSummary(days, null, null);
    }

    @Override
    @Transactional(readOnly = true)
    public DashboardSummaryDto getDashboardSummary(Integer days, LocalDate startDate, LocalDate endDate) {
        LocalDate startDay;
        LocalDate endDay;

        if (startDate != null && endDate != null) {
            if (endDate.isBefore(startDate)) {
                startDay = endDate;
                endDay = startDate;
            } else {
                startDay = startDate;
                endDay = endDate;
            }
        } else {
            int windowDays = (days != null && days > 0) ? days : 30;
            endDay = LocalDate.now();
            startDay = endDay.minusDays(windowDays - 1);
        }

        LocalDateTime startTime = startDay.atStartOfDay();
        LocalDateTime endTime = endDay.plusDays(1).atStartOfDay();

        // 1. KPI Metrics in this time window
        long totalOrders = orderRepository.countOrdersBetween(startTime, endTime);
        long completedOrders = orderRepository.countOrdersByStatusBetween(OrderStatus.COMPLETED, startTime, endTime);
        long cancelledOrders = orderRepository.countOrdersByStatusBetween(OrderStatus.CANCELLED, startTime, endTime);

        List<Order> completedOrderList = orderRepository.findCompletedOrdersBetween(startTime, endTime);
        BigDecimal totalRevenue = completedOrderList.stream()
                .map(Order::getFinalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        long totalCustomers = userRepository.countByRole(RoleName.ROLE_CUSTOMER);
        long newCustomers = userRepository.countByRoleAndCreatedAtAfter(RoleName.ROLE_CUSTOMER, startTime);

        // 2. Revenue Over Time (Daily buckets for the window)
        List<RevenueTimePointDto> revenueOverTime = computeRevenueOverTime(startDay, endDay, completedOrderList);

        // 3. Revenue by Category (with percentage)
        List<CategoryRevenueDto> revenueByCategory = computeRevenueByCategory(startTime, endTime);

        // 4. Revenue by Branch
        List<BranchRevenueDto> revenueByBranch = computeRevenueByBranch(startTime, endTime);

        // 5. Best-Selling Products (Top 5)
        List<BestSellingProductDto> bestSellingProducts = computeBestSellingProducts(5, startTime, endTime);

        return DashboardSummaryDto.builder()
                .totalOrders(totalOrders)
                .totalRevenue(totalRevenue)
                .completedOrders(completedOrders)
                .cancelledOrders(cancelledOrders)
                .newCustomers(newCustomers)
                .totalCustomers(totalCustomers)
                .startDate(startDay.format(DATE_FORMATTER))
                .endDate(endDay.format(DATE_FORMATTER))
                .revenueOverTime(revenueOverTime)
                .revenueByCategory(revenueByCategory)
                .revenueByBranch(revenueByBranch)
                .bestSellingProducts(bestSellingProducts)
                .build();
    }

    private List<RevenueTimePointDto> computeRevenueOverTime(LocalDate startDay, LocalDate endDay, List<Order> completedOrders) {
        Map<LocalDate, RevenueTimePointDto> timelineMap = new LinkedHashMap<>();
        LocalDate cur = startDay;
        while (!cur.isAfter(endDay)) {
            timelineMap.put(cur, RevenueTimePointDto.builder()
                    .date(cur.format(DATE_FORMATTER))
                    .revenue(BigDecimal.ZERO)
                    .orderCount(0L)
                    .build());
            cur = cur.plusDays(1);
        }

        for (Order order : completedOrders) {
            LocalDate orderDate = order.getCreatedAt().toLocalDate();
            RevenueTimePointDto point = timelineMap.get(orderDate);
            if (point != null) {
                point.setRevenue(point.getRevenue().add(order.getFinalAmount()));
                point.setOrderCount(point.getOrderCount() + 1);
            }
        }

        return new ArrayList<>(timelineMap.values());
    }

    private List<CategoryRevenueDto> computeRevenueByCategory(LocalDateTime startTime, LocalDateTime endTime) {
        List<Object[]> rawList = orderItemRepository.getRevenueByCategoryBetween(startTime, endTime);
        if (rawList.isEmpty()) {
            rawList = orderItemRepository.getRevenueByCategory();
        }

        List<CategoryRevenueDto> result = new ArrayList<>();
        BigDecimal totalCatRevenue = BigDecimal.ZERO;

        for (Object[] row : rawList) {
            Long catId = ((Number) row[0]).longValue();
            String catName = (String) row[1];
            BigDecimal rev = (row[2] instanceof BigDecimal) ? (BigDecimal) row[2] : BigDecimal.valueOf(((Number) row[2]).doubleValue());
            Long qty = ((Number) row[3]).longValue();
            totalCatRevenue = totalCatRevenue.add(rev);

            result.add(CategoryRevenueDto.builder()
                    .categoryId(catId)
                    .categoryName(catName)
                    .revenue(rev)
                    .quantitySold(qty)
                    .build());
        }

        // Calculate percentage
        if (totalCatRevenue.compareTo(BigDecimal.ZERO) > 0) {
            for (CategoryRevenueDto dto : result) {
                double pct = dto.getRevenue()
                        .multiply(BigDecimal.valueOf(100))
                        .divide(totalCatRevenue, 2, java.math.RoundingMode.HALF_UP)
                        .doubleValue();
                dto.setPercentage(pct);
            }
        }

        return result;
    }

    private List<BranchRevenueDto> computeRevenueByBranch(LocalDateTime startTime, LocalDateTime endTime) {
        List<Object[]> rawList = orderRepository.getRevenueByBranchBetween(startTime, endTime);
        if (rawList.isEmpty()) {
            rawList = orderRepository.getRevenueByBranch();
        }

        List<BranchRevenueDto> result = new ArrayList<>();

        for (Object[] row : rawList) {
            Long branchId = ((Number) row[0]).longValue();
            String branchName = (String) row[1];
            BigDecimal rev = (row[2] instanceof BigDecimal) ? (BigDecimal) row[2] : BigDecimal.valueOf(((Number) row[2]).doubleValue());
            Long count = ((Number) row[3]).longValue();

            result.add(BranchRevenueDto.builder()
                    .branchId(branchId)
                    .branchName(branchName)
                    .revenue(rev)
                    .orderCount(count)
                    .build());
        }

        return result;
    }

    private List<BestSellingProductDto> computeBestSellingProducts(int limit, LocalDateTime startTime, LocalDateTime endTime) {
        List<Object[]> rawList = orderItemRepository.getBestSellingProductsBetween(startTime, endTime, PageRequest.of(0, limit));
        if (rawList.isEmpty()) {
            rawList = orderItemRepository.getBestSellingProducts(PageRequest.of(0, limit));
        }

        List<BestSellingProductDto> result = new ArrayList<>();

        for (Object[] row : rawList) {
            Long pId = ((Number) row[0]).longValue();
            String pName = (String) row[1];
            String pSku = (String) row[2];
            String pImg = (String) row[3];
            Long qty = ((Number) row[4]).longValue();
            BigDecimal rev = (row[5] instanceof BigDecimal) ? (BigDecimal) row[5] : BigDecimal.valueOf(((Number) row[5]).doubleValue());

            result.add(BestSellingProductDto.builder()
                    .productId(pId)
                    .productName(pName)
                    .productSku(pSku)
                    .productImage(pImg)
                    .quantitySold(qty)
                    .totalRevenue(rev)
                    .build());
        }

        return result;
    }
}


