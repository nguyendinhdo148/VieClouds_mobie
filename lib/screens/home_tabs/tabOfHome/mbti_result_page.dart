import 'package:flutter/material.dart';

class MBTIResultPage extends StatelessWidget {
  final Map<String, dynamic> result;

  const MBTIResultPage({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mbtiType = result['type'] ?? 'UNKNOWN';
    final gender = result['gender'] ?? '';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết Quả MBTI'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.purple.shade50],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              _buildHeader(mbtiType, gender),
              const SizedBox(height: 24),
              
              // MBTI Dimensions
              _buildDimensions(mbtiType),
              const SizedBox(height: 24),
              
              // Overview
              _buildSection(
                title: 'Tổng Quan Tính Cách',
                content: result['overview'] ?? '',
                color: Colors.indigo,
              ),
              
              const SizedBox(height: 16),
              
              // Strengths & Weaknesses
              Column(
                children: [
                  _buildStrengths(),
                  const SizedBox(height: 16),
                  _buildWeaknesses(),
                ],
              ),
              const SizedBox(height: 24),
              
              // Careers
              _buildCareers(),
              const SizedBox(height: 24),
              
              // Advice
              _buildSection(
                title: 'Lời Khuyên Phát Triển',
                content: result['advice'] ?? '',
                color: Colors.purple,
              ),
              
              // Answer Patterns (if available)
              if (result['answerPatterns'] != null) 
                _buildAnswerPatterns(result['answerPatterns']),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              _buildActionButtons(context),
              
              // Footer Note
              _buildFooterNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String mbtiType, String gender) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade600, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text(
              'Kết Quả Trắc Nghiệm MBTI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mbtiType,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loại tính cách ${gender == 'male' ? 'nam' : 'nữ'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensions(String mbtiType) {
    final dimensions = mbtiType.split('');
    final dimensionInfo = {
      'E': {
        'title': 'Hướng ngoại', 
        'desc': 'Năng động, hoạt bát, thích giao tiếp xã hội, được tiếp thêm năng lượng khi tương tác với người khác',
        'fullDesc': 'Người hướng ngoại (E) thường năng động, hoạt bát, thích giao tiếp xã hội. Họ được tiếp thêm năng lượng khi tương tác với người khác, thích làm việc nhóm và dễ dàng kết nối với mọi người.',
        'color': Colors.blue,
      },
      'I': {
        'title': 'Hướng nội', 
        'desc': 'Suy tư, độc lập, thích không gian riêng, được tiếp thêm năng lượng khi ở một mình',
        'fullDesc': 'Người hướng nội (I) thường suy tư, độc lập, thích không gian riêng. Họ được tiếp thêm năng lượng khi ở một mình, làm việc tốt trong môi trường yên tĩnh và có khả năng tập trung sâu.',
        'color': Colors.indigo,
      },
      'S': {
        'title': 'Giác quan', 
        'desc': 'Thực tế, cụ thể, tập trung vào hiện tại, chú ý đến chi tiết và thông tin thực tế',
        'fullDesc': 'Người giác quan (S) thường thực tế, cụ thể, tập trung vào hiện tại. Họ chú ý đến chi tiết và thông tin thực tế, tin tưởng vào kinh nghiệm và những gì có thể nhìn thấy, chạm vào được.',
        'color': Colors.green,
      },
      'N': {
        'title': 'Trực giác', 
        'desc': 'Sáng tạo, tưởng tượng, hướng tới tương lai, tập trung vào bức tranh tổng thể',
        'fullDesc': 'Người trực giác (N) thường sáng tạo, tưởng tượng, hướng tới tương lai. Họ tập trung vào bức tranh tổng thể, thích những ý tưởng mới và khả năng có thể xảy ra trong tương lai.',
        'color': Colors.purple,
      },
      'T': {
        'title': 'Lý trí', 
        'desc': 'Logic, khách quan, quyết định dựa trên phân tích và các nguyên tắc công bằng',
        'fullDesc': 'Người lý trí (T) thường logic, khách quan, quyết định dựa trên phân tích và các nguyên tắc công bằng. Họ coi trọng sự thật và tính nhất quán hơn là cảm xúc cá nhân.',
        'color': Colors.red,
      },
      'F': {
        'title': 'Cảm xúc', 
        'desc': 'Đồng cảm, hài hòa, quyết định dựa trên giá trị cá nhân và tác động đến con người',
        'fullDesc': 'Người cảm xúc (F) thường đồng cảm, hài hòa, quyết định dựa trên giá trị cá nhân và tác động đến con người. Họ quan tâm đến cảm xúc của người khác và tìm kiếm sự hòa hợp trong các mối quan hệ.',
        'color': Colors.pink,
      },
      'J': {
        'title': 'Nguyên tắc', 
        'desc': 'Có kế hoạch, quyết đoán, ngăn nắp, thích sự kiểm soát và kết cấu rõ ràng',
        'fullDesc': 'Người nguyên tắc (J) thường có kế hoạch, quyết đoán, ngăn nắp. Họ thích sự kiểm soát và kết cấu rõ ràng, luôn muốn hoàn thành công việc đúng hạn và theo kế hoạch đã định.',
        'color': Colors.orange,
      },
      'P': {
        'title': 'Linh hoạt', 
        'desc': 'Tự do, thích ứng, linh hoạt, thích sự tự phát và giữ các lựa chọn mở',
        'fullDesc': 'Người linh hoạt (P) thường tự do, thích ứng, linh hoạt. Họ thích sự tự phát và giữ các lựa chọn mở, dễ dàng thay đổi kế hoạch và thích khám phá những khả năng mới.',
        'color': Colors.teal,
      },
    };

    return SingleChildScrollView(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(left: 8.0, bottom: 12),
        child: Text(
          '4 Chiều Tính Cách',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
      ),

      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1, // giảm nhẹ để không bị dài quá
        ),
        itemCount: dimensions.length,
        itemBuilder: (context, index) {
          final dim = dimensions[index];
          final info = dimensionInfo[dim] ?? {
            'title': '', 'desc': '', 'fullDesc': '', 'color': Colors.grey
          };

          return GestureDetector(
            onTap: () => _showDimensionDetail(context, dim, info),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (info['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          dim,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: info['color'] as Color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      info['title'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        info['desc'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Xem thêm',
                          style: TextStyle(
                            fontSize: 9,
                            color: info['color'] as Color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: info['color'] as Color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ],
  ),
);

  
  }

  void _showDimensionDetail(BuildContext context, String dim, Map<String, dynamic> info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (info['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  dim,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: info['color'] as Color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                info['title'] as String,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: info['color'] as Color,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            info['fullDesc'] as String,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
            textAlign: TextAlign.justify,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
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
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  'Điểm Mạnh Nổi Bật',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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
                    const Icon(Icons.check, color: Colors.green, size: 16),
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

  Widget _buildWeaknesses() {
    final weaknesses = (result['weaknesses'] as List<dynamic>? ?? [])
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
                Icon(Icons.warning, color: Colors.orange, size: 24),
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
              children: weaknesses.map((weakness) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _cleanText(weakness),
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
                  'Tính Nhất Quán',
                  '${((patterns['consistency'] ?? 0.0) * 100).round()}%',
                  Colors.green,
                  patterns['consistency'] ?? 0.0,
                ),
                const SizedBox(height: 12),
                _buildPatternItem(
                  'Quyết Đoán',
                  '${((patterns['decisiveness'] ?? 0.0) * 100).round()}%',
                  Colors.blue,
                  patterns['decisiveness'] ?? 0.0,
                ),
                const SizedBox(height: 12),
                _buildPatternItem(
                  'Phản Ứng Mạnh',
                  '${patterns['extremeResponses'] ?? 0}',
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
            Navigator.pushNamed(context, '/mbti-test');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
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
            'Kết quả này chỉ mang tính chất tham khảo, không phải là chẩn đoán tâm lý chuyên nghiệp. '
            'MBTI là công cụ giúp bạn hiểu rõ hơn về bản thân và phát triển cá nhân.',
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

  String _cleanText(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('* ', '')
        .replaceAll('*', '')
        .trim();
  }
}