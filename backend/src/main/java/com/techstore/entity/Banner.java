package com.techstore.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "banners")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Banner {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(length = 255)
    private String subtitle;

    @Column(length = 50)
    private String badgeText1;

    @Column(length = 50)
    private String badgeText2;

    @Column(length = 20)
    @Builder.Default
    private String titleColor = "#FFEB3B";

    @Column(length = 20)
    @Builder.Default
    private String backgroundColor = "#581C87";

    @Column(length = 20)
    private String backgroundGradientEnd;

    @Column(length = 50)
    @Builder.Default
    private String iconName = "devices_other";

    @Column(length = 500)
    private String imageUrl;

    @Column(length = 30)
    @Builder.Default
    private String linkType = "NONE"; // NONE, COUPON, PRODUCT, CATEGORY

    @Column(length = 255)
    private String linkValue;

    @Column(nullable = false)
    @Builder.Default
    private Integer displayOrder = 0;

    @Column(nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
