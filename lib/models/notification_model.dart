// models/notification_model.dart
class ChatNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;

  ChatNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatNotification.fromJson(Map<String, dynamic> json) {
    return ChatNotification(
      id: json['id'] ?? json['_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  ChatNotification markAsRead() {
    return ChatNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      data: data,
      timestamp: timestamp,
      isRead: true,
    );
  }

  bool get isMessageNotification => type == 'message';
  bool get isApplicationNotification => type == 'application';
  bool get isInterviewNotification => type == 'interview';
  bool get isSystemNotification => type == 'system';
}