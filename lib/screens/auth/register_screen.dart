import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../widgets/custom_textfield.dart';
import 'package:file_picker/file_picker.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegisterSuccess;
  
  const RegisterScreen({Key? key, required this.onRegisterSuccess}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _errorMessage = '';
  String _selectedRole = 'student';
  bool _isAdminEmail = false;
  File? _selectedFile;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkAdminEmail);
  }

  void _checkAdminEmail() {
    if (_emailController.text.isNotEmpty) {
      setState(() {
        _isAdminEmail = _authService.isAdminEmail(_emailController.text);
        if (_isAdminEmail) {
          _selectedRole = 'admin';
        }
      });
    }
  }

  // Chọn file từ device
Future<void> _pickFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      PlatformFile file = result.files.first;
      
      if (file.path != null) {
        setState(() {
          _selectedFile = File(file.path!);
          _fileName = file.name;
        });
        
        print('✅ File selected: ${file.name}');
        
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chọn file: ${file.name}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _showErrorDialog('Không thể truy cập file. Vui lòng thử file khác.');
      }
    }
  } catch (e) {
    print('❌ File picker error: $e');
    _showErrorDialog('Lỗi khi chọn file: ${e.toString()}');
  }
}
void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Lỗi'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
    });
  }

void _register() async {
  if (!_formKey.currentState!.validate()) return;
  
  if (_passwordController.text != _confirmPasswordController.text) {
    setState(() {
      _errorMessage = 'Mật khẩu xác nhận không khớp';
    });
    return;
  }
  
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  try {
    final result = await _authService.registerWithFile(
      fullname: _fullnameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phoneNumber: _phoneController.text,
      role: _selectedRole,
      file: _selectedFile,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      if (mounted) {
        await Future.delayed(Duration(milliseconds: 500));
        
        // HIỂN THỊ THÔNG BÁO PHÙ HỢP
        final message = result['message'] ?? 'Đăng ký thành công!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        await Future.delayed(Duration(milliseconds: 1500));
        
        // KIỂM TRA XEM CẦN ĐĂNG NHẬP THỦ CÔNG KHÔNG
        if (result['needsManualLogin'] == true) {
          // Điều hướng đến login screen
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          // Điều hướng đến main app
          widget.onRegisterSuccess();
        }
      }
    } else {
      setState(() {
        _errorMessage = result['error'] ?? 'Đăng ký thất bại';
      });
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'Lỗi kết nối: $e';
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ĐĂNG KÝ TÀI KHOẢN',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D3748),
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                

                Text(
                  'TẠO TÀI KHOẢN MỚI',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D3748),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Khám phá cơ hội việc làm phù hợp với bạn',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Fullname
                _buildLabel('HỌ VÀ TÊN'),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: 'Nhập họ và tên của bạn',
                  controller: _fullnameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Email
                _buildLabel('EMAIL'),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: 'example@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Phone Number
                _buildLabel('SỐ ĐIỆN THOẠI'),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: '09xxxxxxxx',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Password
                _buildLabel('MẬT KHẨU'),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: 'Ít nhất 8 ký tự',
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 8) {
                      return 'Mật khẩu phải có ít nhất 8 ký tự';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.grey[600],
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Confirm Password
                _buildLabel('XÁC NHẬN MẬT KHẨU'),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: 'Nhập lại mật khẩu',
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.grey[600],
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                const SizedBox(height: 20),

                // File Upload Section
                _buildFileUploadSection(),
                const SizedBox(height: 24),

                // Role selection (ẩn nếu là admin email)
if (!_isAdminEmail) ...[
  _buildLabel('VAI TRÒ CỦA BẠN'),
  const SizedBox(height: 6),
  Row(
    children: [
      Expanded(
        child: _buildRoleCard(
          title: 'ỨNG VIÊN',
          isSelected: _selectedRole == 'student',
          onTap: () => setState(() => _selectedRole = 'student'),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: _buildRoleCard(
          title: 'NHÀ TUYỂN DỤNG',
          isSelected: _selectedRole == 'recruiter',
          onTap: () => setState(() => _selectedRole = 'recruiter'),
        ),
      ),
    ],
  ),
  const SizedBox(height: 16),
],
                // Admin badge
                if (_isAdminEmail) 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green[50]!,
                          Colors.green[100]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TÀI KHOẢN ADMIN',
                          style: GoogleFonts.inter(
                            color: Colors.green[800],
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Error message
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red[200]!,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: GoogleFonts.inter(
                              color: Colors.red[800],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 28),
                
                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _isLoading
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFA8D8EA),
                                Color(0xFF7EC5E9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: SpinKitFadingCircle(
                              color: Colors.white,
                              size: 36.0,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFA8D8EA),
                                  Color(0xFF7EC5E9),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFA8D8EA).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'ĐĂNG KÝ TÀI KHOẢN',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Bằng việc đăng ký, bạn đồng ý với Điều khoản dịch vụ và Chính sách bảo mật của chúng tôi',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Colors.grey[700],
          letterSpacing: 0.3,
        ),
      ),
    );
  }

Widget _buildRoleCard({
  required String title,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? Color(0xFFA8D8EA).withOpacity(0.12)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? Color(0xFFA8D8EA)
              : Colors.grey[300]!,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Color(0xFFA8D8EA).withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? Color(0xFF2D3748)
              : Colors.grey[700],
          letterSpacing: 0.1,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('ẢNH ĐẠI DIỆN (TÙY CHỌN)'),
        const SizedBox(height: 12),
        
        if (_fileName == null)
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[50],
            ),
            child: InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CHỌN FILE ẢNH',
                    style: GoogleFonts.inter(
                      color: Color(0xFFA8D8EA),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'JPG, PNG, PDF (Tối đa 5MB)',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.green[300]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
              color: Colors.green[50],
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName!,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Colors.green[800],
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'File đã được chọn',
                        style: GoogleFonts.inter(
                          color: Colors.green[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _removeFile,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red[700],
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 8),
        Text(
          'Chọn ảnh đại diện cho tài khoản của bạn (không bắt buộc)',
          style: GoogleFonts.inter(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}