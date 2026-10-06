package com.techstore.service;

import com.techstore.dto.DashboardSummaryDto;

import java.time.LocalDate;

public interface DashboardService {
    DashboardSummaryDto getDashboardSummary(Integer days);
    DashboardSummaryDto getDashboardSummary(Integer days, LocalDate startDate, LocalDate endDate);
}


