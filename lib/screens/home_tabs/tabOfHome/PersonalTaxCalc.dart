import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PersonalTaxCalc extends StatefulWidget {
  const PersonalTaxCalc({super.key});

  @override
  State<PersonalTaxCalc> createState() => _PersonalTaxCalcState();
}

class _PersonalTaxCalcState extends State<PersonalTaxCalc> {
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _insuranceBaseController = TextEditingController();
  final TextEditingController _dependentsController = TextEditingController();
  
  bool _useCustomInsurance = false;
  String _region = 'I';
  String _taxYear = '2025';
  
  // Regional minimum wages
  final Map<String, int> _regionMinWages2024 = {
    'I': 4960000,
    'II': 4410000,
    'III': 3860000,
    'IV': 3450000,
  };

  final Map<String, int> _regionMinWages2025 = {
    'I': 4960000,
    'II': 4410000,
    'III': 3860000,
    'IV': 3450000,
  };

  // Constants
  final int _maxSocialInsurance = 4680000 * 10;
  final int _maxHealthInsurance = 4680000 * 10;
  final int _personalDeduction = 11000000;
  final int _dependentDeduction = 4400000;

  // Calculation result
  Map<String, dynamic>? _calculationDetails;

  Map<String, int> get _regionMinWages {
    return _taxYear == '2025' ? _regionMinWages2025 : _regionMinWages2024;
  }

  String _formatCurrency(double value) {
    return NumberFormat.decimalPattern('vi').format(value);
  }

  String _formatInputNumber(String value) {
    final cleanValue = value.replaceAll('.', '');
    if (cleanValue.isEmpty) return '';
    
    final number = int.tryParse(cleanValue);
    if (number == null) return '';
    
    return NumberFormat.decimalPattern('vi').format(number);
  }

  Map<String, double> _calculateInsurance(double grossIncome, double insuranceBaseSalary) {
    final regionWage = _regionMinWages[_region]!.toDouble();
    
    // Social insurance (8% capped at _maxSocialInsurance)
    final socialInsurance = (insuranceBaseSalary > _maxSocialInsurance 
        ? _maxSocialInsurance 
        : insuranceBaseSalary) * 0.08;

    // Health insurance (1.5% capped at _maxHealthInsurance)
    final healthInsurance = (insuranceBaseSalary > _maxHealthInsurance 
        ? _maxHealthInsurance 
        : insuranceBaseSalary) * 0.015;

    // Unemployment insurance (1% capped at 20 times regional minimum wage)
    final unemploymentCap = regionWage * 20;
    final unemploymentInsurance = grossIncome * 0.01 > unemploymentCap 
        ? unemploymentCap 
        : grossIncome * 0.01;

    return {
      'socialInsurance': socialInsurance,
      'healthInsurance': healthInsurance,
      'unemploymentInsurance': unemploymentInsurance,
      'totalInsurance': socialInsurance + healthInsurance + unemploymentInsurance,
    };
  }

  void _calculateTax() {
    final grossIncome = double.tryParse(_incomeController.text.replaceAll('.', '')) ?? 0;
    final insuranceBaseSalary = _useCustomInsurance
        ? double.tryParse(_insuranceBaseController.text.replaceAll('.', '')) ?? grossIncome
        : grossIncome;
    final numDependents = int.tryParse(_dependentsController.text) ?? 0;

    if (grossIncome == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập thu nhập Gross')),
      );
      return;
    }

    // Insurance calculations
    final insurance = _calculateInsurance(grossIncome, insuranceBaseSalary);
    final totalInsurance = insurance['totalInsurance']!;

    // Deductions
    final personalDeduction = _personalDeduction.toDouble();
    final dependentDeduction = _dependentDeduction * numDependents;

    // Taxable income
    final incomeBeforeTax = grossIncome - totalInsurance;
    final taxableIncome = incomeBeforeTax - personalDeduction - dependentDeduction;

    if (taxableIncome <= 0) {
      setState(() {
        _calculationDetails = {
          'grossIncome': grossIncome,
          'socialInsurance': insurance['socialInsurance']!,
          'healthInsurance': insurance['healthInsurance']!,
          'unemploymentInsurance': insurance['unemploymentInsurance']!,
          'taxableIncome': 0.0,
          'personalDeduction': personalDeduction,
          'dependentDeduction': dependentDeduction.toDouble(),
          'taxAmount': 0.0,
          'breakdown': [],
          'netIncome': incomeBeforeTax,
        };
      });
      return;
    }

