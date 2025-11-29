import 'package:flutter/material.dart';
import 'package:viejob_app/services/MI_service.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/mi_result_page.dart';

class MITestPage extends StatefulWidget {
  const MITestPage({Key? key}) : super(key: key);

  @override
  State<MITestPage> createState() => _MITestPageState();
}

class _MITestPageState extends State<MITestPage> {
  int _currentQuestion = 0;
  List<int> _answers = List.filled(86, -1);
  String? _selectedGender;
  bool _isSubmitting = false;
  bool _showSummary = false;

  final List<String> _questions = [
    "1. Tôi học tốt nhất bằng cách tự rèn luyện kỹ năng, hơn là đọc về nó hay có người khác chỉ",
    "2. Tôi thích xem phim kinh dị, phiêu lưu hay mạo hiểm",
    "3. Tôi có thể tháo lắp các đồ cơ khí, đồ gia dụng và biết cách sửa chúng",
    "4. Tôi không thể ngồi yên trong một thời gian dài, luôn phải cử động.",
    "5. Tôi giỏi việc ném và bắt",
    "6. Tôi khéo tay và thích làm những thứ như đồ handmade hay đồ mộc, đồ thủ công, …",
    "7. Tôi luôn mơ ước trở thành một nhạc sĩ hay ca sĩ",
    "8. Tôi có một bộ sưu tập âm nhạc ấn tượng mà tôi không thể thiếu được",
    "9. Tôi có chơi ít nhất 1 nhạc cụ",
    "10. Tôi có thể hát theo giai điệu và chỉ ra những nốt bị lệch tông",
    "11. Tôi thích rất nhiều các thể loại âm nhạc và có thể cảm nhận nhiều phong cách/ nhạc sĩ khác nhau",
    "12. Tôi thường có một bài hát, một âm thanh hay một đoạn nhạc ở trong đầu",
    "13. Thú nuôi của tôi cũng là bạn thân nhất của tôi - tôi không chịu được khi thiếu chúng",
    "14. Tôi thường xuyên tái chế và cố gắng tiết kiệm lượng nước và điện",
    "15. Bạn bè nghĩ tôi trồng cây rất mát tay",
    "16. Tôi thường nhận ra những kiến thức khoa học trong cuộc sống hàng ngày",
    "17. Tôi có thể dễ dàng phân biệt các loại cây và động vật khác nhau",
    "18. Tôi thích đi ra ngoài và còn thích hơn khi đi xa, ra khỏi thành phố",
    "19. Tôi thích nhìn thấy các bản vẽ hay biểu đồ về cách mọi thứ hoạt động",
    "20. Tôi thích chụp ảnh",
    "21. Tôi có thể hình dung ra các đồ vật từ nhiều góc nhìn khác nhau",
    "22. Tôi nhạy cảm với màu sắc và tính thẩm mỹ",
    "23. Tôi có rất nhiều tranh ảnh trong nhà hay trong máy tính cá nhân",
    "24. Tôi thường ghi nhớ / tưởng tượng ra các đoạn phim mình ưa thích",
    "25. Tôi luôn hỏi 'Tại sao,' thay vì 'Cái gì' hay 'Thế nào'",
    "26. Tôi thấy hứng thú với những câu hỏi triết học như 'Ý nghĩa cuộc sống là gì?'",
    "27. Tôi thường nghĩ về ý nghĩa của các sự kiện hay các câu hỏi",
    "28. Tôi thích tìm hiểu những vấn đề về tiến hóa, thiên văn học, triết học",
    "29. Bạn bè nghĩ tôi suy nghĩ quá nhiều",
    "30. Tôi thích xem phim tài liệu về các triết gia vĩ đại và các cuộc tranh luận triết học",
    "31. Tôi thích đọc, hoặc tham gia các phiên tranh biện hay thảo luận",
    "32. Tôi có một tủ sách mà không thể sống thiếu chúng",
    "33. Tôi giỏi các trò chơi ô chữ, câu đố và trò chơi chữ khác",
    "34. Tôi bịa chuyện rất dễ dàng",
    "35. Tôi có thể học ngoại ngữ dễ dàng",
    "36. Tôi luôn mơ ước được trở thành nhà văn hay biên tập viên",
    "37. Mọi người thường tìm đến tôi để trò chuyện",
    "38. Tôi thích đến các buổi tiệc hay sự kiện xã hội hơn là ngồi ở nhà một mình",
    "39. Tôi cảm thấy buồn khi người khác buồn",
    "40. Tôi là con người của xã hội (hòa đồng, quảng giao, …)",
    "41. Tôi dễ nhận ra cảm xúc thông qua ngôn ngữ cơ thể của người khác",
    "42. Mọi người nghĩ rằng tôi thích nhận được sự chú ý, thích là trung tâm",
    "43. Tôi thích tìm hiểu về bản thân và các cảm xúc của mình",
    "44. Tôi thích dành thời gian ở một mình",
    "45. Tôi hiểu cảm xúc của mình và biết mình sẽ phản ứng như thế nào trong các tình huống khác nhau",
    "46. Tôi thích làm việc một mình hơn là làm theo nhóm",
    "47. Tôi là một người cô đơn",
    "48. Tôi thích làm các bài tập để tìm hiểu về bản thân như trắc nghiệm tích cách",
    "49. Tôi ghi nhớ các sự kiện, số liệu, và công thức một cách dễ dàng",
    "50. Tôi hay đưa ra lời giải thích hợp lý cho các sự kiện",
    "51. Bạn bè nghĩ tôi có một bộ não như máy tính",
    "52. Tôi có thể làm toán nhẩm trong đầu",
    "53. Tôi không thể hiểu được những người không có logic và lý trí",
    "54. Tôi thích tìm hiểu về cách mọi thứ hoạt động ra sao",
    "55. Tôi rất hay ghi chú, lập danh sách để ghi nhớ, thay vì chỉ dựa vào trí nhớ của bản thân",
    "56. Tôi hay nghi ngờ những thông tin mình nhận được, ít khi tin ngay lập tức",
    "57. Tôi thấy chán chường khi ở một mình và không cần những khoảng thời gian một mình",
    "58. Tôi thường chấp nhận mọi thứ như hiện trạng của chúng và ít khi cảm thấy không thỏa mãn với hiện tại",
    "59. Tôi giữ cho không gian quanh mình được sạch sẽ, không bao giờ để đồ đạc lung tung",
    "60. Tôi nghĩ lời nhận xét 'giống robot' là một sự xúc phạm, tôi không muốn hướng tới việc tư duy như cỗ máy",
    "61. Tôi thường tràn đầy năng lượng và không bao giờ ủ rũ",
    "62. Tôi thích làm những bài kiểm tra trắc nghiệm hơn là viết luận",
    "63. Tôi thấy thoải mái với sự hỗn loạn, hơn là tính có tổ chức, có sắp xếp",
    "64. Tôi thường dễ cảm thấy tổn thương và khó chịu đựng được chỉ trích",
    "65. Tôi làm việc tốt nhất khi là thành viên của một nhóm, hơn là khi làm việc một mình",
    "66. Tôi tập trung vào những việc thực tiễn ở hiện tại, thay vì nghĩ tới những kế hoạch tương lai",
    "67. Tôi thường lên kế hoạch cho tương lai xa chứ không để sát nút rồi mới lên kế hoạch",
    "68. Tôi cần sự tôn trọng từ người khác hơn là cảm tình của họ",
    "69. Sau mỗi buổi tiệc tùng, tôi thường kiệt sức thay vì sung mãn",
    "70. Tôi rất dễ hòa đồng và ít khi bị cô lập",
    "71. Tôi thích sự tự do, không cần kế hoạch hay cam kết gì cụ thể",
    "72. Tôi muốn làm giỏi việc sửa chữa các đồ vật hơn là thay đổi con người",
    "73. Tôi thường bày tỏ quan điểm nhiều hơn là im lặng lắng nghe",
    "74. Tôi thường đơn thuần là mô tả các sự kiện, nhiều hơn là nói về ý nghĩa hay tác động của chúng",
    "75. Tôi thường hoàn thành công việc sớm nhất có thể thay vì trì hoãn chúng",
    "76. Tôi thường hành động theo trái tim mình hơn là theo cái đầu",
    "77. Tôi thường ở nhà nhiều hơn là đi ra ngoài",
    "78. Tôi thích việc quan sát tổng quan hơn là tập trung vào chi tiết",
    "79. Tôi giỏi ứng biến hơn là lên kế hoạch",
    "80. Tôi nghĩ công lý không nên dựa trên sự thông cảm",
    "81. Tôi khó có thể hét to được nên rất khó gọi người khác khi họ ở khoảng cách xa",
    "82. Tôi tin tưởng vào những lý thuyết khoa học hơn là kinh nghiệm cá nhân",
    "83. Tôi dành nhiều thời gian để làm việc hơn là thư giãn, đi chơi",
    "84. Tôi thấy không thoải mái mỗi khi cảm xúc dâng trào, dù là của bản thân hay người khác",
    "85. Tôi thích việc thể hiện bản thân trước nhiều người, không tránh né việc nói trước đông người",
    "86. Tôi thích được biết các thông tin chi tiết và cụ thể, ví dụ như có những ai, ở đâu, làm gì, vào lúc nào, etc., và ít khi quan tâm đến lý do tại sao",
  ];

