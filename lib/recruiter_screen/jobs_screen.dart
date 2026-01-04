// recruiter_screen/jobs_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/job_service.dart';
import '../core/secure_storage.dart';
import '../models/job_model.dart';
import 'job_form_dialog.dart';
import 'job_edit_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({Key? key}) : super(key: key);

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  // ========== Services ==========
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();

  // ========== State Variables ==========
  List<JobModel> _jobs = [];
  bool _isLoading = true;
  JobModel? _selectedDetailJob;
  bool _isDetailOpen = false;

  // ========== Pagination ==========
  int _currentPage = 1;
  final int _jobsPerPage = 6;
  int _totalJobs = 0;
  int _totalPages = 1;

  // ========== User & Navigation ==========
  User? _user;
  final List<NavigationItem> _navigationItems = [
    NavigationItem(name: "Dashboard", route: "/recruiter", icon: Iconsax.home_2),
    NavigationItem(name: "Quản lý công ty", route: "/recruiter/company", icon: Iconsax.building_4),
    NavigationItem(name: "Quản lý việc làm", route: "/recruiter/jobs", icon: Iconsax.briefcase),
    NavigationItem(name: "Quản lý ứng viên", route: "/recruiter/candidates", icon: Iconsax.people),
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    await _checkAuthAndLoadData();
  }

  // ========== API Methods ==========
  Future<void> _checkAuthAndLoadData() async {
    final userJson = await _secureStorage.getUserData();
    
    if (userJson == null) {
      _redirectToLogin();
      return;
    }

    try {
      final userData = jsonDecode(userJson);
      if (userData['role'] != "recruiter") {
        _redirectToLogin();
        return;
      }
      
      setState(() {
        _user = User.fromJson(userData);
      });
      
      await _loadJobs();
    } catch (e) {
      print('Error initializing: $e');
      _redirectToLogin();
    }
  }

  Future<void> _loadJobs() async {
    try {
      setState(() => _isLoading = true);
      
      final result = await _jobService.getRecruiterJobs(
        page: _currentPage,
        limit: _jobsPerPage,
      );
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        final List<dynamic> jobsJson = result['jobs'] ?? [];
        setState(() {
          _jobs = jobsJson.cast<JobModel>();
          _totalJobs = result['total'] ?? 0;
          _totalPages = result['totalPages'] ?? 1;
        });
      } else {
        _showErrorSnackbar('Không thể tải danh sách việc làm: ${result['error']}');
      }
    } catch (e) {
      _showErrorSnackbar('Lỗi tải danh sách việc làm: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteJob(String jobId) async {
    final confirmed = await _showConfirmDialog(
      title: 'Xác nhận xóa',
      message: 'Bạn có chắc muốn xóa tin tuyển dụng này?\nHành động này không thể hoàn tác!',
      confirmText: 'Xóa',
    );

    if (confirmed != true) return;

    try {
      final result = await _jobService.deleteJob(jobId);
      
      if (result['success'] == true) {
        _showSuccessSnackbar('Xóa tin tuyển dụng thành công!');
        await _loadJobs();
      } else {
        throw Exception(result['error'] ?? 'Xóa thất bại');
      }
    } catch (e) {
      _showErrorSnackbar('Lỗi: $e');
    }
  }

  // ========== UI Helper Methods ==========
  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _redirectToLogin() {
    if (mounted) context.go('/login');
  }

  // ========== Form Methods ==========
  Future<void> _handleAddJob() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => JobFormDialog(
        onSuccess: _loadJobs,
      ),
    );
  }
