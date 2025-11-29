import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CompoundInterestCalculator extends StatefulWidget {
  const CompoundInterestCalculator({super.key});

  @override
  State<CompoundInterestCalculator> createState() => _CompoundInterestCalculatorState();
}

class _CompoundInterestCalculatorState extends State<CompoundInterestCalculator> {
  double _principal = 10000000;
  double _monthlyContribution = 1000000;
  int _years = 10;
  double _interestRate = 10;
  String _compoundingFrequency = "yearly";

  List<ChartData> _chartData = [];
  CalculationResult _result = CalculationResult(0, 0, 0);
  
  // State for expandable sections
  bool _showFullFormula = false;
  bool _showFullTips = false;
  bool _showFullFAQ = false;
  
  // For chart interaction
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  // Format number with dots as thousand separators
  String formatNumber(double num) {
    return num.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Handle input change
  void handleInputChange(String value, Function(double) setter) {
    String numericValue = value.replaceAll(RegExp(r'[^\d]'), '');
    numericValue = numericValue.replaceAll(RegExp(r'^0+'), '');
    if (numericValue.isEmpty) numericValue = "0";
    setter(double.parse(numericValue));
  }

  // Format value for display
  String formatDisplayValue(double value) {
    return formatNumber(value);
  }

  // Calculate compound interest and generate chart data
  void calculateCompoundInterest() {
    final P = _principal;
    final r = _interestRate / 100;
    final t = _years;
    int n = 1;
    
    switch (_compoundingFrequency) {
      case "daily": n = 365; break;
      case "monthly": n = 12; break;
      case "quarterly": n = 4; break;
      case "yearly": n = 1; break;
      default: n = 1;
    }
    
    final PMT = _monthlyContribution;
    double balance = P;
    final chartData = <ChartData>[];

    final i_month = (pow(1 + r / n, n / 12) - 1) as double;

    for (int year = 0; year <= t; year++) {
      if (year > 0) {
        for (int m = 0; m < 12; m++) {
          balance = balance * (1 + i_month) + PMT;
        }
      }

      final totalContributions = P + PMT * 12 * year;
      
      chartData.add(ChartData(
        year.toDouble(),
        P,
        totalContributions - P,
        balance,
      ));
    }

    setState(() {
      _chartData = chartData;
    });

    final finalTotal = chartData.last.total;
    final interestEarned = finalTotal - (P + PMT * 12 * t);

    setState(() {
      _result = CalculationResult(
        finalTotal.roundToDouble(),
        interestEarned.roundToDouble(),
        (P + PMT * 12 * t).roundToDouble(),
      );
    });
  }

  void _calculate() {
    calculateCompoundInterest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tính lãi suất kép'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.blue.shade50,
      body: SingleChildScrollView(
         padding: const EdgeInsets.all(16),
         child: Column(
           children: [
             // Input Form
             _buildInputForm(),
             const SizedBox(height: 16),

                    // Results
                    _buildResults(),
                    const SizedBox(height: 16),

                    // Chart Section
                    _buildChartSection(),
                    const SizedBox(height: 16),

                    // Comparison Section
                    _buildComparisonSection(),
                    const SizedBox(height: 16),

                    // Tips Section
                    _buildTipsSection(),
                    const SizedBox(height: 16),

                    // FAQ Section
                    _buildFAQSection(),
                    const SizedBox(height: 16),

                    // Disclaimer
                    _buildDisclaimer(),
           ],
         ),
       ),
     );
   }

  Widget _buildInputForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Nhập thông tin', Icons.calculate),
            const SizedBox(height: 16),

            // Principal Input
            _buildNumberInputField(
              label: 'Tiền gốc ban đầu (VNĐ)',
              value: _principal,
              onChanged: (value) {
                setState(() => _principal = value);
                _calculate();
              },
              icon: Icons.attach_money,
              formatter: formatDisplayValue,
            ),
            const SizedBox(height: 12),

            // Monthly Contribution Input
            _buildNumberInputField(
              label: 'Gửi thêm mỗi tháng (VNĐ)',
              value: _monthlyContribution,
              onChanged: (value) {
                setState(() => _monthlyContribution = value);
                _calculate();
              },
              icon: Icons.savings,
              formatter: formatDisplayValue,
            ),
            const SizedBox(height: 12),

            // Years Input
            _buildSliderInput(
              label: 'Thời gian đầu tư: $_years năm',
              value: _years.toDouble(),
              min: 1,
              max: 50,
              onChanged: (value) {
                setState(() => _years = value.toInt());
                _calculate();
              },
            ),
            const SizedBox(height: 12),

            // Interest Rate Input
            _buildSliderInput(
              label: 'Lãi suất: ${_interestRate.toStringAsFixed(1)}%/năm',
              value: _interestRate,
              min: 0,
              max: 30,
              divisions: 300,
              onChanged: (value) {
                setState(() => _interestRate = value);
                _calculate();
              },
            ),
            const SizedBox(height: 12),

