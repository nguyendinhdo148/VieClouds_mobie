import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../home_tabs/home_tab.dart';
import '../home_tabs/reviewCV.dart';
import '../home_tabs/connect_tab.dart';
import '../home_tabs/notification_tab.dart';
import '../home_tabs/account_tab.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;
  int _currentIndex = 0;
  final AuthService _authService = AuthService(); // DI CHUYỂN LÊN ĐÂY

  final List<Widget> _tabs = [
    const HomeTab(),
    const ResumeReviewScreen(),
    const ConnectTab(),
    const NotificationTab(),
    const AccountTab(),
  ];

  final List<String> _tabTitles = [
    'Trang chủ',
    'Phân tích CV',
    'Kết nối',
    'Thông báo',
    'Tài khoản'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUser();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    // HIỆN DIALOG XÁC NHẬN
    final shouldLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận đăng xuất'),
          content: Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      // HIỆN LOADING
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // GỌI LOGOUT VỚI CONTEXT
        await _authService.logout(context);

        // ĐÓNG LOADING DIALOG
        if (mounted) Navigator.of(context).pop();

        // CHUYỂN VỀ LOGIN bằng GoRouter
        if (mounted) {
          GoRouter.of(context).go('/login');
        }
      } catch (e) {
        // ĐÓNG LOADING NẾU CÓ LỖI
        if (mounted) Navigator.of(context).pop();

        // VẪN CHUYỂN VỀ LOGIN DÙ CÓ LỖI
        if (mounted) {
          GoRouter.of(context).go('/login');
        }
      }
    }
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'student':
        return 'Sinh viên';
      case 'recruiter':
        return 'Nhà tuyển dụng';
      case 'admin':
        return 'Quản trị viên';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tabTitles[_currentIndex],
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: _currentIndex == 4 // Only show logout in account tab
            ? [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black87),
                  onPressed: _logout,
                  tooltip: 'Đăng xuất',
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: SpinKitFadingCircle(
                color: Colors.blue,
                size: 50.0,
              ),
            )
          : _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'CV & Hồ sơ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Kết nối',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}