  final List<List<String>> _options = [
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
    ["Hoàn toàn không đúng", "Không đúng", "Trung lập", "Đúng", "Hoàn toàn đúng"],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trắc nghiệm Đa trí tuệ'),
        backgroundColor: Colors.teal,
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
            colors: [Colors.blue.shade50, Colors.teal.shade50],
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
          _buildProgressBar(),
          const SizedBox(height: 16),
          
          if (_showSummary) _buildSummaryPanel(),
          
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
          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

Widget _buildSummaryPanel() {
  return Card(
    elevation: 4,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6, // giới hạn 60% màn hình
      ),
      child: SingleChildScrollView(
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
                          ? Colors.teal.shade100
                          : isAnswered
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? Colors.teal.shade400
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
                              ? Colors.teal.shade800
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

            const SizedBox(height: 12),

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
                    color: Colors.teal.shade100,
                    border: Border.all(color: Colors.teal.shade400, width: 2),
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
                color: Colors.teal,
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
                ? Colors.teal.shade50 
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _answers[_currentQuestion] == index 
                    ? Colors.teal.shade400 
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
                              ? Colors.teal.shade400 
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                        color: _answers[_currentQuestion] == index 
                            ? Colors.teal.shade400 
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
                              ? Colors.teal.shade800
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
              backgroundColor: Colors.teal.shade100,
              foregroundColor: Colors.teal.shade800,
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
                    backgroundColor: Colors.teal,
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
                backgroundColor: Colors.teal,
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
          color: isSelected ? Colors.teal.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.teal.shade400 : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              gender == 'male' ? Icons.male : Icons.female,
              size: 40,
              color: isSelected ? Colors.teal.shade600 : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.teal.shade800 : Colors.grey.shade800,
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
      final miService = MIService();
      final result = await miService.analyzeMIAdvanced(
        answers: _answers,
        gender: _selectedGender!,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MIResultPage(result: result.toJson()),
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
}