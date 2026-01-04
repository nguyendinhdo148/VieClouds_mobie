// screens/admin_screen/dashboard_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:viejob_app/services/auth_service.dart';
import 'package:viejob_app/services/admin_service.dart';
import 'package:viejob_app/core/secure_storage.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();
  
  bool _isLoading = true;
  Map<String, dynamic> _user = {};
  Map<String, int> _stats = {
    'totalUsers': 0,
    'totalJobs': 0,
    'totalCompanies': 0,
    'totalBlogs': 0,
  };

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    try {
      final userJson = await _secureStorage.getUserData();
      
      if (userJson == null) {
        context.go('/login');
        return;
      }
      
      final user = jsonDecode(userJson);
      if (user['role'] != 'admin') {
        context.go('/login');
        return;
      }
      
      setState(() {
        _user = user;
      });
      
      await _loadDashboardData();
      
    } catch (e) {
      print('Error checking auth: $e');
      context.go('/login');
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final statsResult = await _adminService.getDashboardStats();
      
      if (statsResult['success'] == true) {
        setState(() {
          _stats = {
            'totalUsers': statsResult['totalUsers'] ?? 0,
            'totalJobs': statsResult['totalJobs'] ?? 0,
            'totalCompanies': statsResult['totalCompanies'] ?? 0,
            'totalBlogs': statsResult['totalBlogs'] ?? 0,
          };
        });
      }
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading dashboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(icon, color: color, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChart(List<double> data, Color color) {
    return SizedBox(
      width: 60,
      height: 30,
      child: CustomPaint(
        painter: _MiniChartPainter(data: data, color: color),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return SingleChildScrollView(
      child: Padding(
        padding: isMobile 
            ? const EdgeInsets.all(16)
            : const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, Admin! 👋',
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quản lý hệ thống VieJob',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _loadDashboardData,
                  icon: Icon(
                    Iconsax.refresh,
                    color: Colors.blue,
                    size: isMobile ? 20 : 24,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 2 : 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isMobile ? 1.4 : 1.6,
              children: [
                _buildStatCard(
                  icon: Iconsax.profile_2user,
                  title: 'Người dùng',
                  value: _stats['totalUsers']!,
                  color: Colors.blue,
                  onTap: () => context.go('/admin/users'),
                ),
                _buildStatCard(
                  icon: Iconsax.briefcase,
                  title: 'Việc làm',
                  value: _stats['totalJobs']!,
                  color: Colors.green,
                  onTap: () => context.go('/admin/jobs'),
                ),
                _buildStatCard(
                  icon: Iconsax.building_4,
                  title: 'Công ty',
                  value: _stats['totalCompanies']!,
                  color: Colors.orange,
                  onTap: () => context.go('/admin/companies'),
                ),
                _buildStatCard(
                  icon: Iconsax.document_text,
                  title: 'Bài viết',
                  value: _stats['totalBlogs']!,
                  color: Colors.purple,
                  onTap: () => context.go('/admin/blogs'),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Mini Charts Section
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.chart,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Biểu đồ thống kê',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            _buildMiniChart([10, 20, 15, 25, 30], Colors.blue),
                            const SizedBox(height: 8),
                            Text(
                              'Người dùng',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            _buildMiniChart([5, 15, 10, 20, 25], Colors.green),
                            const SizedBox(height: 8),
                            Text(
                              'Việc làm',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            _buildMiniChart([2, 8, 5, 12, 15], Colors.orange),
                            const SizedBox(height: 8),
                            Text(
                              'Công ty',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            _buildMiniChart([3, 10, 7, 15, 20], Colors.purple),
                            const SizedBox(height: 8),
                            Text(
                              'Bài viết',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Xu hướng tăng trưởng (5 ngày gần nhất)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Info Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.info_circle,
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thông tin hệ thống',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tổng số liệu thống kê từ hệ thống VieJob',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Đang tải dữ liệu...'),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          if (!isMobile) _buildDesktopSidebar(),
          Expanded(
            child: Column(
              children: [
                if (!isMobile) _buildDesktopAppBar(),
                Expanded(child: _buildDashboardContent()),
              ],
            ),
          ),
        ],
      ),
      drawer: isMobile ? _buildMobileSidebar() : null,
      appBar: isMobile ? _buildMobileAppBar() : null,
    );
  }

  AppBar _buildMobileAppBar() {
    return AppBar(
      title: const Text('Dashboard Admin'),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.refresh),
          onPressed: _loadDashboardData,
        ),
      ],
    );
  }

  Container _buildDesktopAppBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Iconsax.refresh, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSidebar() {
    return Drawer(
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  child: Text(
                    _user['fullname']?.isNotEmpty == true
                        ? _user['fullname'][0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user['fullname'] ?? 'Admin',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Quản trị viên',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildSidebarItem(
            icon: Iconsax.home_2,
            label: 'Dashboard',
            isActive: GoRouterState.of(context).uri.toString() == '/admin',
            onTap: () => context.go('/admin'),
          ),
          _buildSidebarItem(
            icon: Iconsax.profile_2user,
            label: 'Người dùng',
            isActive: GoRouterState.of(context).uri.toString().contains('/admin/users'),
            onTap: () => context.go('/admin/users'),
          ),
          _buildSidebarItem(
            icon: Iconsax.building_4,
            label: 'Công ty',
            isActive: GoRouterState.of(context).uri.toString().contains('/admin/companies'),
            onTap: () => context.go('/admin/companies'),
          ),
          _buildSidebarItem(
            icon: Iconsax.briefcase,
            label: 'Việc làm',
            isActive: GoRouterState.of(context).uri.toString().contains('/admin/jobs'),
            onTap: () => context.go('/admin/jobs'),
          ),
          _buildSidebarItem(
            icon: Iconsax.document_text,
            label: 'Blog',
            isActive: GoRouterState.of(context).uri.toString().contains('/admin/blogs'),
            onTap: () => context.go('/admin/blogs'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Iconsax.logout, color: Colors.red),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _authService.logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: Text(
                    _user['fullname']?.isNotEmpty == true
                        ? _user['fullname'][0].toUpperCase()
                        : 'A',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user['fullname'] ?? 'Admin',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Quản trị viên',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSidebarItem(
                  icon: Iconsax.home_2,
                  label: 'Dashboard',
                  isActive: GoRouterState.of(context).uri.toString() == '/admin',
                  onTap: () => context.go('/admin'),
                ),
                _buildSidebarItem(
                  icon: Iconsax.profile_2user,
                  label: 'Người dùng',
                  isActive: GoRouterState.of(context).uri.toString().contains('/admin/users'),
                  onTap: () => context.go('/admin/users'),
                ),
                _buildSidebarItem(
                  icon: Iconsax.building_4,
                  label: 'Công ty',
                  isActive: GoRouterState.of(context).uri.toString().contains('/admin/companies'),
                  onTap: () => context.go('/admin/companies'),
                ),
                _buildSidebarItem(
                  icon: Iconsax.briefcase,
                  label: 'Việc làm',
                  isActive: GoRouterState.of(context).uri.toString().contains('/admin/jobs'),
                  onTap: () => context.go('/admin/jobs'),
                ),
                _buildSidebarItem(
                  icon: Iconsax.document_text,
                  label: 'Blog',
                  isActive: GoRouterState.of(context).uri.toString().contains('/admin/blogs'),
                  onTap: () => context.go('/admin/blogs'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Iconsax.logout, size: 16, color: Colors.red),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
              onTap: () => _authService.logout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? Colors.blue : Colors.grey,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isActive ? Colors.blue : Colors.black,
          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? Colors.blue.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _MiniChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final pointWidth = size.width / (data.length - 1);
    
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw area
    final path = Path();
    path.moveTo(0, size.height);
    
    for (int i = 0; i < data.length; i++) {
      final x = i * pointWidth;
      final y = size.height - (data[i] / maxValue * size.height);
      
      if (i == 0) {
        path.lineTo(0, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Draw line
    final linePath = Path();
    linePath.moveTo(0, size.height - (data[0] / maxValue * size.height));
    
    for (int i = 1; i < data.length; i++) {
      final x = i * pointWidth;
      final y = size.height - (data[i] / maxValue * size.height);
      linePath.lineTo(x, y);
    }
    
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}