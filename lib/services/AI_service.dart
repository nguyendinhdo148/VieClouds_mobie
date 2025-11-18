// services/AI_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AIResponse {
  final bool success;
  final String? description;
  final String? feedback;
  final String? answer;
  final String? message;

  AIResponse({
    required this.success,
    this.description,
    this.feedback,
    this.answer,
    this.message,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      success: json['success'] ?? false,
      description: json['description'],
      feedback: json['feedback'],
      answer: json['answer'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'description': description,
      'feedback': feedback,
      'answer': answer,
      'message': message,
    };
  }
}

class AIService {
  final String baseUrl = ApiConfig.baseUrl;
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  // Thêm token vào headers nếu có
  void setToken(String token) {
    headers['Authorization'] = 'Bearer $token';
  }

  // Xóa token khỏi headers
  void removeToken() {
    headers.remove('Authorization');
  }

  // Chat với AI (không yêu cầu đăng nhập)
  Future<AIResponse> chatWithAI({
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.chatWithAI}'),
        headers: headers,
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        return AIResponse.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        return AIResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to chat with AI: ${response.statusCode}',
        );
      }
    } catch (e) {
      return AIResponse(
        success: false,
        message: 'Error chatting with AI: $e',
      );
    }
  }

  // Các method khác (generateJobDescription, reviewResume, chatWithContext, ...)...
  // (Bạn có thể giữ lại các method khác từ file cũ nếu cần)
}

/// -----------------------
/// Helper class để quản lý chat history (đã mở rộng)
/// -----------------------
class ChatMessage {
  final String id; // định danh duy nhất
  final String role; // 'user' hoặc 'assistant' hoặc 'bot'
  String content;
  final DateTime timestamp;
  bool isTemporary; // true nếu là temporary local message (chưa được server xác nhận)

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isTemporary = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isTemporary': isTemporary,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isTemporary: json['isTemporary'] ?? false,
    );
  }
}

class AIChatSession {
  final AIService _aiService = AIService();
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  // Thêm tin nhắn (thường dùng cho assistant hoặc bot)
  void addMessage(String role, String content, {String? id, bool isTemporary = false}) {
    final msgId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _messages.add(ChatMessage(id: msgId, role: role, content: content, isTemporary: isTemporary));
  }

  // Thêm temporary user message (trả về tempId để dùng sau khi server trả về)
  String addTemporaryUserMessage(String content) {
    final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    _messages.add(ChatMessage(id: tempId, role: 'user', content: content, isTemporary: true));
    return tempId;
  }

  // Khi server trả về, thay thế hoặc mark message temporary -> confirmed
  void confirmTemporaryMessage(String tempId) {
    final idx = _messages.indexWhere((m) => m.id == tempId);
    if (idx != -1) {
      _messages[idx].isTemporary = false;
      // nếu muốn, có thể cập nhật timestamp hoặc content ở đây
    }
  }

  // Nếu server trả lỗi và muốn remove temporary message
  void removeTemporaryMessage(String tempId) {
    _messages.removeWhere((m) => m.id == tempId);
  }

  // Chat với AI và lưu lịch sử
  // Nếu tempId được cung cấp, thì sẽ KHÔNG thêm duplicate user message
  Future<AIResponse> sendMessage(String message, {String? token, String? tempId}) async {
    try {
      // nếu không có tempId, phương thức sẽ tự thêm user message (backwards-compatible)
      if (tempId == null) {
        addMessage('user', message);
      } else {
        // mark temporary message as confirmed (keeps same content)
        confirmTemporaryMessage(tempId);
      }

      // Gọi service
      final response = await _aiService.chatWithAI(message: message);

      if (response.success && response.answer != null) {
        // Thêm phản hồi AI vào lịch sử
        addMessage('assistant', response.answer!);
      }

      return response;
    } catch (e) {
      return AIResponse(success: false, message: 'Error chatting with AI: $e');
    }
  }

  // Xóa lịch sử chat
  void clearHistory() {
    _messages.clear();
  }

  // Lấy số lượng tin nhắn
  int get messageCount => _messages.length;

  // Export chat history
  List<Map<String, dynamic>> exportHistory() {
    return _messages.map((msg) => msg.toJson()).toList();
  }

  // Import chat history
  void importHistory(List<Map<String, dynamic>> history) {
    _messages.clear();
    _messages.addAll(history.map((msg) => ChatMessage.fromJson(msg)));
  }

  // Lấy tin nhắn gần đây nhất
  ChatMessage? get lastMessage => _messages.isNotEmpty ? _messages.last : null;

  // Kiểm tra xem session có trống không
  bool get isEmpty => _messages.isEmpty;

  // Lấy tin nhắn theo index
  ChatMessage getMessageAt(int index) {
    return _messages[index];
  }
}

// Exception classes cho AI service (giữ nguyên)
class AIServiceException implements Exception {
  final String message;
  final int? statusCode;

  AIServiceException(this.message, {this.statusCode});

  @override
  String toString() => 'AIServiceException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class AIResponseException implements Exception {
  final String message;
  final AIResponse response;

  AIResponseException(this.response, this.message);

  @override
  String toString() => 'AIResponseException: $message';
}
