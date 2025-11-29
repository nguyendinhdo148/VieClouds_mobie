import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class MIResult {
  final String dominantIntelligence;
  final Map<String, int> allIntelligences;
  final String gender;
  final String profile;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> careers;
  final String advice;
  final Map<String, dynamic>? answerPatterns;
  final bool isFallback;
  final String? timestamp;

  MIResult({
    required this.dominantIntelligence,
    required this.allIntelligences,
    required this.gender,
    required this.profile,
    required this.strengths,
    required this.improvements,
    required this.careers,
    required this.advice,
    this.answerPatterns,
    this.isFallback = false,
    this.timestamp,
  });

  factory MIResult.fromJson(Map<String, dynamic> json) {
    return MIResult(
      dominantIntelligence: json['dominantIntelligence'] ?? '',
      allIntelligences: Map<String, int>.from(json['allIntelligences'] ?? {}),
      gender: json['gender'] ?? '',
      profile: json['profile'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
      careers: List<String>.from(json['careers'] ?? []),
      advice: json['advice'] ?? '',
      answerPatterns: json['answerPatterns'],
      isFallback: json['isFallback'] ?? false,
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dominantIntelligence': dominantIntelligence,
      'allIntelligences': allIntelligences,
      'gender': gender,
      'profile': profile,
      'strengths': strengths,
      'improvements': improvements,
      'careers': careers,
      'advice': advice,
      'answerPatterns': answerPatterns,
      'isFallback': isFallback,
      'timestamp': timestamp,
    };
  }
}

class MIService {
  final String baseUrl = ApiConfig.baseUrl;
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  static const List<String> intelligenceTypes = [
    'Vận động', 'Âm nhạc', 'Thiên nhiên', 'Không gian', 
    'Triết học', 'Ngôn ngữ', 'Xã hội', 'Nội tâm', 'Logic'
  ];

  // Thêm token vào headers nếu có
  void setToken(String token) {
    headers['Authorization'] = 'Bearer $token';
  }

  // Xóa token khỏi headers
  void removeToken() {
    headers.remove('Authorization');
  }

  // Phân tích MI cơ bản
  Future<MIResult> analyzeMIBasic({
    required List<int> answers,
    required String gender,
  }) async {
    try {
      final scores = _calculateMIScores(answers);
      final dominantType = _getDominantType(scores);

      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.miBasicAnalysis}'),
        headers: headers,
        body: jsonEncode({
          'answers': answers,
          'gender': gender,
          'miScores': scores,
          'dominantIntelligence': dominantType,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return MIResult.fromJson(responseData);
      } else {
        // Fallback
        return _generateFallbackMIAnalysis(answers, gender);
      }
    } catch (e) {
      // Fallback khi có lỗi
      return _generateFallbackMIAnalysis(answers, gender);
    }
  }

  // Phân tích MI nâng cao
  Future<MIResult> analyzeMIAdvanced({
    required List<int> answers,
    required String gender,
  }) async {
    try {
      final scores = _calculateMIScores(answers);
      final dominantType = _getDominantType(scores);
      final patterns = _analyzeMIAnswerPatterns(answers, scores);

      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.miAdvancedAnalysis}'),
        headers: headers,
        body: jsonEncode({
          'answers': answers,
          'gender': gender,
          'miScores': scores,
          'dominantIntelligence': dominantType,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return MIResult.fromJson(responseData);
      } else {
        // Fallback với patterns
        return _generateAdvancedFallbackMIAnalysis(answers, gender, patterns);
      }
    } catch (e) {
      final scores = _calculateMIScores(answers);
      final patterns = _analyzeMIAnswerPatterns(answers, scores);
      return _generateAdvancedFallbackMIAnalysis(answers, gender, patterns);
    }
  }

  // Tính điểm MI
  Map<String, int> _calculateMIScores(List<int> answers) {
    final scores = <String, int>{};
    for (final type in intelligenceTypes) {
      scores[type] = 0;
    }

    // Simple scoring - bạn có thể customize theo logic thực tế
    for (int i = 0; i < answers.length; i++) {
      final typeIndex = i % intelligenceTypes.length;
      final type = intelligenceTypes[typeIndex];
      scores[type] = scores[type]! + (answers[i] + 1); // Convert -1,0,1 to 0,1,2
    }

    // Normalize to 0-100
    final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
    final minScore = scores.values.reduce((a, b) => a < b ? a : b);

    if (maxScore == minScore) {
      for (final type in intelligenceTypes) {
        scores[type] = 50;
      }
    } else {
      for (final type in intelligenceTypes) {
        scores[type] = ((scores[type]! - minScore) / (maxScore - minScore) * 100).round();
      }
    }

    return scores;
  }

  String _getDominantType(Map<String, int> scores) {
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Phân tích pattern cho MI
  Map<String, dynamic> _analyzeMIAnswerPatterns(List<int> answers, Map<String, int> scores) {
    final scoreValues = scores.values.toList();
    final maxScore = scoreValues.reduce((a, b) => a > b ? a : b);
    final minScore = scoreValues.reduce((a, b) => a < b ? a : b);

    return {
      'scoreRange': '$minScore-$maxScore',
      'dominantDifference': maxScore - minScore,
      'consistency': _calculateMIConsistency(answers),
      'extremeResponses': answers.where((a) => a == 0 || a == 1).length,
      'learningStyle': _determineLearningStyle(scores),
    };
  }

  double _calculateMIConsistency(List<int> answers) {
    final validAnswers = answers.where((a) => a != -1);
    if (validAnswers.isEmpty) return 0.0;

    final avg = validAnswers.reduce((a, b) => a + b) / validAnswers.length;
    final variance = validAnswers.map((a) => (a - avg) * (a - avg)).reduce((a, b) => a + b) / validAnswers.length;
    return (1 - variance / 4).clamp(0.0, 1.0);
  }

  String _determineLearningStyle(Map<String, int> scores) {
    final bodily = scores['Vận động'] ?? 0;
    final musical = scores['Âm nhạc'] ?? 0;
    final spatial = scores['Không gian'] ?? 0;

    if (bodily > musical && bodily > spatial) return "Học qua vận động";
    if (musical > bodily && musical > spatial) return "Học qua âm nhạc";
    if (spatial > bodily && spatial > musical) return "Học qua hình ảnh";
    return "Học đa phương thức";
  }

  // Fallback analysis cho MI
  MIResult _generateFallbackMIAnalysis(List<int> answers, String gender) {
    final scores = _calculateMIScores(answers);
    final dominantType = _getDominantType(scores);

    return MIResult(
      dominantIntelligence: dominantType,
      allIntelligences: scores,
      gender: gender,
      profile: 'Bạn có xu hướng nổi trội về $dominantType. Đây là loại trí thông minh đặc biệt giúp bạn phát triển trong nhiều lĩnh vực.',
      strengths: [
        'Khả năng ${dominantType.toLowerCase()} vượt trội',
        'Tư duy phân tích tốt',
        'Khả năng học hỏi nhanh'
      ],
      improvements: [
        'Phát triển kỹ năng giao tiếp',
        'Rèn luyện tư duy sáng tạo',
        'Nâng cao khả năng làm việc nhóm'
      ],
      careers: ['Nhà phân tích', 'Chuyên gia tư vấn', 'Quản lý dự án'],
      advice: 'Tập trung phát triển kỹ năng ${dominantType.toLowerCase()} thông qua thực hành và học tập chuyên sâu.',
      isFallback: true,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  // Advanced fallback analysis cho MI
  MIResult _generateAdvancedFallbackMIAnalysis(
    List<int> answers, 
    String gender, 
    Map<String, dynamic> patterns
  ) {
    final scores = _calculateMIScores(answers);
    final dominantType = _getDominantType(scores);

    // Tự động gợi ý cải thiện dựa trên 3 loại điểm thấp nhất
    final sortedScores = scores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final improvements = sortedScores.take(3).map(
      (entry) => 'Phát triển trí thông minh ${entry.key.toLowerCase()} thông qua các hoạt động liên quan'
    ).toList();

    return MIResult(
      dominantIntelligence: dominantType,
      allIntelligences: scores,
      gender: gender,
      profile: '''
Phân tích chi tiết về trí thông minh của bạn:

**Trí thông minh nổi trội:** $dominantType
**Phong cách học tập:** ${patterns['learningStyle']}
**Phạm vi điểm số:** ${patterns['scoreRange']}

Bạn có tiềm năng phát triển mạnh trong các lĩnh vực liên quan đến $dominantType.
''',
      strengths: [
        'Khả năng ${dominantType.toLowerCase()} xuất sắc',
        'Tư duy đa chiều và sáng tạo',
        'Khả năng thích ứng linh hoạt',
        'Học hỏi và phát triển nhanh'
      ],
      improvements: improvements,
      careers: _getSuggestedCareers(dominantType),
      advice: '''
Dựa trên kết quả phân tích:

🎯 **Chiến lược phát triển:**
- Tập trung vào các hoạt động phát triển $dominantType
- Kết hợp ${patterns['learningStyle']} vào quá trình học tập
- Khám phá các lĩnh vực liên quan đến điểm mạnh của bạn

📊 **Thống kê trả lời:**
- Độ nhất quán: ${(patterns['consistency'] * 100).round()}%
- Phong cách học: ${patterns['learningStyle']}
''',
      answerPatterns: patterns,
      isFallback: true,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  // Gợi ý nghề nghiệp dựa trên loại trí thông minh
  List<String> _getSuggestedCareers(String dominantType) {
    final careerSuggestions = {
      'Vận động': ['Vận động viên', 'Bác sĩ phẫu thuật', 'Nghệ sĩ múa', 'Thợ thủ công'],
      'Âm nhạc': ['Nhạc sĩ', 'Ca sĩ', 'Nhà sản xuất âm nhạc', 'Giáo viên âm nhạc'],
      'Thiên nhiên': ['Nhà sinh vật học', 'Nhà bảo tồn', 'Nông dân', 'Kiến trúc sư cảnh quan'],
      'Không gian': ['Kiến trúc sư', 'Họa sĩ', 'Kỹ sư', 'Nhà thiết kế đồ họa'],
      'Triết học': ['Triết gia', 'Nhà văn', 'Giáo sư', 'Nhà nghiên cứu'],
      'Ngôn ngữ': ['Nhà văn', 'Biên tập viên', 'Phiên dịch', 'Luật sư'],
      'Xã hội': ['Giáo viên', 'Tư vấn viên', 'Nhân viên xã hội', 'Quản lý nhân sự'],
      'Nội tâm': ['Nhà tâm lý học', 'Nhà văn', 'Nghiên cứu viên', 'Triết gia'],
      'Logic': ['Nhà toán học', 'Lập trình viên', 'Kỹ sư', 'Nhà khoa học'],
    };

    return careerSuggestions[dominantType] ?? [
      'Chuyên gia phân tích',
      'Nhà tư vấn',
      'Quản lý dự án'
    ];
  }

  // Lấy danh sách các loại trí thông minh
  Future<List<String>> getIntelligenceTypes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.miIntelligenceTypes}'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return List<String>.from(responseData['types'] ?? intelligenceTypes);
      } else {
        return intelligenceTypes;
      }
    } catch (e) {
      return intelligenceTypes;
    }
  }
}