    // Tax brackets
    final brackets = [
      {'min': 0, 'max': 5000000, 'rate': 0.05, 'fixedAmount': 0},
      {'min': 5000000, 'max': 10000000, 'rate': 0.1, 'fixedAmount': 250000},
      {'min': 10000000, 'max': 18000000, 'rate': 0.15, 'fixedAmount': 750000},
      {'min': 18000000, 'max': 32000000, 'rate': 0.2, 'fixedAmount': 1950000},
      {'min': 32000000, 'max': 52000000, 'rate': 0.25, 'fixedAmount': 4750000},
      {'min': 52000000, 'max': 80000000, 'rate': 0.3, 'fixedAmount': 9750000},
      {'min': 80000000, 'max': double.infinity, 'rate': 0.35, 'fixedAmount': 18150000},
    ];

double remainingIncome = taxableIncome;
double totalTax = 0;
final List<Map<String, dynamic>> breakdown = [];

for (int i = 0; i < brackets.length; i++) {
  final bracket = brackets[i];
  if (remainingIncome <= 0) break;

  final double min = bracket['min'] as double;
  final double max = bracket['max'] as double;
  final double rate = bracket['rate'] as double;

  final double bracketRange = max - min;

  final double taxableInBracket =
      remainingIncome < bracketRange ? remainingIncome : bracketRange;

  if (taxableInBracket > 0) {
    final double taxForBracket = taxableInBracket * rate;
    totalTax += taxForBracket;

    breakdown.add({
      'bracket': i == 0
          ? 'Đến ${_formatCurrency(max)}'
          : 'Trên ${_formatCurrency(min)} '
              'đến ${max == double.infinity ? "" : _formatCurrency(max)}',
      'taxableAmount': taxableInBracket,
      'rate': rate * 100,
      'taxAmount': taxForBracket,
    });

    remainingIncome -= taxableInBracket;
  }
}



    

