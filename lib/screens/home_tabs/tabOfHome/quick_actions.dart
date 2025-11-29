import 'package:flutter/material.dart';
import 'package:viejob_app/screens/Home_tab/job/find_job.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/mbti_test_page.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/mi_test_page.dart';
// import 'package:viejob_app/screens/tools/tax_calculator_page.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/PersonalTaxCalc.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/compound_interest_calculator.dart';
// import 'package:viejob_app/screens/tools/insurance_calculator_page.dart';
// import 'package:viejob_app/screens/tools/savings_plan_page.dart';
// import 'package:viejob_app/screens/tools/salary_calculator_page.dart';
// import 'package:viejob_app/screens/tools/salary_comparison_page.dart';
// import 'package:viejob_app/screens/career/career_goals_page.dart';

class QuickActionsSection extends StatefulWidget {
  const QuickActionsSection({Key? key}) : super(key: key);

  @override
  State<QuickActionsSection> createState() => _QuickActionsSectionState();
}

class _QuickActionsSectionState extends State<QuickActionsSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _itemsPerPage = 4;

  final List<QuickActionItem> _actionItems = [
    QuickActionItem(
      'Tìm việc',
      Icons.work_outline,
      _VibrantColors.blue,
      (BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FindJobScreen(initialSearch: '')),
      ),
    ),
    QuickActionItem(
      'Phân tích MBTI',
      Icons.psychology,
      _VibrantColors.pink,
      (BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MBTITestPage()), // TODO: Thay bằng MBTI page thực tế
      ), 
    ),
    QuickActionItem(
      'Phân tích MI',
      Icons.auto_awesome,
      _VibrantColors.orange,
      (BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MITestPage()), // TODO: Thay bằng MI page thực tế
      ),
    ),
    QuickActionItem(
      'Tính thuế TNCN',
      Icons.calculate,
      _VibrantColors.green,
      (BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PersonalTaxCalc()), // TODO: Thay bằng Tax Calculator
      ),
    ),
    QuickActionItem(
      'Lãi suất kép',
      Icons.trending_up,
      _VibrantColors.teal,
      (BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CompoundInterestCalculator()), // TODO: Thay bằng Compound Interest
      ),
    ),
    QuickActionItem(
      'Tính BHTN',
      Icons.security,
      _VibrantColors.amber,
      (BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const InsuranceCalculatorPage(type: 'BHTN')), // TODO: Thay bằng Insurance Calculator
      ),
    ),
    QuickActionItem(
      'Tính BHXH',
      Icons.health_and_safety,
      _VibrantColors.red,
      (BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const InsuranceCalculatorPage(type: 'BHXH')), // TODO: Thay bằng Insurance Calculator
      ),
    ),
    QuickActionItem(
      'Tiết kiệm',
      Icons.savings,
      _VibrantColors.indigo,
      (BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SavingsPlanPage()), // TODO: Thay bằng Savings Plan
      ),
    ),
    QuickActionItem(
      'Lương Gross/Net',
      Icons.attach_money,
      _VibrantColors.lime,
      (BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SalaryCalculatorPage()), // TODO: Thay bằng Salary Calculator
      ),
    ),
    QuickActionItem(
      'So sánh lương',
      Icons.compare,
      _VibrantColors.cyan,
      (BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SalaryComparisonPage()), // TODO: Thay bằng Salary Comparison
      ),
    ),
    QuickActionItem(
      'Mục tiêu nghề',
      Icons.flag,
      _VibrantColors.deepOrange,
      (BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CareerGoalsPage()), // TODO: Thay bằng Career Goals
      ),
    ),
  ];

  int get _pageCount {
    return (_actionItems.length / _itemsPerPage).ceil();
  }

  List<QuickActionItem> _getItemsForPage(int page) {
    final startIndex = page * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _actionItems.length);
    return _actionItems.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header với tiêu đề và pagination dots
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tính năng nhanh',
                style: _TextStyles.displayMedium,
              ),
              if (_pageCount > 1) _buildPageIndicator(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // PageView cho các action items
        SizedBox(
          height: 100, // Chiều cao cố định cho mỗi trang
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pageCount,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, pageIndex) {
              final pageItems = _getItemsForPage(pageIndex);
              return _buildActionPage(pageItems);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionPage(List<QuickActionItem> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((item) {
        return _buildQuickActionItem(
          item.title,
          item.icon,
          item.color,
          item.onTap,
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionItem(
      String title, IconData icon, Color color, void Function(BuildContext) onTap) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 100, // Chiều cao cố định
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    Color.alphaBlend(Colors.black.withOpacity(0.1), color),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon với container cố định
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      icon, 
                      size: 18, 
                      color: Colors.white
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: _TextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 10,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_pageCount, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index 
                ? _VibrantColors.blue 
                : Colors.grey[300],
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// =============================================================================
// PLACEHOLDER PAGES - CÁC TRANG TẠM THỜI (COMMENT LẠI KHI CÓ TRANG THẬT)
// =============================================================================

// TODO: Thay bằng trang MBTI thực tế
class MBTIPage extends StatelessWidget {
  const MBTIPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trắc nghiệm MBTI'),
        backgroundColor: Colors.pink,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, size: 64, color: Colors.pink),
            SizedBox(height: 16),
            Text(
              'Trang MBTI đang được phát triển',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tính năng sẽ sớm có mặt trong phiên bản tới',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: Thay bằng trang MI thực tế
class MIPage extends StatelessWidget {
  const MIPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đa trí thông minh'),
        backgroundColor: Colors.orange,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Trắc nghiệm Đa trí thông minh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Khám phá 9 loại trí thông minh của bạn',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: Thay bằng trang tính thuế thực tế
class TaxCalculatorPage extends StatelessWidget {
  const TaxCalculatorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tính thuế TNCN'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Máy tính thuế thu nhập cá nhân',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: Thay bằng trang lãi suất kép thực tế
class CompoundInterestPage extends StatelessWidget {
  const CompoundInterestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lãi suất kép'),
        backgroundColor: Colors.teal,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.teal),
            SizedBox(height: 16),
            Text(
              'Tính lãi suất kép',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Khám phá sức mạnh của lãi suất kép',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: Thay bằng trang tính bảo hiểm thực tế
class InsuranceCalculatorPage extends StatelessWidget {
  final String type;
  const InsuranceCalculatorPage({Key? key, required this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tính $type'),
        backgroundColor: type == 'BHTN' ? Colors.amber : Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'BHTN' ? Icons.security : Icons.health_and_safety,
              size: 64,
              color: type == 'BHTN' ? Colors.amber : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Tính $type',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: Thay bằng trang kế hoạch tiết kiệm thực tế
class SavingsPlanPage extends StatelessWidget {
  const SavingsPlanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kế hoạch tiết kiệm'),
        backgroundColor: Colors.indigo,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.savings, size: 64, color: Colors.indigo),
            SizedBox(height: 16),
            Text(
              'Lập kế hoạch tiết kiệm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: Thay bằng trang tính lương thực tế
class SalaryCalculatorPage extends StatelessWidget {
  const SalaryCalculatorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lương Gross/Net'),
        backgroundColor: Colors.lime,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.attach_money, size: 64, color: Colors.lime),
            SizedBox(height: 16),
            Text(
              'Chuyển đổi lương Gross - Net',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: Thay bằng trang so sánh lương thực tế
class SalaryComparisonPage extends StatelessWidget {
  const SalaryComparisonPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('So sánh lương'),
        backgroundColor: Colors.cyan,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare, size: 64, color: Colors.cyan),
            SizedBox(height: 16),
            Text(
              'So sánh mức lương theo ngành',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: Thay bằng trang mục tiêu nghề nghiệp thực tế
class CareerGoalsPage extends StatelessWidget {
  const CareerGoalsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mục tiêu nghề nghiệp'),
        backgroundColor: Colors.deepOrange,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag, size: 64, color: Colors.deepOrange),
            SizedBox(height: 16),
            Text(
              'Lập kế hoạch mục tiêu nghề nghiệp',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionItem {
  final String title;
  final IconData icon;
  final Color color;
  final void Function(BuildContext) onTap;

  QuickActionItem(this.title, this.icon, this.color, this.onTap);
}

// Màu sắc nổi bật và tươi sáng
class _VibrantColors {
  static const Color blue = Color(0xFF4361EE);
  static const Color pink = Color(0xFFF72585);
  static const Color orange = Color(0xFFFB5607);
  static const Color green = Color(0xFF4CAF50);
  static const Color teal = Color(0xFF009688);
  static const Color amber = Color(0xFFFFC107);
  static const Color red = Color(0xFFF44336);
  static const Color indigo = Color(0xFF3F51B5);
  static const Color lime = Color(0xFFCDDC39);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color deepOrange = Color(0xFFFF5722);
}

class _PastelColors {
  static const Color dark = Color(0xFF2D3748);
}

class _TextStyles {
  static final TextStyle displayMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: _PastelColors.dark,
    letterSpacing: -0.5,
  );

  static final TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: _PastelColors.dark,
  );
}