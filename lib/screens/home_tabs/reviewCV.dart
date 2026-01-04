// screens/resume_review_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:viejob_app/config/api_config.dart';
import 'dart:convert';
import '../../services/ai_service.dart';

class ResumeReviewScreen extends StatefulWidget {
  const ResumeReviewScreen({Key? key}) : super(key: key);

  @override
  State<ResumeReviewScreen> createState() => _ResumeReviewScreenState();
}

class _ResumeReviewScreenState extends State<ResumeReviewScreen> {
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  String _errorMessage = '';
  String _feedback = '';
  final AIService _aiService = AIService();

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _errorMessage = '';
          _feedback = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi chọn file: $e';
      });
    }
  }

  Future<void> _analyzeResume() async {
    if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn file PDF CV để phân tích.';
      });
      return;
    }

    if (_selectedFile!.extension != 'pdf') {
      setState(() {
        _errorMessage = 'Chỉ hỗ trợ file PDF.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _feedback = '';
    });

    try {
      // Tạo request để upload file PDF
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_aiService.baseUrl}${ApiConfig.resumeReview}'),
      );

      // Thêm file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        ),
      );

      // Gửi request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          _feedback = jsonResponse['feedback'] ?? 
                     jsonResponse['analysis']?['summary'] ?? 
                     'Không nhận được phản hồi từ AI.';
        });
      } else {
        setState(() {
          _errorMessage = jsonResponse['message'] ?? 'Có lỗi xảy ra khi phân tích CV.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Có lỗi xảy ra khi phân tích CV: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF0D9488),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_feedback.isNotEmpty) {
      return _buildFeedbackResult();
    }

    return _buildEmptyState();
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Đang phân tích CV...',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vui lòng đợi trong giây lát',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.description_outlined,
            size: 40,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Sẵn sàng phân tích CV',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Tải CV lên và nhấp vào "Phân tích" để nhận được đánh giá chi tiết và gợi ý cải thiện từ AI',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackResult() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _formatFeedbackText(_feedback),
      ),
    );
  }

  List<Widget> _formatFeedbackText(String text) {
    final lines = text.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Tiêu đề chính (I. / II. / III. / ...)
      if (RegExp(r'^[IVX]+\.').hasMatch(line)) {
        widgets.add(
          Text(
            line,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
        );
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Tiêu đề phụ dạng **...**
      if (RegExp(r'^\*\*(.+)\*\*$').hasMatch(line)) {
        widgets.add(
          Text(
            line.replaceAll('**', ''),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
        );
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Bullet point (- hoặc *)
      if (RegExp(r'^[-*]\s+').hasMatch(line)) {
        final content = line.replaceAll(RegExp(r'^[-*]\s+'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: _buildFormattedText(content),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Các dòng có **đậm** trong câu
      if (line.contains('**')) {
        widgets.add(_buildFormattedText(line));
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Mặc định: dòng thường
      widgets.add(
        Text(
          line,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 6));
    }

    return widgets;
  }

  Widget _buildFormattedText(String text) {
    final parts = text.split('**');
    final List<TextSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        // Text đậm
        spans.add(
          TextSpan(
            text: parts[i],
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
              fontSize: 14,
            ),
          ),
        );
      } else {
        // Text thường
        spans.add(
          TextSpan(
            text: parts[i],
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Upload Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.upload_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phân tích CV',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Powered by AI',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          // File Upload Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tải CV của bạn lên',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _pickFile,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFD1D5DB),
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFFF9FAFB),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 40,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Nhấn để chọn file PDF',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Chỉ hỗ trợ file PDF (tối đa 5MB)',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_selectedFile != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFBBF7D0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: const Color(0xFF16A34A),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _selectedFile!.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF166534),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Analyze Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _analyzeResume,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                shadowColor: const Color(0xFF0D9488)
                                    .withOpacity(0.3),
                              ),
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Đang phân tích...',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Phân tích',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          if (_errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFECACA),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: const Color(0xFFDC2626),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Features Section
                          Container(
                            padding: const EdgeInsets.only(top: 20),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: const Color(0xFFF3F4F6),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tính năng:',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  children: [
                                    _buildFeatureItem('Phân tích cấu trúc CV'),
                                    const SizedBox(height: 8),
                                    _buildFeatureItem('Đánh giá nội dung'),
                                    const SizedBox(height: 8),
                                    _buildFeatureItem('Gợi ý cải thiện'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Results Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kết quả phân tích',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Chi tiết và gợi ý cải thiện',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Container(
                      height: 400,
                      padding: const EdgeInsets.all(0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: _buildFeedbackContent(),
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
}