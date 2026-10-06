package com.techstore.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateBannerRequest {

    @NotBlank(message = "Tiêu đề banner không được để trống")
    private String title;

    private String subtitle;
    private String badgeText1;
    private String badgeText2;
    private String titleColor;
    private String backgroundColor;
    private String backgroundGradientEnd;
    private String iconName;
    private String imageUrl;
    private String linkType;
    private String linkValue;
    private Integer displayOrder;
    private Boolean isActive;
}