    setState(() {
      _calculationDetails = {
        'grossIncome': grossIncome,
        'socialInsurance': insurance['socialInsurance']!,
        'healthInsurance': insurance['healthInsurance']!,
        'unemploymentInsurance': insurance['unemploymentInsurance']!,
        'taxableIncome': taxableIncome,
        'personalDeduction': personalDeduction,
        'dependentDeduction': dependentDeduction.toDouble(),
        'taxAmount': totalTax.roundToDouble(),
        'breakdown': breakdown,
        'netIncome': incomeBeforeTax - totalTax,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tính Thuế TNCN'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
      
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calculate, size: 40, color: Colors.indigo[700]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Công cụ tính Thuế thu nhập cá nhân',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.indigo),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Chuẩn 2025',
                            style: TextStyle(
                              color: Colors.indigo[600],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Tax Year Selection
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Áp dụng quy định:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile(
                            title: Text('Từ 01/07/2024 - 30/06/2025'),
                            value: '2024-2025',
                            groupValue: _taxYear,
                            onChanged: (value) {
                              setState(() {
                                _taxYear = value.toString();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    RadioListTile(
                      title: Text('Từ 01/07/2025 (Mới nhất)'),
                      value: '2025',
                      groupValue: _taxYear,
                      onChanged: (value) {
                        setState(() {
                          _taxYear = value.toString();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Deduction Info
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            'Giảm trừ bản thân',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '11,000,000đ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            'Người phụ thuộc',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '4,400,000đ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Input Form
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin tính thuế',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Gross Income
                    _buildInputField(
                      label: 'Thu nhập Gross',
                      controller: _incomeController,
                      hintText: 'VD: 15,000,000',
                    ),
                    SizedBox(height: 16),

                    // Region Selection
                    _buildRegionDropdown(),
                    SizedBox(height: 16),

                    // Custom Insurance Toggle
                    _buildCustomInsuranceToggle(),
                    SizedBox(height: 16),

                    // Dependents
                    _buildInputField(
                      label: 'Số người phụ thuộc',
                      controller: _dependentsController,
                      hintText: '0',
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 20),

                    // Calculate Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _calculateTax,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Tính thuế TNCN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Results Section
            if (_calculationDetails != null) _buildResults(),

            // Information Section
            _buildInformationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) {
            if (keyboardType != TextInputType.number) {
              final formatted = _formatInputNumber(value);
              if (formatted != controller.text) {
                controller.text = formatted;
                controller.selection = TextSelection.collapsed(offset: formatted.length);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildRegionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vùng lương tối thiểu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _region,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _regionMinWages.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text('Vùng ${entry.key}: ${_formatCurrency(entry.value.toDouble())}'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _region = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCustomInsuranceToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _useCustomInsurance,
              onChanged: (value) {
                setState(() {
                  _useCustomInsurance = value!;
                });
              },
            ),
            Text('Sử dụng mức lương đóng BHXH khác'),
          ],
        ),
        if (_useCustomInsurance) ...[
          SizedBox(height: 8),
          _buildInputField(
            label: 'Mức lương đóng BHXH',
            controller: _insuranceBaseController,
            hintText: 'Nhập mức lương đóng BHXH',
          ),
        ],
        Text(
          'Mức đóng BHXH tối đa: ${_formatCurrency(_maxSocialInsurance.toDouble())} VND/tháng',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final details = _calculationDetails!;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kết quả tính thuế',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Overview
            _buildResultCard(
              'Tổng quan',
              [
                _buildResultRow('Lương GROSS:', _formatCurrency(details['grossIncome'])),
                _buildResultRow('BHXH (8%):', '-${_formatCurrency(details['socialInsurance'])}', isNegative: true),
                _buildResultRow('BHYT (1.5%):', '-${_formatCurrency(details['healthInsurance'])}', isNegative: true),
                _buildResultRow('BHTN (1%):', '-${_formatCurrency(details['unemploymentInsurance'])}', isNegative: true),
                _buildResultRow(
                  'Thu nhập trước thuế:',
                  _formatCurrency(details['grossIncome'] - details['socialInsurance'] - details['healthInsurance'] - details['unemploymentInsurance']),
                  isBold: true,
                ),
              ],
              color: Colors.grey[50],
            ),
            SizedBox(height: 12),

            // Deductions
            _buildResultCard(
              'Giảm trừ',
              [
                _buildResultRow('Giảm trừ bản thân:', '-${_formatCurrency(details['personalDeduction'])}', isPositive: true),
                _buildResultRow('Giảm trừ người phụ thuộc:', '-${_formatCurrency(details['dependentDeduction'])}', isPositive: true),
                _buildResultRow('Thu nhập chịu thuế:', _formatCurrency(details['taxableIncome']), isBold: true),
              ],
              color: Colors.blue[50],
            ),
            SizedBox(height: 12),

            // Tax Summary
            _buildResultCard(
              'Thuế TNCN',
              [
                _buildResultRow('Tổng thuế phải nộp:', _formatCurrency(details['taxAmount']), isLarge: true),
                _buildResultRow('Lương NET:', _formatCurrency(details['netIncome']), isBold: true, isPositive: true),
              ],
              color: Colors.purple[50],
            ),

            // Tax Breakdown
            if ((details['breakdown'] as List).isNotEmpty) ...[
              SizedBox(height: 12),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chi tiết tính thuế',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...(details['breakdown'] as List<Map<String, dynamic>>).map((item) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item['bracket'],
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              Text('${item['rate']}%'),
                              Text(_formatCurrency(item['taxAmount'])),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, List<Widget> children, {Color? color}) {
    return Card(
      color: color,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {
    bool isNegative = false,
    bool isPositive = false,
    bool isBold = false,
    bool isLarge = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isNegative
                  ? Colors.red
                  : isPositive
                      ? Colors.green
                      : Colors.black,
              fontWeight: isBold || isLarge ? FontWeight.bold : FontWeight.normal,
              fontSize: isLarge ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin về thuế TNCN',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Regional Wages Table
            Text(
              'Mức lương tối thiểu vùng',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ..._regionMinWages.entries.map((entry) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Vùng ${entry.key}:'),
                    Text(_formatCurrency(entry.value.toDouble())),
                  ],
                ),
              );
            }).toList(),

            SizedBox(height: 16),
            Text(
              'Công thức: Thuế TNCN = Thu nhập tính thuế × Thuế suất',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}