package com.techstore.dto;

import com.techstore.entity.Banner;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BannerResponseDto {
    private Long id;
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
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static BannerResponseDto fromEntity(Banner banner) {
        if (banner == null) return null;
        return BannerResponseDto.builder()
                .id(banner.getId())
                .title(banner.getTitle())
                .subtitle(banner.getSubtitle())
                .badgeText1(banner.getBadgeText1())
                .badgeText2(banner.getBadgeText2())
                .titleColor(banner.getTitleColor())
                .backgroundColor(banner.getBackgroundColor())
                .backgroundGradientEnd(banner.getBackgroundGradientEnd())
                .iconName(banner.getIconName())
                .imageUrl(banner.getImageUrl())
                .linkType(banner.getLinkType())
                .linkValue(banner.getLinkValue())
                .displayOrder(banner.getDisplayOrder())
                .isActive(banner.getIsActive())
                .createdAt(banner.getCreatedAt())
                .updatedAt(banner.getUpdatedAt())
                .build();
    }
}
