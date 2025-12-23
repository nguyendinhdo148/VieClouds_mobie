// screens/recruiter_screen/candidates_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:viejob_app/recruiter_screen/jobs_screen.dart';
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../services/application_service.dart';
import '../../core/secure_storage.dart';
import '../../models/application_model.dart';
import '../recruiter_screen/applicant_profile_screen.dart';

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({Key? key}) : super(key: key);

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  final ApplicationService _applicationService = ApplicationService();
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();
  
  List<ApplicationModel> _applications = [];
  List<ApplicationModel> _filteredApplications = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _selectedStatus = 'all';
  
  // Sidebar variables
  User? _user;
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      name: "Dashboard",
      route: "/recruiter",
      icon: Iconsax.home_2,
    ),
    NavigationItem(
      name: "Quản lý công ty",
      route: "/recruiter/company",
      icon: Iconsax.building_4,
    ),
    NavigationItem(
      name: "Quản lý việc làm",
      route: "/recruiter/jobs",
      icon: Iconsax.briefcase,
    ),
    NavigationItem(
      name: "Quản lý ứng viên",
      route: "/recruiter/candidates",
      icon: Iconsax.people,
    ),
  ];

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  void _checkAuthAndLoadData() async {
    final userJson = await _secureStorage.getUserData();
    
    if (userJson != null) {
      try {
        final userData = jsonDecode(userJson);
        if (userData['role'] != "recruiter") {
          if (mounted) {
            context.go('/login');
          }
          return;
        }
        setState(() {
          _user = User.fromJson(userData);
        });
        await _loadApplications();
      } catch (e) {
        print('Error parsing user data: $e');
        if (mounted) {
          context.go('/login');
        }
      }
    } else {
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _loadApplications() async {
    try {
      print('🔄 Loading applications...');
      setState(() {
        _isLoading = true;
      });
      
      final result = await _applicationService.getRecruiterCandidatesWithDebug();
      
      if (result['success'] == true) {
        final List<dynamic> applicationsData = result['applications'] ?? result['candidates'] ?? [];
        
        final applications = applicationsData
            .map<ApplicationModel>((json) => ApplicationModel.fromJson(json))
            .toList();
        
        print('✅ Loaded ${applications.length} applications');
        print('🔍 First application debug:');
        if (applications.isNotEmpty) {
          applications.first.printDebugInfo();
        }
        
        setState(() {
          _applications = applications;
          _filterApplications();
        });
      } else {
        print('⚠️ Failed to load applications: ${result['error']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể tải danh sách ứng viên: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading applications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách ứng viên: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterApplications() {
    List<ApplicationModel> filtered = _applications;
    
    // Filter by search term
    if (_searchTerm.isNotEmpty) {
      filtered = filtered.where((app) {
        final fullName = app.applicantName.toLowerCase();
        final email = app.applicant?.email?.toLowerCase() ?? '';
        final jobTitle = app.jobTitle.toLowerCase();
        final term = _searchTerm.toLowerCase();
        
        return fullName.contains(term) ||
               email.contains(term) ||
               jobTitle.contains(term);
      }).toList();
    }
    
    // Filter by status
    if (_selectedStatus != 'all') {
      filtered = filtered.where((app) => app.status == _selectedStatus).toList();
    }
    
    setState(() {
      _filteredApplications = filtered;
      _totalPages = (_filteredApplications.length / _itemsPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;
      if (_currentPage > _totalPages) _currentPage = 1;
    });
  }

  List<ApplicationModel> _getPaginatedApplications() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredApplications.sublist(
      startIndex.clamp(0, _filteredApplications.length),
      endIndex.clamp(0, _filteredApplications.length),
    );
  }

  Future<void> _handleAcceptAndReject(String applicationId, String status) async {
    final action = status == 'accepted' ? 'Chấp nhận' : 'Từ chối';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận $action'),
        content: Text('Bạn có chắc muốn $action ứng viên này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
            ),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _applicationService.updateApplicationStatus(
        applicationId,
        status,
      );
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${action} ứng viên thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadApplications();
      } else {
        throw Exception(result['message'] ?? 'Thao tác thất bại');
      }
    } catch (e) {
      print('❌ Error updating application status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _getStatusBadge(String status) {
    switch (status) {
      case 'pending':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.yellow.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Đang xem xét',
            style: TextStyle(
              fontSize: 12,
              color: Colors.yellow.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case 'accepted':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Đã chấp nhận',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case 'rejected':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Đã từ chối',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quản lý ứng viên',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
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
          onPressed: _loadApplications,
        ),
      ],
    );
  }

  Widget _buildMobileSidebar() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Profile section
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
                    backgroundImage: _user?.profile?.profilePhoto?.url != null
                        ? NetworkImage(_user!.profile!.profilePhoto!.url)
                        : null,
                    child: _user?.profile?.profilePhoto?.url == null
                        ? Text(
                            _user?.fullname?.isNotEmpty == true
                                ? _user!.fullname![0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                    backgroundColor: Colors.blue.shade100,
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
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _user?.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
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
                padding: const EdgeInsets.all(12),
                child: ListView.builder(
                  itemCount: _navigationItems.length,
                  itemBuilder: (context, index) {
                    final item = _navigationItems[index];
                    final currentRoute = GoRouterState.of(context).uri.toString();
                    final isActive = currentRoute == item.route;
                    
                    return ListTile(
                      leading: Icon(
                        item.icon,
                        color: isActive ? Colors.blue : Colors.grey,
                      ),
                      title: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isActive ? Colors.blue : Colors.black,
                        ),
                      ),
                      tileColor: isActive ? Colors.blue.withOpacity(0.1) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.go(item.route);
                      },
                    );
                  },
                ),
              ),
            ),

            // Logout button
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

  Widget _buildFiltersCard() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.search_normal, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm ứng viên...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchTerm = value;
                    });
                    _filterApplications();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Status filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatusFilterChip('all', 'Tất cả', _applications.length),
              const SizedBox(width: 8),
              _buildStatusFilterChip(
                'pending',
                'Đang xem xét',
                _applications.where((app) => app.status == 'pending').length,
              ),
              const SizedBox(width: 8),
              _buildStatusFilterChip(
                'accepted',
                'Đã chấp nhận',
                _applications.where((app) => app.status == 'accepted').length,
              ),
              const SizedBox(width: 8),
              _buildStatusFilterChip(
                'rejected',
                'Đã từ chối',
                _applications.where((app) => app.status == 'rejected').length,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildStatusFilterChip(String status, String label, int count) {
    final isSelected = _selectedStatus == status;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
        _filterApplications();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _getStatusColor(status).withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? _getStatusColor(status) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? _getStatusColor(status) : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.blue;
    }
  }

  Widget _buildCandidateCard(ApplicationModel application) {
    final applicant = application.applicant;
    final job = application.job;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Applicant info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: applicant?.profile?.profilePhoto?.url != null
                      ? NetworkImage(applicant!.profile!.profilePhoto!.url)
                      : null,
                  child: applicant?.profile?.profilePhoto?.url == null
                      ? Text(
                          application.applicantName.isNotEmpty
                              ? application.applicantName[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                  backgroundColor: Colors.blue.shade100,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.applicantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        application.applicantEmail ?? 'Chưa có email',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _getStatusBadge(application.status),
              ],
            ),
            const SizedBox(height: 12),
            
            // Job info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vị trí ứng tuyển:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  application.jobTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Công ty: ${application.companyName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Contact and date
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SĐT: ${application.applicant?.phoneNumber ?? 'Chưa cập nhật'}',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ngày ứng tuyển: ${DateFormat('dd/MM/yyyy').format(application.createdAt)}',
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
            const SizedBox(height: 12),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to applicant profile
                      if (application.applicantId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ApplicantProfileScreen(
                              userId: application.applicantId,
                              isRecruiterView: true,
                              applicantData: application.applicantData, // ✅ QUAN TRỌNG
                            ),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Xem hồ sơ'),
                  ),
                ),
                const SizedBox(width: 8),
                if (application.status == 'pending')
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleAcceptAndReject(application.id, 'accepted'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Chấp nhận'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleAcceptAndReject(application.id, 'rejected'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Từ chối'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.people,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có ứng viên nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hiện tại chưa có ứng viên nào ứng tuyển',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

Widget _buildContent() {
  if (_isLoading) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            'Đang tải danh sách ứng viên...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  final paginatedApplications = _getPaginatedApplications();

  return Column(
    children: [
      // 🔍 Filters + search
      _buildFiltersCard(),

      // Candidate count
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tổng số ứng viên: ${_filteredApplications.length}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 8),

      // Candidate list
      Expanded(
        child: _filteredApplications.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _loadApplications,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: paginatedApplications.length,
                  itemBuilder: (context, index) {
                    return _buildCandidateCard(
                      paginatedApplications[index],
                    );
                  },
                ),
              ),
      ),

      // Pagination
      if (_filteredApplications.length > _itemsPerPage)
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Iconsax.arrow_left_2),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                    : null,
                color: _currentPage > 1 ? Colors.blue : Colors.grey,
              ),
              Text(
                'Trang $_currentPage/$_totalPages',
                style: const TextStyle(fontSize: 14),
              ),
              IconButton(
                icon: const Icon(Iconsax.arrow_right_3),
                onPressed: _currentPage < _totalPages
                    ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                    : null,
                color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
              ),
            ],
          ),
        ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      drawer: _buildMobileSidebar(),
      body: _buildContent(),
    );
  }
}

extension on String? {
  get url => null;
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