import 'package:flutter/material.dart';
import 'package:viejob_app/services/MBTI_service.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/mbti_result_page.dart';

class MBTITestPage extends StatefulWidget {
  const MBTITestPage({Key? key}) : super(key: key);

  @override
  State<MBTITestPage> createState() => _MBTITestPageState();
}

class _MBTITestPageState extends State<MBTITestPage> {
  int _currentQuestion = 0;
  List<int> _answers = List.filled(70, -1);
  String? _selectedGender;
  bool _isSubmitting = false;
  bool _showSummary = false;

  final List<String> _questions = [
    "1. Trong một buổi tiệc, bạn sẽ:",
    "2. Bạn thiên về:",
    "3. Điều gì khiến bạn cảm thấy tệ hơn?",
    "4. Bạn thấy ấn tượng hơn bởi:",
    "5. Bạn dễ bị thuyết phục hơn bởi những sự việc:",
    "6. Bạn thích làm việc:",
    "7. Khi lựa chọn, bạn thường:",
    "8. Tại các buổi gặp mặt, bạn sẽ:",
    "9. Tuýp người nào sẽ thu hút bạn hơn?",
    "10. Bạn hứng thú hơn với những sự việc:",
    "11. Bạn thường đánh giá người khác dựa trên:",
    "12. Khi tiếp cận người khác, bạn thường đánh giá họ dựa trên góc nhìn nào?",
    "13. Bạn thường là người:",
    "14. Sau khi trải qua một kỳ thi, bạn thường:",
    "15. Trong nhóm, bạn thường là người:",
    "16. Cách bạn giải quyết những công việc thường ngày là:",
    "17. Theo bạn, các nhà văn nên:",
    "18. Điều gì thu hút bạn hơn?",
    "19. Bạn cảm thấy thoải mái hơn khi đưa ra nhận xét:",
    "20. Bạn thích những điều:",
    "21. Một phút thật lòng với bản thân nhé. Bạn là người:",
    "22. Khi nói chuyện điện thoại, bạn:",
    "23. Theo bạn, các sự việc và hiện tượng:",
    "24. Những người có tầm nhìn xa:",
    "25. Bạn là người:",
    "26. Bạn cảm thấy tồi tệ hơn khi đối mặt với:",
    "27. Theo bạn, quyết định nên được đưa ra:",
    "28. Khi đi mua sắm, bạn thích cảm giác nào hơn?",
    "29. Trong công ty, bạn là người:",
    "30. Với những kiến thức, quy luật đã được xã hội công nhận, bạn sẽ:",
    "31. Theo bạn, trẻ em thường không:",
    "32. Khi mua xe hơi, bạn nghĩ yếu tố nào quan trọng hơn?",
    "33. Tính cách của bạn nghiêng về:",
    "34. Khả năng nào đáng khâm phục hơn?",
    "35. Bạn mong muốn điều gì hơn ở cấp trên?",
    "36. Khi đối mặt với những vấn đề mới, bạn thường cảm thấy:",
    "37. Tính cách của bạn thiên về:",
    "38. Bạn sẽ quan tâm hơn đến:",
    "39. Điều gì làm bạn thoải mái hơn?",
    "40. Bạn sẽ lựa chọn công việc nào?",
    "41. Bạn thích được điều hướng công việc theo cách:",
    "42. Bạn thường tìm kiếm những điều:",
    "43. Bạn thường kết giao:",
    "44. Điều gì ảnh hưởng tới quyết định của bạn nhiều hơn?",
    "45. Bạn thấy hứng thú hơn với việc:",
    "46. Bạn thường được tán thưởng vì:",
    "47. Bạn thấy điều gì giá trị hơn ở bản thân mình?",
    "48. Bạn đánh giá cao:",
    "49. Bạn thấy nhẹ nhõm hơn:",
    "50. Bạn đánh giá bản thân là người như thế nào?",
    "51. Bạn có xu hướng tin tưởng vào:",
    "52. Bạn thường:",
    "53. Bạn thấy ấn tượng hơn khi tiếp xúc với một người:",
    "54. Bạn đánh giá tính cách nào cao hơn?",
    "55. Theo bạn, mọi chuyện sẽ diễn ra hợp lý hơn nếu:",
    "56. Trong một mối quan hệ:",
    "57. Khi có số lạ gọi tới điện thoại của bạn, bạn sẽ:",
    "58. Bạn đánh giá cao khả năng của mình hơn khi:",
    "59. Bạn bị thu hút hơn với điều gì?",
    "60. Bạn không thích những người:",
    "61. Bạn thuộc tuýp người:",
    "62. Trước một chuyến đi chơi, bạn thường:",
    "63. Trong công việc, bạn thường:",
    "64. Bạn nghĩ mình là người:",
    "65. Khi viết lách, bạn có xu hướng:",
    "66. Là một cấp trên, bạn cảm thấy điều gì khó hơn?",
    "67. Bạn cảm thấy mình cần trở nên:",
    "68. Điều gì khiến bạn khó chấp nhận hơn?",
    "69. Bạn sẽ lựa chọn:",
    "70. Phong cách làm việc của bạn là gì?",
  ];

