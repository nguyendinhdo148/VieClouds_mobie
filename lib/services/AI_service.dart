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
  final Map<String, dynamic>? resumeAnalysis; // Thêm field cho phân tích CV

  AIResponse({
    required this.success,
    this.description,
    this.feedback,
    this.answer,
    this.message,
    this.resumeAnalysis,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      success: json['success'] ?? false,
      description: json['description'],
      feedback: json['feedback'],
      answer: json['answer'],
      message: json['message'],
      resumeAnalysis: json['resume_analysis'] ?? json['analysis'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'description': description,
      'feedback': feedback,
      'answer': answer,
      'message': message,
      'resume_analysis': resumeAnalysis,
    };
  }
}

class ResumeReviewRequest {
  final String resumeText;
  final String? jobDescription;
  final String? targetPosition;
  final int? maxFeedbackLength;

  ResumeReviewRequest({
    required this.resumeText,
    this.jobDescription,
    this.targetPosition,
    this.maxFeedbackLength,
  });

  Map<String, dynamic> toJson() {
    return {
      'resume_text': resumeText,
      'job_description': jobDescription,
      'target_position': targetPosition,
      'max_feedback_length': maxFeedbackLength,
    };
  }
}

class ResumeAnalysis {
  final double overallScore;
  final String summary;
  final List<String> strengths;
  final List<String> improvements;
  final Map<String, dynamic>? sectionScores;
  final String? suggestedOptimizations;
  final String? atsCompatibility;

  ResumeAnalysis({
    required this.overallScore,
    required this.summary,
    required this.strengths,
    required this.improvements,
    this.sectionScores,
    this.suggestedOptimizations,
    this.atsCompatibility,
  });

  factory ResumeAnalysis.fromJson(Map<String, dynamic> json) {
    return ResumeAnalysis(
      overallScore: (json['overall_score'] ?? json['score'] ?? 0.0).toDouble(),
      summary: json['summary'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
      sectionScores: json['section_scores'],
      suggestedOptimizations: json['suggested_optimizations'],
      atsCompatibility: json['ats_compatibility'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall_score': overallScore,
      'summary': summary,
      'strengths': strengths,
      'improvements': improvements,
      'section_scores': sectionScores,
      'suggested_optimizations': suggestedOptimizations,
      'ats_compatibility': atsCompatibility,
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

  // Đánh giá và phân tích CV
  Future<AIResponse> reviewResume(ResumeReviewRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.resumeReview}'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Xử lý response để tạo ResumeAnalysis
        if (responseData['resume_analysis'] != null || responseData['analysis'] != null) {
          final analysisData = responseData['resume_analysis'] ?? responseData['analysis'];
          final resumeAnalysis = ResumeAnalysis.fromJson(analysisData);
          
          return AIResponse(
            success: true,
            message: responseData['message'] ?? 'Resume reviewed successfully',
            resumeAnalysis: resumeAnalysis.toJson(),
          );
        } else {
          // Fallback: nếu API trả về dạng khác
          return AIResponse.fromJson(responseData);
        }
      } else {
        final errorData = jsonDecode(response.body);
        return AIResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to review resume: ${response.statusCode}',
        );
      }
    } catch (e) {
      return AIResponse(
        success: false,
        message: 'Error reviewing resume: $e',
      );
    }
  }

  // Phương thức tiện ích để review resume với các tham số đơn giản
  Future<AIResponse> reviewResumeSimple({
    required String resumeText,
    String? jobDescription,
    String? targetPosition,
  }) async {
    final request = ResumeReviewRequest(
      resumeText: resumeText,
      jobDescription: jobDescription,
      targetPosition: targetPosition,
    );
    
    return await reviewResume(request);
  }

  // Generate job description (giữ nguyên từ file cũ nếu có)
  Future<AIResponse> generateJobDescription({
    required String jobTitle,
    required String companyName,
    required String location,
    required String jobType,
    required String experienceLevel,
    required List<String> skills,
    String? companyDescription,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.generateDescription}'),
        headers: headers,
        body: jsonEncode({
          'job_title': jobTitle,
          'company_name': companyName,
          'location': location,
          'job_type': jobType,
          'experience_level': experienceLevel,
          'skills': skills,
          'company_description': companyDescription,
        }),
      );

      if (response.statusCode == 200) {
        return AIResponse.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        return AIResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to generate job description: ${response.statusCode}',
        );
      }
    } catch (e) {
      return AIResponse(
        success: false,
        message: 'Error generating job description: $e',
      );
    }
  }

  // Review resume với context của job (nếu cần)
  Future<AIResponse> reviewResumeForJob({
    required String resumeText,
    required String jobDescription,
    required String jobTitle,
  }) async {
    final request = ResumeReviewRequest(
      resumeText: resumeText,
      jobDescription: jobDescription,
      targetPosition: jobTitle,
      maxFeedbackLength: 500,
    );
    
    return await reviewResume(request);
  }
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
  final Map<String, dynamic>? metadata; // Thêm metadata cho các loại message đặc biệt

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isTemporary = false,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isTemporary': isTemporary,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isTemporary: json['isTemporary'] ?? false,
      metadata: json['metadata'],
    );
  }
}

