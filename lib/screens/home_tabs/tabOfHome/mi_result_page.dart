import 'package:flutter/material.dart';

class MIResultPage extends StatelessWidget {
  final Map<String, dynamic> result;

  const MIResultPage({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dominantIntelligence = result['dominantIntelligence'] ?? 'UNKNOWN';
    final gender = result['gender'] ?? '';
    final allIntelligences = Map<String, int>.from(result['allIntelligences'] ?? {});
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết Quả Đa Trí Tuệ'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.teal.shade50],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(dominantIntelligence, gender),
              const SizedBox(height: 24),
              
              _buildIntelligenceScores(allIntelligences),
              const SizedBox(height: 24),
              
              _buildSection(
                title: 'Hồ Sơ Trí Thông Minh',
                content: result['profile'] ?? '',
                color: Colors.indigo,
              ),
              
              const SizedBox(height: 16),
              
              Column(
                children: [
                  _buildStrengths(),
                  const SizedBox(height: 16),
                  _buildImprovements(),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildCareers(),
              const SizedBox(height: 24),
              
              _buildSection(
                title: 'Lời Khuyên Phát Triển',
                content: result['advice'] ?? '',
                color: Colors.teal,
              ),
              
              if (result['answerPatterns'] != null) 
                _buildAnswerPatterns(result['answerPatterns']),
              
              const SizedBox(height: 32),
              
              _buildActionButtons(context),
              
              _buildFooterNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String dominantIntelligence, String gender) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade600, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text(
              'Kết Quả Trắc Nghiệm Đa Trí Tuệ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              dominantIntelligence,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Trí thông minh nổi trội ${gender == 'male' ? 'nam' : 'nữ'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getIntelligenceDescription(dominantIntelligence),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntelligenceScores(Map<String, int> intelligences) {
    final sortedIntelligences = intelligences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 12),
          child: Text(
            'Điểm Số Các Loại Trí Thông Minh',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: sortedIntelligences.map((entry) {
                final intelligence = entry.key;
                final score = entry.value;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              intelligence,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '$score%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(score),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: score / 100,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  color: color,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16, 
                height: 1.5,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengths() {
    final strengths = (result['strengths'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text(
                  'Điểm Mạnh Nổi Bật',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: strengths.map((strength) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _cleanText(strength),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovements() {
    final improvements = (result['improvements'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text(
                  'Điểm Cần Cải Thiện',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: improvements.map((improvement) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _cleanText(improvement),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareers() {
    final careers = (result['careers'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.work, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Nghề Nghiệp Phù Hợp',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: careers.map((career) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  career,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerPatterns(Map<String, dynamic> patterns) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.grey, size: 24),
                SizedBox(width: 8),
                Text(
                  'Phân Tích Kiểu Trả Lời',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildPatternItem(
                  'Độ Nhất Quán',
                  '${((patterns['consistency'] ?? 0.0) * 100).round()}%',
                  Colors.green,
                  patterns['consistency'] ?? 0.0,
                ),
                const SizedBox(height: 12),
                _buildPatternItem(
                  'Phong Cách Học Tập',
                  patterns['learningStyle'] ?? 'Không xác định',
                  Colors.blue,
                  null,
                ),
                const SizedBox(height: 12),
                _buildPatternItem(
                  'Phạm Vi Điểm Số',
                  patterns['scoreRange'] ?? '0-0',
                  Colors.orange,
                  null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternItem(String title, String value, Color color, double? progress) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          if (progress != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/mi-test');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text('Làm Lại Trắc Nghiệm'),
        ),
      ],
    );
  }

  Widget _buildFooterNote() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            '💡 Lưu ý',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Kết quả này chỉ mang tính chất tham khảo, dựa trên thuyết Đa trí tuệ của Howard Gardner. '
            'Mỗi người đều sở hữu nhiều loại trí thông minh khác nhau với mức độ phát triển khác nhau.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getIntelligenceDescription(String intelligence) {
    final descriptions = {
      'Vận động': 'Khả năng sử dụng cơ thể một cách khéo léo, phối hợp tay mắt tốt',
      'Âm nhạc': 'Nhạy cảm với âm thanh, nhịp điệu và giai điệu',
      'Thiên nhiên': 'Hiểu và kết nối với thiên nhiên, động thực vật',
      'Không gian': 'Khả năng hình dung, tưởng tượng không gian 3D',
      'Triết học': 'Suy nghĩ sâu sắc về các vấn đề triết học và ý nghĩa cuộc sống',
      'Ngôn ngữ': 'Khả năng sử dụng ngôn ngữ linh hoạt và hiệu quả',
      'Xã hội': 'Khả năng hiểu và tương tác tốt với người khác',
      'Nội tâm': 'Hiểu rõ bản thân, cảm xúc và mục tiêu cá nhân',
      'Logic': 'Tư duy logic, phân tích và giải quyết vấn đề',
    };
    
    return descriptions[intelligence] ?? 'Loại trí thông minh đặc biệt';
  }

  String _cleanText(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('* ', '')
        .replaceAll('*', '')
        .trim();
  }
}