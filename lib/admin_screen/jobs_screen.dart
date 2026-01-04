// screens/admin_screen/jobs_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:viejob_app/services/admin_service.dart';
import 'package:viejob_app/services/auth_service.dart';
import 'package:viejob_app/core/secure_storage.dart';

class AdminJobsScreen extends StatefulWidget {
  final String? status;
  
  const AdminJobsScreen({Key? key, this.status}) : super(key: key);

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();
  
  bool _isLoading = true;
  bool _isMobile = false;
  Map<String, dynamic> _user = {};
  List<dynamic> _jobs = [];
  int _totalItems = 0;
  String _currentStatus = 'all';
  String _currentApproval = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status ?? 'all';
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
      
      await _loadJobs();
      
    } catch (e) {
      print('Error checking auth: $e');
      context.go('/login');
    }
  }

  Future<void> _loadJobs({String? search}) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _adminService.getAllJobs(
        status: _currentStatus == 'all' ? null : _currentStatus,
        approval: _currentApproval == 'all' ? null : _currentApproval,
        search: search,
      );
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        final jobs = result['jobs'] ?? [];
        setState(() {
          _jobs = jobs;
          _totalItems = result['total'] ?? result['count'] ?? jobs.length;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError('Không thể tải danh sách việc làm: ${result['error']}');
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      _showError('Lỗi: $e');
    }
  }

  Future<void> _approveJob(String jobId, String jobTitle) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận duyệt'),
        content: Text('Bạn có chắc muốn duyệt việc làm "$jobTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Duyệt', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final result = await _adminService.approveJob(jobId);
      
      if (result['success'] == true) {
        _showSuccess('Đã duyệt việc làm thành công');
        await _loadJobs(search: _searchController.text);
      } else {
        _showError(result['error'] ?? 'Không thể duyệt việc làm');
      }
    }
  }

  Future<void> _rejectJob(String jobId, String jobTitle) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối việc làm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Việc làm: "$jobTitle"'),
            const SizedBox(height: 12),
            const Text('Lý do từ chối:'),
            const SizedBox(height: 4),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do từ chối...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      final result = await _adminService.rejectJob(jobId, reasonController.text);
      
      if (result['success'] == true) {
        _showSuccess('Đã từ chối việc làm thành công');
        await _loadJobs(search: _searchController.text);
      } else {
        _showError(result['error'] ?? 'Không thể từ chối việc làm');
      }
    }
  }

  Future<void> _deleteJob(String jobId, String jobTitle) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa việc làm "$jobTitle"?'),
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
      final result = await _adminService.deleteJob(jobId);
      
      if (result['success'] == true) {
        _showSuccess('Đã xóa việc làm thành công');
        await _loadJobs(search: _searchController.text);
      } else {
        _showError(result['error'] ?? 'Không thể xóa việc làm');
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

  Widget _buildJobCard(Map<String, dynamic> job) {
    bool isPending = job['approval']?.toString() == 'pending';
    bool isApproved = job['approval']?.toString() == 'approved';
    bool isRejected = job['approval']?.toString() == 'rejected';
    
    String approvalNote = job['approvalNote']?.toString() ?? '';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hàng 1: Tiêu đề và trạng thái
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title']?.toString() ?? 'Không có tiêu đề',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (job['company'] != null && job['company']['name'] != null)
                        Text(
                          job['company']['name'].toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Hiển thị trạng thái duyệt
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getApprovalColor(job['approval']?.toString()).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getApprovalColor(job['approval']?.toString()).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getApprovalText(job['approval']?.toString()),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getApprovalColor(job['approval']?.toString()),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Hàng 2: Thông tin chi tiết
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                // Trạng thái hoạt động
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(job['status']?.toString()).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getStatusColor(job['status']?.toString()).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getStatusText(job['status']?.toString()),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(job['status']?.toString()),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                if (job['location'] != null && job['location'].toString().isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.location, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job['location'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (job['salary'] != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.money, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${job['salary']} triệu',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                if (job['jobType'] != null && job['jobType'].toString().isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.briefcase, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _getJobTypeText(job['jobType'].toString()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            
            // Hiển thị lý do từ chối nếu có
            if (isRejected && approvalNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Iconsax.info_circle, size: 14, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lý do: $approvalNote',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Hàng 3: Nút thao tác
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Chỉ hiển thị nút duyệt/từ chối khi đang chờ duyệt
                if (isPending) ...[
                  ElevatedButton.icon(
                    onPressed: () => _approveJob(
                      job['_id'].toString(), 
                      job['title']?.toString() ?? 'việc làm'
                    ),
                    icon: const Icon(Iconsax.tick_circle, size: 14),
                    label: const Text('Duyệt', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _rejectJob(
                      job['_id'].toString(), 
                      job['title']?.toString() ?? 'việc làm'
                    ),
                    icon: const Icon(Iconsax.close_circle, size: 14),
                    label: const Text('Từ chối', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _deleteJob(
                    job['_id'].toString(), 
                    job['title']?.toString() ?? 'việc làm'
                  ),
                  icon: const Icon(Iconsax.trash, size: 14),
                  label: const Text('Xóa', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    final statusStr = status?.toString() ?? '';
    switch (statusStr) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'draft':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    final statusStr = status?.toString() ?? '';
    switch (statusStr) {
      case 'active':
        return 'Hoạt động';
      case 'pending':
        return 'Chờ duyệt';
      case 'draft':
        return 'Nháp';
      case 'closed':
        return 'Đã đóng';
      default:
        return statusStr;
    }
  }

  Color _getApprovalColor(String? approval) {
    final approvalStr = approval?.toString() ?? 'pending';
    switch (approvalStr) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getApprovalText(String? approval) {
    final approvalStr = approval?.toString() ?? 'pending';
    switch (approvalStr) {
      case 'approved':
        return 'Đã duyệt';
      case 'pending':
        return 'Chờ duyệt';
      case 'rejected':
        return 'Từ chối';
      default:
        return approvalStr;
    }
  }

  String _getJobTypeText(String jobType) {
    switch (jobType) {
      case 'full_time':
        return 'Toàn thời gian';
      case 'part_time':
        return 'Bán thời gian';
      case 'contract':
        return 'Hợp đồng';
      case 'internship':
        return 'Thực tập';
      default:
        return jobType;
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
                      'Đang tải danh sách việc làm...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_jobs.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.briefcase,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không có việc làm nào',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadJobs(),
                child: ListView.builder(
                  itemCount: _jobs.length,
                  itemBuilder: (context, index) => _buildJobCard(_jobs[index]),
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
                'Quản lý việc làm',
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
            'Quản lý việc làm',
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