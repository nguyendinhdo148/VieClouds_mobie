// screens/admin_screen/users_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:viejob_app/services/admin_service.dart';
import 'package:viejob_app/services/auth_service.dart';
import 'package:viejob_app/core/secure_storage.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();
  
  bool _isLoading = true;
  bool _isMobile = false;
  Map<String, dynamic> _user = {};
  List<dynamic> _users = [];
  int _totalItems = 0;
  final TextEditingController _searchController = TextEditingController();

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
      
      if (!mounted) return;
      
      setState(() {
        _user = user;
      });
      
      await _loadUsers();
      
    } catch (e) {
      print('Error checking auth: $e');
      context.go('/login');
    }
  }

  Future<void> _loadUsers({String? search}) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _adminService.getAllUsers(
        search: search,
      );
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        final users = result['users'] ?? [];
        setState(() {
          _users = users;
          _totalItems = result['total'] ?? result['count'] ?? users.length;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError('Không thể tải danh sách người dùng: ${result['error']}');
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      _showError('Lỗi: $e');
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa người dùng "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final result = await _adminService.deleteUser(userId);
      
      if (result['success'] == true) {
        _showSuccess('Đã xóa người dùng thành công');
        await _loadUsers(search: _searchController.text);
      } else {
        _showError(result['error'] ?? 'Không thể xóa người dùng');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getRoleColor(user['role']),
              child: Text(
                user['fullname']?.toString().isNotEmpty == true
                    ? user['fullname'].toString()[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
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
                    user['fullname']?.toString() ?? 'Không có tên',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['email']?.toString() ?? 'Không có email',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user['role']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _getRoleColor(user['role']).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getRoleText(user['role']),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getRoleColor(user['role']),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (user['phoneNumber'] != null && user['phoneNumber'].toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Iconsax.call, size: 10, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                user['phoneNumber'].toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (user['createdAt'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Tham gia: ${_formatDate(user['createdAt'].toString())}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      const Icon(Iconsax.eye, size: 16),
                      const SizedBox(width: 8),
                      Text('Xem chi tiết', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Iconsax.edit, size: 16),
                      const SizedBox(width: 8),
                      Text('Chỉnh sửa', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Iconsax.trash, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(fontSize: 14, color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteUser(user['_id'].toString(), user['fullname']?.toString() ?? 'người dùng');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getRoleColor(String? role) {
    final roleStr = role?.toString() ?? '';
    switch (roleStr) {
      case 'admin':
        return Colors.purple;
      case 'recruiter':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleText(String? role) {
    final roleStr = role?.toString() ?? '';
    switch (roleStr) {
      case 'admin':
        return 'Quản trị viên';
      case 'recruiter':
        return 'Nhà tuyển dụng';
      case 'student':
        return 'Ứng viên';
      default:
        return roleStr;
    }
  }

  Widget _buildContent() {
    _isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      padding: _isMobile ? const EdgeInsets.all(12) : const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          if (_isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải danh sách người dùng...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_users.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.profile_2user,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không có người dùng nào',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadUsers(),
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) => _buildUserCard(_users[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          if (!_isMobile) _buildDesktopSidebar(),
          Expanded(
            child: Column(
              children: [
                if (!_isMobile) _buildDesktopAppBar(),
                Expanded(
                  child: _isLoading && _user.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 20),
                              Text(
                                'Đang tải...',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _isMobile ? _buildMobileSidebar() : null,
      appBar: _isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Iconsax.menu_1, color: Colors.black),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              title: const Text(
                'Người dùng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            )
          : null,
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
            'Người dùng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileSidebar() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      _user['fullname']?.toString().isNotEmpty == true
                          ? _user['fullname'].toString()[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user['fullname']?.toString() ?? 'Admin',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildSidebarItem(
                      icon: Iconsax.home_2,
                      label: 'Dashboard',
                      isActive: GoRouterState.of(context).uri.toString() == '/admin',
                      onTap: () => context.go('/admin'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.profile_2user,
                      label: 'Quản lý người dùng',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/users'),
                      onTap: () => context.go('/admin/users'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.building_4,
                      label: 'Quản lý công ty',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/companies'),
                      onTap: () => context.go('/admin/companies'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.briefcase,
                      label: 'Quản lý việc làm',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/jobs'),
                      onTap: () => context.go('/admin/jobs'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.document_text,
                      label: 'Quản lý blog',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/blogs'),
                      onTap: () => context.go('/admin/blogs'),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: ListTile(
                leading: const Icon(Iconsax.logout, color: Colors.red),
                title: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => _authService.logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 256,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      _user['fullname']?.toString().isNotEmpty == true
                          ? _user['fullname'].toString()[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.blue,
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
                          _user['fullname']?.toString() ?? 'Admin',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSidebarItem(
                      icon: Iconsax.home_2,
                      label: 'Dashboard',
                      isActive: GoRouterState.of(context).uri.toString() == '/admin',
                      onTap: () => context.go('/admin'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.profile_2user,
                      label: 'Quản lý người dùng',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/users'),
                      onTap: () => context.go('/admin/users'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.building_4,
                      label: 'Quản lý công ty',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/companies'),
                      onTap: () => context.go('/admin/companies'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.briefcase,
                      label: 'Quản lý việc làm',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/jobs'),
                      onTap: () => context.go('/admin/jobs'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.document_text,
                      label: 'Quản lý blog',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/blogs'),
                      onTap: () => context.go('/admin/blogs'),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: ListTile(
                leading: const Icon(Iconsax.logout, size: 16, color: Colors.red),
                title: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => _authService.logout(context),
              ),
            ),
          ],
        ),
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
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: isActive ? Colors.blue : Colors.black,
        ),
      ),
      tileColor: isActive ? Colors.blue.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      dense: true,
      onTap: onTap,
    );
  }
}