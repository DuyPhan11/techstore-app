package com.techstore.dto;

import com.techstore.enums.NotificationType;
import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationDto {
    private Long id;
    private String title;
    private String content;
    private NotificationType type;
    private String referenceId;
    private Boolean isRead;
    private LocalDateTime createdAt;
}
