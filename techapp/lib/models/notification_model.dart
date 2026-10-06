enum NotificationType { order, promotion, system }

class NotificationModel {
  final int id;
  final String title;
  final String content;
  final NotificationType type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType parseType(String? t) {
      switch (t?.toUpperCase()) {
        case 'PROMOTION':
          return NotificationType.promotion;
        case 'SYSTEM':
          return NotificationType.system;
        case 'ORDER':
        default:
          return NotificationType.order;
      }
    }

    return NotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: parseType(json['type'] as String?),
      referenceId: json['referenceId']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      content: content,
      type: type,
      referenceId: referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