  final List<List<String>> _options = [
    [
      "Thoải mái trò chuyện với tất cả mọi người, kể cả người lạ",
      "Chỉ tương tác với những người bạn quen",
    ],
    ["Thực tế hơn là suy đoán", "Suy đoán hơn là thực tế"],
    ["Đầu óc trên mây, viển vông và phi thực tế", "Nhàm chán, đơn điệu"],
    ["Nguyên lý, nguyên tắc", "Cảm xúc, tình cảm"],
    [
      "Logic, dựa trên bằng chứng và lý lẽ",
      "Cảm động, thiên về cảm xúc và tình người",
    ],
    ["Với thời hạn (deadline) rõ ràng", "Tùy hứng, linh hoạt"],
    [
      "Xem xét kỹ lưỡng từ nhiều khía cạnh",
      "Tin vào suy đoán và linh cảm của mình",
    ],
    [
      "Muốn tận hưởng bữa tiệc và ở lại đến cuối cùng",
      "Nhanh chóng thấy mệt mỏi và muốn ra về sớm",
    ],
    ["Người logic và thực tế", "Người có khả năng tưởng tượng phong phú"],
    ["Đã và đang xảy ra", "Có khả năng xảy ra"],
    ["Quy định, nguyên tắc", "Hoàn cảnh cụ thể"],
    ["Khách quan", "Chủ quan"],
    ["Luôn đúng giờ", "Thong thả, linh hoạt về thời gian"],
    [
      "Cảm thấy nhẹ nhõm và bắt đầu lên lịch đi chơi",
      "Lo lắng về kết quả sẽ đạt được",
    ],
    ["Luôn nắm bắt thông tin kịp thời", "Biết thông tin muộn hơn"],
    ["Làm theo cách thông thường", "Làm theo cách của riêng mình"],
    [
      "Viết chính xác những gì họ nghĩ, diễn đạt một cách rõ ràng, nghĩa trên mặt chữ",
      "Diễn đạt bằng biện pháp so sánh, liên tưởng, ví von thâm sâu",
    ],
    ["Tính nhất quán trong tư tưởng", "Mối quan hệ hài hòa giữa người với người"],
    ["Dựa trên logic", "Dựa trên quan điểm, giá trị cá nhán"],
    ["Theo kế hoạch và ổn định", "Linh hoạt và có thể thay đổi"],
    ["Nghiêm túc, quyết đoán", "Dễ tính, thoải mái"],
    [
      "Hiếm khi băn khoăn đến những điều mình sẽ nói",
      "Thường chuẩn bị trước những điều mình sẽ nói",
    ],
    [
      "Tự nói lên bản chất của chính nó",
      "Tồn tại để minh họa cho các quy luật, quy tắc khác",
    ],
    [
      "Ở mức độ nào đó, họ thường gây khó chịu cho người khác",
      "Khá thú vị, lôi cuốn",
    ],
    ["Có cái đầu lạnh", "Có trái tim ấm"],
    ["Sự bất công", "Sự tàn nhẫn"],
    [
      "Dựa trên việc cân nhắc và lựa chọn kỹ lưỡng",
      "Thuận theo tự nhiên, nước chảy mây trôi",
    ],
    ["Đã mua được thứ mình muốn", "Đang trong quá trình lựa chọn"],
    ["Khởi xướng các câu chuyện", "Đợi người khác khởi xướng rồi tham gia vào"],
    ["Tin tưởng không nghi ngờ", "Không ngừng đặt nghi vấn về tính chính xác"],
    [
      "Tự mình phát huy hết năng lực",
      "Khai thác tối đa trí tưởng tượng của mình",
    ],
    ["Nhu cầu sử dụng", "Sở thích cá nhân"],
    ["Cứng rắn", "Mềm mỏng"],
    [
      "Tổ chức và làm việc bài bản, có phương pháp, hệ thống",
      "Dễ dàng thích ứng và linh hoạt trong mọi tình huống",
    ],
    ["Chuyên môn xuất sắc", "Tư duy cởi mở"],
    ["Hào hứng, tràn đầy năng lượng", "Mệt mỏi, nhanh chóng bị hút cạn sức lực"],
    ["Thực tế", "Mơ mộng"],
    [
      "Giá trị thực tế mà một người mang lại",
      "Cảm nhận, suy nghĩ của đối phương",
    ],
    [
      "Thảo luận kỹ lưỡng về một vấn đề (quá trình)",
      "Thống nhất được hướng giải quyết cho một vấn đề (kết quả)",
    ],
    [
      "Công việc bạn không thực sự thích nhưng đem lại thu nhập cao",
      "Công việc mà bạn hằng mơ ước nhưng thu nhập trung bình",
    ],
    [
      "Giao việc trọn gói, bàn giao 100% sau khi hoàn thành",
      "Giao việc hàng ngày, từng bước hoàn thành công việc",
    ],
    ["Được sắp xếp theo thứ tự rõ ràng", "Ngẫu nhiên, tùy hứng"],
    [
      "Với nhiều bạn nhưng không quá thân",
      "Với ít bạn nhưng tình cảm khăng khít",
    ],
    ["Tình hình thực tế", "Nguyên tắc, luật lệ"],
    ["Sản xuất và phân phối", "Thiết kế và nghiên cứu"],
    ["Là người có tư duy logic", "Là người tinh tế, tình cảm"],
    ["Tinh thần kiên định, vững vàng", "Sự toàn tâm, cống hiến"],
    [
      "Tuyên bố cuối cùng, không thay đổi",
      "Tuyên bố mang tính dự kiến, có thể thay đổi",
    ],
    ["Trước khi đưa ra quyết định", "Sau khi đưa ra quyết định"],
    [
      "Tôi có thể dễ dàng bắt chuyện với người lạ",
      "Tôi không có hứng thú trò chuyện với người lạ",
    ],
    ["Kinh nghiệm của mình", "Linh cảm của mình"],
    [
      "Giải quyết vấn đề một cách thực tế và hiệu quả (có thể áp dụng được ngay)",
      "Nghĩ ra những giải pháp sáng tạo và độc đáo (có thể không thực hiện ngay được)",
    ],
    ["Giàu lý trí", "Giàu cảm xúc"],
    ["Sự công bằng", "Sự đồng cảm"],
    ["Được chuẩn bị trước", "Diễn ra tự nhiên"],
    [
      "Điều gì cũng có thể thương lượng và điều chỉnh lại để đạt được sự đồng thuận chung",
      "Nên để mọi chuyện diễn ra tự nhiên, thuận theo hoàn cảnh đưa đẩy",
    ],
    ["Nhấc máy ngay để xem ai đang gọi", "Chần chừ không nghe máy"],
    [
      "Đưa ra quyết định dựa trên số liệu thực tế",
      "Đưa ra quyết định dựa trên trực giác và linh cảm",
    ],
    ["Những nguyên tắc cơ bản", "Những ẩn ý sâu xa"],
    [
      "Quá cảm xúc (dễ bị tình cảm chi phối)",
      "Quá lý trí (không dễ bị ảnh hưởng bởi yếu tố cảm xúc)",
    ],
    [
      "Mạnh mẽ, quyết đoán, không dễ bị thuyết phục",
      "Mềm mỏng, dễ bị thuyết phục, dễ thay đổi quan điểm dưới ảnh hưởng của người khác",
    ],
    ["Lên lịch trình chi tiết, rõ ràng", "Tới đâu hay tới đó"],
    ["Làm việc theo thói quen", "Hay thay đổi, thích thử nghiệm những điều mới"],
    ["Cởi mở, dễ gần", "Kín tiếng, khó đoán"],
    [
      "Viết những áng văn bay bổng (thiên về nghĩa bóng)",
      "Viết về những điều thực tế (thiên về nghĩa đen)",
    ],
    [
      "Hiểu và chia sẻ với cấp dưới",
      "Bỏ qua yếu tố cảm xúc, công việc là quan trọng nhất",
    ],
    ["Lý trí hơn", "Tình cảm hơn"],
    [
      "Hành động thiếu suy nghĩ, gây ra sai phạm lớn",
      "Sự chỉ trích, phê phán nghiêm khắc quá mức",
    ],
    [
      "Sự kiện đã được lên kế hoạch trước",
      "Sự kiện chưa được lên kế hoạch trước",
    ],
    ["Cân nhắc thận trọng", "Tự nhiên, tự phát"],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trắc nghiệm MBTI'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          if (_currentQuestion < _questions.length)
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSummary,
              tooltip: 'Xem tổng hợp đáp án',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.purple.shade50],
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_currentQuestion < _questions.length) {
      return _buildQuestionPage();
    } else {
      return _buildGenderSelection();
    }
  }

  Widget _buildQuestionPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Progress Bar
          _buildProgressBar(),
          const SizedBox(height: 16),
          
          // Summary Panel (nếu đang mở)
          if (_showSummary) _buildSummaryPanel(),
          
          // Question Card
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildQuestionCard(),
                  const SizedBox(height: 20),
                  _buildOptions(),
                ],
              ),
            ),
          ),
          
          // Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final answeredCount = _answers.where((a) => a != -1).length;
    final progress = answeredCount / _questions.length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tiến độ: $answeredCount/${_questions.length}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildSummaryPanel() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng hợp câu trả lời',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _toggleSummary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_questions.length, (index) {
                final isAnswered = _answers[index] != -1;
                final isCurrent = index == _currentQuestion;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentQuestion = index;
                      _showSummary = false;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? Colors.blue.shade100
                          : isAnswered
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? Colors.blue.shade400
                            : isAnswered
                                ? Colors.green.shade400
                                : Colors.red.shade400,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? Colors.blue.shade800
                              : isAnswered
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    border: Border.all(color: Colors.green.shade400),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Đã trả lời', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    border: Border.all(color: Colors.red.shade400),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Chưa trả lời', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    border: Border.all(color: Colors.blue.shade400, width: 2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Hiện tại', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Câu ${_currentQuestion + 1}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _questions[_currentQuestion],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      children: _options[_currentQuestion].asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 2,
            color: _answers[_currentQuestion] == index 
                ? Colors.blue.shade50 
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _answers[_currentQuestion] == index 
                    ? Colors.blue.shade400 
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: () => _handleAnswer(index),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _answers[_currentQuestion] == index 
                              ? Colors.blue.shade400 
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                        color: _answers[_currentQuestion] == index 
                            ? Colors.blue.shade400 
                            : Colors.transparent,
                      ),
                      child: _answers[_currentQuestion] == index
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          color: _answers[_currentQuestion] == index
                              ? Colors.blue.shade800
                              : Colors.grey.shade800,
                          fontWeight: _answers[_currentQuestion] == index
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentQuestion > 0 ? _handlePrevious : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.grey.shade800,
              disabledBackgroundColor: Colors.grey.shade200,
            ),
            child: const Text('Quay lại'),
          ),
          Text(
            '${_currentQuestion + 1}/${_questions.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          ElevatedButton(
            onPressed: _handleNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade100,
              foregroundColor: Colors.blue.shade800,
            ),
            child: Text(
              _currentQuestion < _questions.length - 1 ? 'Tiếp theo' : 'Hoàn thành',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelection() {
    final unansweredQuestions = _answers.where((a) => a == -1).length;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Hoàn thành bài trắc nghiệm',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          if (unansweredQuestions > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn còn $unansweredQuestions câu chưa trả lời. Bạn có muốn quay lại trả lời không?',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentQuestion = 0;
                      _showSummary = true;
                    });
                  },
                  child: const Text('Quay lại trả lời'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
  onPressed: _selectedGender != null && !_isSubmitting ? _handleSubmit : null,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.purple,
    foregroundColor: Colors.white,
  ),
  child: _isSubmitting
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
      : const Text('Vẫn xem kết quả'),
),

              ],
            ),
            const SizedBox(height: 20),
          ] else ...[
            const Text(
              'Bạn đã hoàn thành tất cả câu hỏi! Vui lòng chọn giới tính để xem kết quả chi tiết.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
          ],
          
          const Text(
            'Chọn giới tính của bạn',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGenderOption('Nam', 'male'),
              _buildGenderOption('Nữ', 'female'),
            ],
          ),
          
          const SizedBox(height: 30),
          
          if (unansweredQuestions == 0)
            ElevatedButton(
              onPressed: _selectedGender != null && !_isSubmitting ? _handleSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Xem kết quả', style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String label, String gender) {
    final isSelected = _selectedGender == gender;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              gender == 'male' ? Icons.male : Icons.female,
              size: 40,
              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.blue.shade800 : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSummary() {
    setState(() {
      _showSummary = !_showSummary;
    });
  }

  void _handleAnswer(int optionIndex) {
    setState(() {
      _answers[_currentQuestion] = optionIndex;
    });
  }

  void _handlePrevious() {
    if (_currentQuestion > 0) {
      setState(() => _currentQuestion--);
    }
  }

  void _handleNext() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() => _currentQuestion++);
    } else {
      setState(() => _currentQuestion = _questions.length);
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giới tính!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Calculate MBTI type from answers
      final mbtiType = _calculateMBTIType(_answers);
      
      final mbtiService = MBTIService();
      final result = await mbtiService.analyzeMBTIAdvanced(
        answers: _answers,
        gender: _selectedGender!,
        mbtiType: mbtiType,
      );

      // Navigate to result page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MBTIResultPage(result: result.toJson()),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _calculateMBTIType(List<int> answers) {
    // Simple MBTI calculation logic - bạn có thể thay thế bằng logic thực tế
    final eCount = answers.sublist(0, 10).where((a) => a == 1).length;
    final iCount = answers.sublist(0, 10).where((a) => a == 0).length;
    
    final sCount = answers.sublist(10, 20).where((a) => a == 1).length;
    final nCount = answers.sublist(10, 20).where((a) => a == 0).length;
    
    final tCount = answers.sublist(20, 30).where((a) => a == 1).length;
    final fCount = answers.sublist(20, 30).where((a) => a == 0).length;
    
    final jCount = answers.sublist(30, 40).where((a) => a == 1).length;
    final pCount = answers.sublist(30, 40).where((a) => a == 0).length;

    var mbti = '';
    mbti += eCount > iCount ? 'E' : 'I';
    mbti += sCount > nCount ? 'S' : 'N';
    mbti += tCount > fCount ? 'T' : 'F';
    mbti += jCount > pCount ? 'J' : 'P';

    return mbti;
  }
}