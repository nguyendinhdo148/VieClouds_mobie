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
  void _simulateFilePick() {
    // This is just for demonstration
    // In production, use actual file picker
    setState(() {
      _fileName = 'profile_image.jpg';
      // _selectedFile would be an actual File object in real implementation
    });
    
    // Show dialog to inform user
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thông báo'),
        content: Text('Trong phiên bản thực tế, tính năng chọn file sẽ được tích hợp với package file_picker.'),
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
        title: Text(
          'Đăng ký tài khoản',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Fullname
                CustomTextField(
                  hintText: 'Họ và tên',
                  controller: _fullnameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                // Email
                CustomTextField(
                  hintText: 'Email',
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
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                // Phone Number
                CustomTextField(
                  hintText: 'Số điện thoại',
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
                  prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                // Password
                CustomTextField(
                  hintText: 'Mật khẩu',
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
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Confirm Password
                CustomTextField(
                  hintText: 'Xác nhận mật khẩu',
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // File Upload Section
                _buildFileUploadSection(),
                const SizedBox(height: 16),

                // Role selection (ẩn nếu là admin email)
                if (!_isAdminEmail) ...[
                  Text(
                    'Vai trò',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('Sinh viên', style: GoogleFonts.inter()),
                          value: 'student',
                          groupValue: _selectedRole,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('Nhà tuyển dụng', style: GoogleFonts.inter()),
                          value: 'recruiter',
                          groupValue: _selectedRole,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Admin badge
                if (_isAdminEmail) 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Tài khoản Admin',
                            style: GoogleFonts.inter(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Error message
                if (_errorMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: GoogleFonts.inter(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_errorMessage.isNotEmpty) const SizedBox(height: 16),
                
                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _isLoading
                      ? const Center(
                          child: SpinKitFadingCircle(
                            color: Colors.green,
                            size: 40.0,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Đăng ký',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Bằng việc đăng ký, bạn đồng ý với Điều khoản dịch vụ và Chính sách bảo mật của chúng tôi',
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ảnh đại diện (Tùy chọn)',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        
        if (_fileName == null)
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Chọn file ảnh',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'JPG, PNG, PDF (Tối đa 5MB)',
                    style: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green[300]!, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.green[50],
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName!,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: Colors.green[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'File đã chọn',
                        style: GoogleFonts.inter(
                          color: Colors.green[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _removeFile,
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 4),
        Text(
          'Chọn ảnh đại diện cho tài khoản của bạn (không bắt buộc)',
          style: GoogleFonts.inter(
            color: Colors.grey[600],
            fontSize: 12,
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