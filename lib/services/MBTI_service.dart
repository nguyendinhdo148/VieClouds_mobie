import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class MBTIResult {
  final String type;
  final String gender;
  final String overview;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> careers;
  final String advice;
  final Map<String, dynamic>? answerPatterns;
  final String? source;
  final String? timestamp;

  MBTIResult({
    required this.type,
    required this.gender,
    required this.overview,
    required this.strengths,
    required this.weaknesses,
    required this.careers,
    required this.advice,
    this.answerPatterns,
    this.source,
    this.timestamp,
  });

  factory MBTIResult.fromJson(Map<String, dynamic> json) {
    return MBTIResult(
      type: json['type'] ?? '',
      gender: json['gender'] ?? '',
      overview: json['overview'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      careers: List<String>.from(json['careers'] ?? []),
      advice: json['advice'] ?? '',
      answerPatterns: json['answerPatterns'],
      source: json['source'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'gender': gender,
      'overview': overview,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'careers': careers,
      'advice': advice,
      'answerPatterns': answerPatterns,
      'source': source,
      'timestamp': timestamp,
    };
  }
}

class MBTIService {
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

  // Phân tích MBTI cơ bản
  Future<MBTIResult> analyzeMBTIBasic({
    required String gender,
    required String mbtiType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.mbtiBasicAnalysis}'),
        headers: headers,
        body: jsonEncode({
          'gender': gender,
          'mbtiType': mbtiType,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return MBTIResult.fromJson(responseData);
      } else {
        // Fallback khi API fail
        return _generateFallbackMBTIResult(mbtiType, gender);
      }
    } catch (e) {
      // Fallback khi có lỗi
      return _generateFallbackMBTIResult(mbtiType, gender);
    }
  }

  // Phân tích MBTI nâng cao
  Future<MBTIResult> analyzeMBTIAdvanced({
    required List<int> answers,
    required String gender,
    required String mbtiType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.mbtiAdvancedAnalysis}'),
        headers: headers,
        body: jsonEncode({
          'answers': answers,
          'gender': gender,
          'mbtiType': mbtiType,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return MBTIResult.fromJson(responseData);
      } else {
        // Fallback với phân tích pattern
        final patterns = _analyzeAnswerPatterns(answers);
        return _generateAdvancedFallbackMBTIResult(mbtiType, gender, patterns);
      }
    } catch (e) {
      final patterns = _analyzeAnswerPatterns(answers);
      return _generateAdvancedFallbackMBTIResult(mbtiType, gender, patterns);
    }
  }

  // Phân tích pattern từ answers
  Map<String, dynamic> _analyzeAnswerPatterns(List<int> answers) {
    final validAnswers = answers.where((a) => a != -1).toList();
    final len = validAnswers.length;
    
    return {
      'consistency': _calculateConsistency(validAnswers),
      'decisiveness': len / answers.length,
      'extremeResponses': validAnswers.where((a) => a == 0 || a == 1).length,
      'neutralCount': answers.where((a) => a == -1).length,
      'preferenceTrend': _calculateTrend(validAnswers),
    };
  }

  double _calculateConsistency(List<int> answers) {
    if (answers.isEmpty) return 0.5;
    final avg = answers.reduce((a, b) => a + b) / answers.length;
    final variance = answers.map((a) => (a - avg) * (a - avg)).reduce((a, b) => a + b) / answers.length;
    return (1 - (variance / 4)).clamp(0.0, 1.0);
  }

  String _calculateTrend(List<int> answers) {
    if (answers.isEmpty) return "Không có xu hướng rõ ràng";
    final count1 = answers.where((a) => a == 1).length;
    final ratio = count1 / answers.length;
    
    if (ratio > 0.7) return "Xu hướng hướng ngoại, yêu thích sự mới mẻ";
    if (ratio < 0.3) return "Xu hướng hướng nội, thiên về ổn định";
    return "Sự cân bằng giữa hướng nội và hướng ngoại";
  }

  // Fallback result cho basic analysis
  MBTIResult _generateFallbackMBTIResult(String mbtiType, String gender) {
    return MBTIResult(
      type: mbtiType,
      gender: gender,
      overview: '''
**Tổng quan $mbtiType:**
Tính cách đặc trưng với điểm mạnh riêng biệt, phong cách giao tiếp và làm việc độc đáo, khả năng thích ứng với môi trường linh hoạt.
''',
      strengths: [
        'Tư duy sáng tạo và linh hoạt',
        'Khả năng giải quyết vấn đề tốt',
        'Cam kết với công việc và mục tiêu'
      ],
      weaknesses: [
        'Đôi khi quá cầu toàn',
        'Cần phát triển kỹ năng giao tiếp',
        'Học cách linh hoạt hơn trong công việc'
      ],
      careers: [
        'Quản lý dự án',
        'Phát triển sản phẩm', 
        'Tư vấn chiến lược',
        'Nhà nghiên cứu'
      ],
      advice: 'Tập trung phát triển điểm mạnh và cải thiện điểm yếu. Tìm kiếm môi trường làm việc phù hợp với tính cách của bạn.',
      source: 'Fallback System',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  // Fallback result cho advanced analysis
  MBTIResult _generateAdvancedFallbackMBTIResult(
    String mbtiType, 
    String gender, 
    Map<String, dynamic> patterns
  ) {
    return MBTIResult(
      type: mbtiType,
      gender: gender,
      overview: 'Phân tích tính cách $mbtiType dựa trên câu trả lời của bạn. Đây là nhóm tính cách có nhiều tiềm năng phát triển.',
      strengths: [
        'Tư duy logic và phân tích',
        'Khả năng ra quyết định nhanh',
        'Làm việc độc lập hiệu quả',
        'Khả năng học hỏi nhanh'
      ],
      weaknesses: [
        'Cần phát triển kỹ năng giao tiếp',
        'Học cách linh hoạt hơn trong công việc',
        'Cân bằng giữa công việc và cuộc sống'
      ],
      careers: [
        'Nhà phân tích hệ thống',
        'Lập trình viên',
        'Quản lý dự án',
        'Chuyên gia tư vấn',
        'Nhà nghiên cứu'
      ],
      advice: '''
Dựa trên phân tích câu trả lời của bạn:
- ${patterns['preferenceTrend']}
- Mức độ nhất quán: ${(patterns['consistency'] * 100).round()}%

Hãy tập trung vào các lĩnh vực phát triển phù hợp với tính cách $mbtiType.
''',
      answerPatterns: patterns,
      source: 'Fallback Advanced System',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  // Tính toán MBTI type từ answers
  String calculateMBTIType(List<int> answers) {
    if (answers.length < 40) return 'UNKNOWN';
    
    // Tính điểm cho 4 cặp dimension
    final eCount = answers.sublist(0, 10).where((a) => a == 1).length;
    final iCount = answers.sublist(0, 10).where((a) => a == 0).length;
    
    final sCount = answers.sublist(10, 20).where((a) => a == 1).length;
    final nCount = answers.sublist(10, 20).where((a) => a == 0).length;
    
    final tCount = answers.sublist(20, 30).where((a) => a == 1).length;
    final fCount = answers.sublist(20, 30).where((a) => a == 0).length;
    
    final jCount = answers.sublist(30, 40).where((a) => a == 1).length;
    final pCount = answers.sublist(30, 40).where((a) => a == 0).length;

    String mbti = '';
    mbti += eCount > iCount ? 'E' : 'I';
    mbti += sCount > nCount ? 'S' : 'N';
    mbti += tCount > fCount ? 'T' : 'F';
    mbti += jCount > pCount ? 'J' : 'P';

    return mbti;
  }
}