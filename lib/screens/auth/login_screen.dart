import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:viejob_app/admin_screen/dashboard_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_textfield.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function(String role) onLoginSuccess;
  
  const LoginScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _showPassword = false;
  String _errorMessage = '';
  String _selectedRole = 'student';
  bool _isAdminEmail = false;

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

void _login() async {
  if (!_formKey.currentState!.validate()) return;
  
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  final result = await _authService.login(
    _emailController.text,
    _passwordController.text,
    _selectedRole,
  );

  setState(() {
    _isLoading = false;
  });

  if (result['success'] == true) {
    if (mounted) {
      // Sử dụng addPostFrameCallback để đảm bảo navigation không xảy ra trong quá trình build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Dựa vào role để quyết định điều hướng
        if (_selectedRole == 'admin') {
          // Điều hướng đến admin dashboard
          widget.onLoginSuccess('admin');
        } else {
          // Gọi callback cho các role khác
          widget.onLoginSuccess(_selectedRole);
        }
      });
    }
  } else {
    setState(() {
      _errorMessage = result['error'];
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                // TIÊU ĐỀ CHÍNH
                Text(
                  'CHÀO MỪNG ĐẾN VỚI',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[700],
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'VIEJOBS',
                  style: GoogleFonts.inter(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFA8D8EA),
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hành trình sự nghiệp bắt đầu từ đây',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 40),
                
                // FORM ĐĂNG NHẬP
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 20,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ĐĂNG NHẬP TÀI KHOẢN',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // EMAIL FIELD
                      CustomTextField(
                        hintText: 'Email của bạn',
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
                      
                      // PASSWORD FIELD
                      CustomTextField(
                        hintText: 'Mật khẩu',
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        validator: (value) {
                          if (!_isAdminEmail) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            if (value.length < 8) {
                              return 'Mật khẩu phải có ít nhất 8 ký tự';
                            }
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

                      // ROLE SELECTION
                      if (!_isAdminEmail) ...[
                        Text(
                          'VAI TRÒ CỦA BẠN',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.grey[700],
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleCard(
                                title: 'ỨNG VIÊN',
                                isSelected: _selectedRole == 'student',
                                onTap: () => setState(() => _selectedRole = 'student'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildRoleCard(
                                title: 'NHÀ TUYỂN DỤNG',
                                isSelected: _selectedRole == 'recruiter',
                                onTap: () => setState(() => _selectedRole = 'recruiter'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ADMIN BADGE
                      if (_isAdminEmail) 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // ERROR MESSAGE
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
                      
                      const SizedBox(height: 24),
                      
                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: _isLoading
                            ? Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFA8D8EA),
                                      const Color(0xFF7EC5E9),
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
                                onPressed: _login,
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
                                        const Color(0xFFA8D8EA),
                                        const Color(0xFF7EC5E9),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFA8D8EA).withOpacity(0.5),
                                        blurRadius: 15,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'ĐĂNG NHẬP',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // SIGN UP LINK
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chưa có tài khoản? ',
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterScreen(
                                    onRegisterSuccess: () => widget.onLoginSuccess('student'),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'ĐĂNG KÝ NGAY',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFA8D8EA),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // FOOTER
                Text(
                  'Bắt đầu hành trình sự nghiệp cùng VieJobs',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFA8D8EA).withOpacity(0.15)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFA8D8EA)
                : Colors.grey[200]!,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFA8D8EA).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF2D3748)
                    : Colors.grey[700],
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}