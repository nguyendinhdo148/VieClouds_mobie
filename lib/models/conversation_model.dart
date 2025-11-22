// models/conversation_model.dart
class Conversation {
  final String id;
  final List<String> participants;
  final String? lastMessageId;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  final List<ConversationParticipant> participantDetails;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessageId,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.participantDetails = const [],
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? json['_id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessageId: json['lastMessageId'],
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.parse(json['lastMessageAt'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : null,
      participantDetails: json['participantDetails'] != null
          ? List<ConversationParticipant>.from(
              json['participantDetails'].map((x) => ConversationParticipant.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'lastMessageId': lastMessageId,
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
      'participantDetails': participantDetails.map((x) => x.toJson()).toList(),
    };
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  ConversationParticipant? getOtherParticipant(String currentUserId) {
    return participantDetails.firstWhere(
      (participant) => participant.userId != currentUserId,
      orElse: () => ConversationParticipant.empty(),
    );
  }

  String getDisplayName(String currentUserId) {
    final otherParticipant = getOtherParticipant(currentUserId);
    return otherParticipant?.name ?? 'Người dùng';
  }

  String? getAvatar(String currentUserId) {
    final otherParticipant = getOtherParticipant(currentUserId);
    return otherParticipant?.avatar;
  }

  String? getCompany(String currentUserId) {
    final otherParticipant = getOtherParticipant(currentUserId);
    return otherParticipant?.company;
  }
}

class ConversationParticipant {
  final String userId;
  final String name;
  final String? avatar;
  final String? company;
  final String role; // 'recruiter' or 'candidate'
  final bool isOnline;
  final DateTime? lastSeen;

  ConversationParticipant({
    required this.userId,
    required this.name,
    this.avatar,
    this.company,
    required this.role,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      company: json['company'],
      role: json['role'] ?? 'candidate',
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'avatar': avatar,
      'company': company,
      'role': role,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  static ConversationParticipant empty() {
    return ConversationParticipant(
      userId: '',
      name: '',
      role: 'candidate',
    );
  }

  bool get isRecruiter => role == 'recruiter';
  bool get isCandidate => role == 'candidate';
}