            // Compounding Frequency
            _buildDropdownInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInputField({
    required String label,
    required double value,
    required Function(double) onChanged,
    required IconData icon,
    required String Function(double) formatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: formatter(value)),
          onChanged: (text) => handleInputChange(text, onChanged),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderInput({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    int divisions = 100,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${min.toInt()}'),
            Text('${max.toInt()}'),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tần suất ghép lãi',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _compoundingFrequency,
          onChanged: (String? newValue) {
            setState(() {
              _compoundingFrequency = newValue!;
              _calculate();
            });
          },
          items: const [
            DropdownMenuItem(value: "yearly", child: Text("Hàng năm")),
            DropdownMenuItem(value: "quarterly", child: Text("Hàng quý")),
            DropdownMenuItem(value: "monthly", child: Text("Hàng tháng")),
            DropdownMenuItem(value: "daily", child: Text("Hàng ngày")),
          ],
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionTitle('Kết quả dự báo', Icons.analytics),
            const SizedBox(height: 16),

            // Total Value
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade500, Colors.blue.shade700],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Tổng giá trị sau $_years năm',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatNumber(_result.total)} VNĐ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Breakdown
            Row(
              children: [
                Expanded(
                  child: _buildResultItem(
                    'Lãi kiếm được',
                    '${formatNumber(_result.interestEarned)} VNĐ',
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildResultItem(
                    'Tiền đầu tư',
                    '${formatNumber(_result.contributions)} VNĐ',
                    Colors.blue,
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ROI
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tỷ suất lợi nhuận (ROI)'),
                  Text(
                    _result.contributions > 0
                        ? '${((_result.interestEarned / _result.contributions) * 100).toStringAsFixed(1)}%'
                        : '0%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            // Formula (Expandable)
            const SizedBox(height: 16),
            _buildExpandableSection(
              title: 'Công thức tính',
              isExpanded: _showFullFormula,
              onTap: () => setState(() => _showFullFormula = !_showFullFormula),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Fₙ = P × (1 + r/n)ⁿᵗ + PMT × [(1 + r/n)ⁿᵗ - 1] / (r/n)",
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  _buildFormulaDetail('Fₙ', 'Giá trị cuối kỳ'),
                  _buildFormulaDetail('P', 'Tiền gốc ban đầu'),
                  _buildFormulaDetail('r', 'Lãi suất năm'),
                  _buildFormulaDetail('n', 'Số lần ghép lãi/năm'),
                  _buildFormulaDetail('t', 'Số năm đầu tư'),
                  _buildFormulaDetail('PMT', 'Tiền gửi định kỳ'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaDetail(String symbol, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$symbol: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(child: Text(description, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Biểu đồ tăng trưởng tài sản theo thời gian',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: SfCartesianChart(
                onChartTouchInteractionDown: (ChartTouchInteractionArgs args) {
                  if (args.position != null) {
                    _handleChartTap(args.position!);
                  }
                },
                title: ChartTitle(
                  text: 'Sự tăng trưởng kỳ diệu của lãi kép qua thời gian',
                ),
                legend: Legend(isVisible: true, position: LegendPosition.top),
                primaryXAxis: NumericAxis(
                  title: AxisTitle(text: 'Năm'),
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.compact(),
                  title: AxisTitle(text: 'Giá trị (VNĐ)'),
                ),
                series: [
                  LineSeries<ChartData, double>(
                    name: 'Tiền gốc',
                    dataSource: _chartData,
                    xValueMapper: (ChartData data, _) => data.year,
                    yValueMapper: (ChartData data, _) => data.principal,
                    color: const Color.fromRGBO(75, 192, 192, 1),
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                  LineSeries<ChartData, double>(
                    name: 'Tiền lãi',
                    dataSource: _chartData,
                    xValueMapper: (ChartData data, _) => data.year,
                    yValueMapper: (ChartData data, _) => data.interest,
                    color: const Color.fromRGBO(53, 162, 235, 1),
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                  LineSeries<ChartData, double>(
                    name: 'Tổng giá trị',
                    dataSource: _chartData,
                    xValueMapper: (ChartData data, _) => data.year,
                    yValueMapper: (ChartData data, _) => data.total,
                    color: const Color.fromRGBO(255, 99, 132, 1),
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                ],
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x năm\npoint.y VNĐ',
                ),
              ),
            ),
            
            // Hiển thị giá trị khi click
            if (_selectedIndex != null && _selectedIndex! < _chartData.length)
              _buildSelectedPointInfo(),
          ],
        ),
      ),
    );
  }

  void _handleChartTap(Offset position) {
    // Tính toán index dựa trên vị trí tap
    if (_chartData.isEmpty) return;
    
    final chartWidth = 400.0; // Chiều rộng ước tính của chart
    final xStep = chartWidth / (_chartData.length - 1);
    final tappedIndex = (position.dx / xStep).round();
    
    if (tappedIndex >= 0 && tappedIndex < _chartData.length) {
      setState(() {
        _selectedIndex = tappedIndex;
      });
    }
  }

  Widget _buildSelectedPointInfo() {
    final data = _chartData[_selectedIndex!];
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Năm ${data.year.toInt()}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildValueItem('Tổng giá trị', data.total, Colors.red),
              _buildValueItem('Tiền lãi', data.interest, Colors.green),
              _buildValueItem('Tiền gốc', data.principal, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatCompactValue(value),
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatCompactValue(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}T';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}Tr';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildComparisonSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Lãi đơn vs Lãi kép', Icons.compare),
            const SizedBox(height: 12),
            
            _buildComparisonItem(
              'Lãi đơn',
              Icons.trending_down,
              Colors.red,
              'Lãi chỉ tính trên tiền gốc ban đầu',
              '100 triệu × 8% × 10 năm = 180 triệu',
            ),
            const SizedBox(height: 12),
            
            _buildComparisonItem(
              'Lãi kép',
              Icons.trending_up,
              Colors.green,
              'Lãi được cộng dồn vào gốc',
              '100 triệu × (1.08)¹⁰ = 216 triệu',
            ),
            
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Chênh lệch: 36 triệu VNĐ với 100 triệu gốc trong 10 năm!',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonItem(String title, IconData icon, Color color, String desc, String example) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(desc, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(example, style: TextStyle(fontSize: 11, color: color, fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    final shortTips = [
      'Bắt đầu sớm - Thời gian là yếu tố quan trọng nhất',
      'Kiên trì đều đặn - Tính kỷ luật quan trọng hơn số tiền lớn',
      'Chọn lãi suất tốt - So sánh các kênh đầu tư',
    ];

    final fullTips = [
      '• Bắt đầu sớm: Thời gian là yếu tố quan trọng nhất. Bắt đầu đầu tư từ 20 tuổi sẽ có lợi thế khổng lồ so với 30 tuổi.',
      '• Kiên trì đều đặn: Gửi tiết kiệm đều đặn mỗi tháng, dù chỉ 1-2 triệu. Tính kỷ luật quan trọng hơn số tiền lớn.',
      '• Chọn lãi suất tốt: So sánh nhiều kênh đầu tư. Chênh lệch 2-3% lãi suất có thể tạo ra hàng trăm triệu sau 20 năm.',
      '• Đa dạng hóa: Không bỏ tất cả trứng vào một giỏ. Phân bổ vốn vào nhiều kênh đầu tư khác nhau.',
      '• Tái đầu tư lợi nhuận: Để lãi tiếp tục sinh lãi, không rút ra sử dụng.',
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Bí quyết đầu tư', Icons.lightbulb),
            const SizedBox(height: 12),
            
            ...(_showFullTips ? fullTips : shortTips).map((tip) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $tip', style: const TextStyle(fontSize: 12)),
              ),
            ).toList(),

            GestureDetector(
              onTap: () => setState(() => _showFullTips = !_showFullTips),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showFullTips ? 'Thu gọn' : 'Xem thêm bí quyết',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      _showFullTips ? Icons.expand_less : Icons.expand_more,
                      color: Colors.blue.shade700,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      {
        'question': 'Lãi suất bao nhiêu là hợp lý?',
        'answer': '• Tiết kiệm ngân hàng: 4-6%/năm\n• Trái phiếu: 6-8%/năm\n• Quỹ đầu tư: 8-12%/năm\n• Cổ phiếu: 10-15%/năm'
      },
      {
        'question': 'Nên bắt đầu với bao nhiêu tiền?',
        'answer': 'Không cần số tiền lớn. Quan trọng là tính đều đặn. Bắt đầu với 500.000-1.000.000 VNĐ/tháng.'
      },
      {
        'question': 'Có rủi ro gì khi đầu tư dài hạn?',
        'answer': '• Rủi ro lạm phát\n• Rủi ro thanh khoản\n• Rủi ro thị trường\n→ Đa dạng hóa danh mục'
      },
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Câu hỏi thường gặp', Icons.help),
            const SizedBox(height: 12),
            
            ...faqs.take(_showFullFAQ ? faqs.length : 2).map((faq) => 
              _buildFAQItem(faq['question']!, faq['answer']!),
            ).toList(),

            if (faqs.length > 2) GestureDetector(
              onTap: () => setState(() => _showFullFAQ = !_showFullFAQ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showFullFAQ ? 'Thu gọn' : 'Xem thêm câu hỏi',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      _showFullFAQ ? Icons.expand_less : Icons.expand_more,
                      color: Colors.blue.shade700,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Lưu ý: Kết quả chỉ mang tính tham khảo. Tham khảo chuyên gia trước khi đầu tư.',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            dense: true,
          ),
          if (isExpanded) Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: child,
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final double year;
  final double principal;
  final double interest;
  final double total;

  ChartData(this.year, this.principal, this.interest, this.total);
}

class CalculationResult {
  final double total;
  final double interestEarned;
  final double contributions;

  CalculationResult(this.total, this.interestEarned, this.contributions);
}