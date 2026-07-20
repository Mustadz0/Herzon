// Fix #6: added copyWith so markAsRead/markAllAsRead don't rebuild manually.
class NotificationModel {
  final String id;
  final String? userId;
  final String? adminId;
  final String type;
  final String recipientType;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    this.userId,
    this.adminId,
    required this.type,
    this.recipientType = 'user',
    required this.title,
    required this.body,
    this.data = const {},
    this.isRead = false,
    this.createdAt,
  });

  bool get isAdminNotification => recipientType == 'admin';

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? adminId,
    String? type,
    String? recipientType,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      adminId: adminId ?? this.adminId,
      type: type ?? this.type,
      recipientType: recipientType ?? this.recipientType,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      adminId: json['admin_id'] as String?,
      type: json['type'] as String,
      recipientType: json['recipient_type'] as String? ?? 'user',
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'admin_id': adminId,
      'type': type,
      'recipient_type': recipientType,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
