// models/message_model.dart
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType messageType;
  final DateTime timestamp;
  final MessageStatus status;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.messageType = MessageType.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? json['_id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      messageType: _parseMessageType(json['messageType']),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      status: _parseMessageStatus(json['status']),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'messageType': messageType.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'metadata': metadata,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? messageType,
    DateTime? timestamp,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      case 'interview_invitation':
        return MessageType.interviewInvitation;
      case 'job_offer':
        return MessageType.jobOffer;
      default:
        return MessageType.text;
    }
  }

  static MessageStatus _parseMessageStatus(String? status) {
    switch (status) {
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'seen':
        return MessageStatus.seen;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  static Message empty() {
    return Message(
      id: '',
      conversationId: '',
      senderId: '',
      receiverId: '',
      content: '',
      timestamp: DateTime.now(),
    );
  }

  bool get isText => messageType == MessageType.text;
  bool get isImage => messageType == MessageType.image;
  bool get isFile => messageType == MessageType.file;
  bool get isSystem => messageType == MessageType.system;
  bool get isInterviewInvitation => messageType == MessageType.interviewInvitation;
  bool get isJobOffer => messageType == MessageType.jobOffer;

  bool get isSent => status == MessageStatus.sent;
  bool get isDelivered => status == MessageStatus.delivered;
  bool get isSeen => status == MessageStatus.seen;
  bool get isFailed => status == MessageStatus.failed;
}

enum MessageType {
  text,
  image,
  file,
  system,
  interviewInvitation,
  jobOffer,
}

enum MessageStatus {
  sent,
  delivered,
  seen,
  failed,
}