Future<void> _handleEditJob(JobModel job) async {
  // Sử dụng Builder để có context đúng
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => JobEditScreen(
        job: job,
        onSuccess: () {
          _loadJobs(); // Gọi lại khi thành công
        },
      ),
    ),
  );
}

  void _showJobDetail(JobModel job) {
    setState(() {
      _selectedDetailJob = job;
      _isDetailOpen = true;
    });
  }

  // ========== UI Components ==========
  Widget _buildStatusBadge(String status) {
    final Map<String, Map<String, dynamic>> badgeConfig = {
      'active': {
        'textColor': Colors.green.shade700,
        'text': 'Hoạt động',
        'backgroundColor': Colors.green.shade100,
        'borderColor': Colors.green.shade300,
      },
      'draft': {
        'textColor': Colors.orange.shade700,
        'text': 'Nháp',
        'backgroundColor': Colors.orange.shade100,
        'borderColor': Colors.orange.shade300,
      },
      'closed': {
        'textColor': Colors.red.shade700,
        'text': 'Đã đóng',
        'backgroundColor': Colors.red.shade100,
        'borderColor': Colors.red.shade300,
      },
    };

    final config = badgeConfig[status];
    if (config == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: config['backgroundColor'] as Color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config['borderColor'] as Color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 12,
            color: config['textColor'] as Color,
          ),
          const SizedBox(width: 4),
          Text(
            config['text'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: config['textColor'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active': return Iconsax.tick_circle;
      case 'draft': return Iconsax.document;
      case 'closed': return Iconsax.close_circle;
      default: return Iconsax.info_circle;
    }
  }

  Widget _buildApprovalBadge(String approval, String? approvalNote) {
    final Map<String, Map<String, dynamic>> badgeConfig = {
      'approved': {
        'textColor': Colors.green.shade700,
        'text': 'Đã duyệt',
        'backgroundColor': Colors.green.shade100,
        'borderColor': Colors.green.shade300,
      },
      'pending': {
        'textColor': Colors.orange.shade700,
        'text': 'Chờ duyệt',
        'backgroundColor': Colors.orange.shade100,
        'borderColor': Colors.orange.shade300,
      },
      'rejected': {
        'textColor': Colors.red.shade700,
        'text': 'Từ chối',
        'backgroundColor': Colors.red.shade100,
        'borderColor': Colors.red.shade300,
      },
    };

    final config = badgeConfig[approval];
    if (config == null) return const SizedBox();

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: config['backgroundColor'] as Color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config['borderColor'] as Color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getApprovalIcon(approval),
            size: 12,
            color: config['textColor'] as Color,
          ),
          const SizedBox(width: 4),
          Text(
            config['text'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: config['textColor'] as Color,
            ),
          ),
        ],
      ),
    );

    if (approval == 'rejected' && approvalNote != null) {
      return Tooltip(
        message: approvalNote,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        child: badge,
      );
    }

    return badge;
  }

  IconData _getApprovalIcon(String approval) {
    switch (approval) {
      case 'approved': return Iconsax.tick_circle;
      case 'pending': return Iconsax.clock;
      case 'rejected': return Iconsax.close_circle;
      default: return Iconsax.info_circle;
    }
  }

  Widget _buildJobCard(JobModel job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    _buildStatusBadge(job.status),
                    const SizedBox(width: 8),
                    _buildApprovalBadge(job.approval, job.approvalNote),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Details
            _buildJobDetailRow(
              icon: Iconsax.location,
              text: job.location,
            ),
            const SizedBox(height: 4),
            
            Row(
              children: [
                Icon(Iconsax.money, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${NumberFormat.decimalPattern().format(job.salary)} triệu',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Iconsax.clock, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${job.experienceLevel} năm',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    '${job.applications.length} ỨV',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  children: [
                    _buildActionButton(
                      icon: Iconsax.eye,
                      color: Colors.grey,
                      onTap: () => _showJobDetail(job),
                    ),
                    _buildActionButton(
                      icon: Iconsax.edit,
                      color: Colors.blue,
                      onTap: () => _handleEditJob(job),
                    ),
                    _buildActionButton(
                      icon: Iconsax.trash,
                      color: Colors.red,
                      onTap: () => _deleteJob(job.id),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetailRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: color,
      onPressed: onTap,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.briefcase, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Chưa có tin tuyển dụng nào',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy bắt đầu bằng cách đăng tin mới',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _handleAddJob,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.add, size: 16),
                SizedBox(width: 8),
                Text('Đăng tin tuyển dụng'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobList() {
    if (_jobs.isEmpty) return _buildEmptyState();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _jobs.length,
      itemBuilder: (context, index) => _buildJobCard(_jobs[index]),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
        ),
        Text(
          'Trang $_currentPage/$_totalPages',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        IconButton(
          icon: const Icon(Iconsax.arrow_right_3),
          onPressed: _currentPage < _totalPages ? () => _changePage(_currentPage + 1) : null,
        ),
      ],
    );
  }

  void _changePage(int newPage) {
    setState(() => _currentPage = newPage);
    _loadJobs();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Đang tải danh sách việc làm...',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ========== Layout Components ==========
PreferredSizeWidget _buildAppBar() {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,

    leading: Builder(
      builder: (context) => IconButton(
        icon: const Icon(Iconsax.menu_1, color: Colors.black),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    ),

    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quản lý việc làm',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          _user?.fullname?.split(' ').last ?? 'Nhà tuyển dụng',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    ),

    actions: [
      IconButton(
        icon: const Icon(Iconsax.refresh, color: Colors.blue),
        onPressed: _loadJobs,
      ),
    ],
  );
}

Widget _buildMobileSidebar() {
  return Drawer(
    child: SafeArea(
      child: Column(
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: _user?.profile?.profilePhoto?.url != null
                      ? NetworkImage(_user!.profile!.profilePhoto!.url)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?.fullname ?? 'Người dùng',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _user?.email ?? '',
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

          // Navigation
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ListView.builder(
                itemCount: _navigationItems.length,
                itemBuilder: (context, index) =>
                    _buildNavigationItem(_navigationItems[index]),
              ),
            ),
          ),

          // Logout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
              onTap: () {
                Navigator.pop(context);
                _authService.logout(context);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildNavigationItem(NavigationItem item) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isActive = currentRoute == item.route;

    return ListTile(
      leading: Icon(item.icon, color: isActive ? Colors.blue : Colors.grey),
      title: Text(
        item.name,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.blue : Colors.black,
        ),
      ),
      tileColor: isActive ? Colors.blue.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context);
        context.go(item.route);
      },
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.indigo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Iconsax.clipboard_text, color: Colors.white, size: 32),
              ),
              ElevatedButton(
                onPressed: _handleAddJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Row(
                  children: [
                    Icon(Iconsax.add, size: 18),
                    SizedBox(width: 8),
                    Text('Đăng tin tuyển dụng'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Job List
          Expanded(
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildJobList(),
              ),
            ),
          ),
          
          // Pagination
          const SizedBox(height: 16),
          _buildPagination(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScreen();

    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: _buildAppBar(),
        drawer: _buildMobileSidebar(),
        body: Stack(
          children: [
            _buildContent(),
            if (_isDetailOpen) _buildDetailOverlay(),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          // Desktop Sidebar (đơn giản hóa cho mobile)
          Container(
            width: 256,
            color: Colors.white,
            child: SafeArea(
              child: Column(
                children: [
                  // Profile
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage: _user?.profile?.profilePhoto?.url != null
                              ? NetworkImage(_user!.profile!.profilePhoto!.url)
                              : null,
                          child: _user?.profile?.profilePhoto?.url == null
                              ? Text(
                                  _user?.fullname?.isNotEmpty == true
                                      ? _user!.fullname![0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _user?.fullname ?? 'Người dùng',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _user?.email ?? '',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Navigation
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView.builder(
                        itemCount: _navigationItems.length,
                        itemBuilder: (context, index) => _buildDesktopNavigationItem(_navigationItems[index]),
                      ),
                    ),
                  ),
                  
                  // Logout
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: ListTile(
                      leading: const Icon(Iconsax.logout, size: 16, color: Colors.red),
                      title: const Text(
                        'Đăng xuất',
                        style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                      onTap: () => _authService.logout(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Main Content
          Expanded(
            child: Stack(
              children: [
                _buildContent(),
                if (_isDetailOpen) _buildDetailOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNavigationItem(NavigationItem item) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isActive = currentRoute == item.route;

    return ListTile(
      leading: Icon(item.icon, size: 20, color: isActive ? Colors.blue : Colors.grey),
      title: Text(
        item.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.blue : Colors.black,
        ),
      ),
      tileColor: isActive ? Colors.blue.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => context.go(item.route),
    );
  }

  Widget _buildDetailOverlay() {
    return Stack(
      children: [
        ModalBarrier(
          color: Colors.black.withOpacity(0.5),
          dismissible: true,
          onDismiss: () => setState(() {
            _isDetailOpen = false;
            _selectedDetailJob = null;
          }),
        ),
        Center(child: _buildJobDetailDialog()),
      ],
    );
  }

  Widget _buildJobDetailDialog() {
    if (_selectedDetailJob == null) return const SizedBox();

    final job = _selectedDetailJob!;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Iconsax.eye, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chi tiết tin tuyển dụng',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(job.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              
              // Badges
              Row(children: [
                _buildStatusBadge(job.status),
                const SizedBox(width: 8),
                _buildApprovalBadge(job.approval, job.approvalNote),
              ]),
              const SizedBox(height: 16),
              
              // Details
              _buildDetailRow('🏢 Công ty', job.companyId),
              _buildDetailRow('📍 Địa điểm', job.location),
              _buildDetailRow('💰 Mức lương', '${NumberFormat.decimalPattern().format(job.salary)} triệu VNĐ'),
              _buildDetailRow('📊 Kinh nghiệm', '${job.experienceLevel} năm'),
              _buildDetailRow('📝 Số ứng viên', '${job.applications.length}'),
              
              if (job.description != null) ...[
                const SizedBox(height: 16),
                const Text('Mô tả công việc', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                Text(job.description!),
              ],
              
              if (job.requirements.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Yêu cầu công việc', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                ...job.requirements.map((req) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(req)),
                    ],
                  ),
                )),
              ],
              
              if (job.benefits.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Quyền lợi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                ...job.benefits.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(benefit)),
                    ],
                  ),
                )),
              ],
              
              if (job.approvalNote != null && job.approvalNote!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ghi chú từ quản trị viên',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
                      ),
                      const SizedBox(height: 4),
                      Text(job.approvalNote!),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _isDetailOpen = false;
            _selectedDetailJob = null;
          }),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// ========== Models ==========
class User {
  final String? fullname;
  final String? email;
  final String role;
  final Profile? profile;

  User({this.fullname, this.email, required this.role, this.profile});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      fullname: json['fullname'],
      email: json['email'],
      role: json['role'],
      profile: json['profile'] != null ? Profile.fromJson(json['profile']) : null,
    );
  }
}

class Profile {
  final ProfilePhoto? profilePhoto;

  Profile({this.profilePhoto});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      profilePhoto: json['profilePhoto'] != null ? ProfilePhoto.fromJson(json['profilePhoto']) : null,
    );
  }
}

class ProfilePhoto {
  final String url;

  ProfilePhoto({required this.url});

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(url: json['url']);
  }
}

class NavigationItem {
  final String name;
  final String route;
  final IconData icon;

  NavigationItem({
    required this.name,
    required this.route,
    required this.icon,
  });
}