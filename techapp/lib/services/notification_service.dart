import '../config/api_config.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  /// Lấy danh sách toàn bộ thông báo của người dùng
  static Future<List<NotificationModel>> getNotifications() async {
    final res = await ApiService.get(ApiConfig.notifications);
    if (res is List) {
      return res.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Lấy số lượng thông báo chưa đọc
  static Future<int> getUnreadCount() async {
    final res = await ApiService.get('${ApiConfig.notifications}/unread-count');
    if (res is Map && res.containsKey('unreadCount')) {
      return (res['unreadCount'] as num).toInt();
    }
    return 0;
  }

  /// Đánh dấu một thông báo là đã đọc
  static Future<void> markAsRead(int notificationId) async {
    await ApiService.put('${ApiConfig.notifications}/$notificationId/read');
  }

  /// Đánh dấu tất cả thông báo là đã đọc
  static Future<void> markAllAsRead() async {
    await ApiService.put('${ApiConfig.notifications}/read-all');
  }
}
