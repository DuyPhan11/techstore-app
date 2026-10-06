package com.techstore.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminReviewStatsDto {
    private Double averageRating;
    private Long totalReviews;
    private Long count5Star;
    private Long count4Star;
    private Long count3Star;
    private Long count2Star;
    private Long count1Star;
}
