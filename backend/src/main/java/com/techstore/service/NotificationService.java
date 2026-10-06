package com.techstore.service;

import com.techstore.dto.NotificationDto;
import com.techstore.entity.User;
import com.techstore.enums.NotificationType;

import java.util.List;

public interface NotificationService {
    List<NotificationDto> getUserNotifications(User user);
    long getUnreadCount(User user);
    void markAsRead(User user, Long notificationId);
    void markAllAsRead(User user);
    void createNotification(User user, String title, String content, NotificationType type, String referenceId);
}
