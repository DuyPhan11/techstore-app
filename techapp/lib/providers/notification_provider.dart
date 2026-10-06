import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final list = await NotificationService.getNotifications();
      _notifications = list;
      _unreadCount = list.where((n) => !n.isRead).length;
    } catch (_) {
      // Backend offline or error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      _unreadCount = 0;
      notifyListeners();
      return;
    }

    try {
      _unreadCount = await NotificationService.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
      notifyListeners();

      try {
        await NotificationService.markAsRead(notificationId);
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead() async {
    if (_unreadCount == 0) return;

    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await NotificationService.markAllAsRead();
    } catch (_) {}
  }

  void clearOnLogout() {
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }
}