class AIChatSession {
  final AIService _aiService = AIService();
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  // Thêm tin nhắn (thường dùng cho assistant hoặc bot)
  void addMessage(String role, String content, {String? id, bool isTemporary = false, Map<String, dynamic>? metadata}) {
    final msgId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _messages.add(ChatMessage(
      id: msgId, 
      role: role, 
      content: content, 
      isTemporary: isTemporary,
      metadata: metadata,
    ));
  }

  // Thêm temporary user message (trả về tempId để dùng sau khi server trả về)
  String addTemporaryUserMessage(String content, {Map<String, dynamic>? metadata}) {
    final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    _messages.add(ChatMessage(
      id: tempId, 
      role: 'user', 
      content: content, 
      isTemporary: true,
      metadata: metadata,
    ));
    return tempId;
  }

  // Thêm message phân tích CV
  void addResumeAnalysisMessage(ResumeAnalysis analysis) {
    final metadata = {
      'type': 'resume_analysis',
      'analysis': analysis.toJson(),
    };
    
    final content = _formatResumeAnalysisContent(analysis);
    
    addMessage('assistant', content, metadata: metadata);
  }

  String _formatResumeAnalysisContent(ResumeAnalysis analysis) {
    final buffer = StringBuffer();
    
    buffer.writeln('📊 **Đánh giá CV của bạn:**');
    buffer.writeln('**Điểm tổng quan:** ${(analysis.overallScore * 10).toInt()}/10');
    buffer.writeln();
    
    buffer.writeln('**Tóm tắt:** ${analysis.summary}');
    buffer.writeln();
    
    if (analysis.strengths.isNotEmpty) {
      buffer.writeln('✅ **Điểm mạnh:**');
      for (final strength in analysis.strengths) {
        buffer.writeln('• $strength');
      }
      buffer.writeln();
    }
    
    if (analysis.improvements.isNotEmpty) {
      buffer.writeln('💡 **Điểm cần cải thiện:**');
      for (final improvement in analysis.improvements) {
        buffer.writeln('• $improvement');
      }
      buffer.writeln();
    }
    
    if (analysis.suggestedOptimizations != null) {
      buffer.writeln('🚀 **Gợi ý tối ưu:**');
      buffer.writeln(analysis.suggestedOptimizations!);
    }
    
    return buffer.toString();
  }

  // Khi server trả về, thay thế hoặc mark message temporary -> confirmed
  void confirmTemporaryMessage(String tempId) {
    final idx = _messages.indexWhere((m) => m.id == tempId);
    if (idx != -1) {
      _messages[idx].isTemporary = false;
    }
  }

  // Nếu server trả lỗi và muốn remove temporary message
  void removeTemporaryMessage(String tempId) {
    _messages.removeWhere((m) => m.id == tempId);
  }

  // Chat với AI và lưu lịch sử
  Future<AIResponse> sendMessage(String message, {String? token, String? tempId}) async {
    try {
      if (tempId == null) {
        addMessage('user', message);
      } else {
        confirmTemporaryMessage(tempId);
      }

      if (token != null) {
        _aiService.setToken(token);
      }

      final response = await _aiService.chatWithAI(message: message);

      if (response.success && response.answer != null) {
        addMessage('assistant', response.answer!);
      }

      return response;
    } catch (e) {
      return AIResponse(success: false, message: 'Error chatting with AI: $e');
    }
  }

  // Gửi yêu cầu review CV
  Future<AIResponse> reviewResume({
    required String resumeText,
    String? jobDescription,
    String? targetPosition,
    String? token,
  }) async {
    try {
      final userMessage = 'Tôi muốn đánh giá CV với vị trí: ${targetPosition ?? "chung"}';
      final tempId = addTemporaryUserMessage(userMessage);

      if (token != null) {
        _aiService.setToken(token);
      }

      final request = ResumeReviewRequest(
        resumeText: resumeText,
        jobDescription: jobDescription,
        targetPosition: targetPosition,
      );

      final response = await _aiService.reviewResume(request);

      if (response.success && response.resumeAnalysis != null) {
        confirmTemporaryMessage(tempId);
        final analysis = ResumeAnalysis.fromJson(response.resumeAnalysis!);
        addResumeAnalysisMessage(analysis);
        
        return AIResponse(
          success: true,
          message: response.message,
          resumeAnalysis: response.resumeAnalysis,
        );
      } else {
        removeTemporaryMessage(tempId);
        addMessage('assistant', '❌ Không thể phân tích CV: ${response.message}');
        return response;
      }
    } catch (e) {
      return AIResponse(success: false, message: 'Error reviewing resume: $e');
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

// Exception classes cho AI service
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