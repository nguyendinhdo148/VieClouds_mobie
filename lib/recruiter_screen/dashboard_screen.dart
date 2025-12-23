// recruiter_screen/dashboard_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:viejob_app/models/job_model.dart';
import '../services/auth_service.dart';
import '../services/company_service.dart';
import '../services/job_service.dart';
import '../services/application_service.dart';
import '../core/secure_storage.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? _user;
  bool _isLoading = true;
  bool _hasCompany = false;
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();
  final CompanyService _companyService = CompanyService();
  final JobService _jobService = JobService();
  final ApplicationService _applicationService = ApplicationService();

  // Real data from API
  int _jobCount = 0;
  int _candidateCount = 0;
  List<dynamic> _recentActivities = [];

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

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    final userJson = await _secureStorage.getUserData();
    
    if (userJson != null) {
      try {
        final user = User.fromJson(jsonDecode(userJson));
        if (user.role != "recruiter") {
          if (mounted) {
            context.go('/login');
          }
        } else {
          setState(() {
            _user = user;
          });
          await _loadDashboardData();
        }
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

  Future<void> _loadDashboardData() async {
    try {
      print('🔄 Loading dashboard data from real APIs...');
      
      // Check if user has company
      final hasCompany = await _companyService.hasCompany();
      print('🏢 Has company: $hasCompany');
      setState(() {
        _hasCompany = hasCompany;
      });
      
      // Load job count
      print('📊 Loading job count...');
      final jobCountResult = await _jobService.getRecruiterJobCount();
      print('📊 Job count result: ${jobCountResult['success']}');
      print('📊 Job count value: ${jobCountResult['count']}');
      print('📊 Job count error: ${jobCountResult['error']}');
      
      if (jobCountResult['success'] == true) {
        setState(() {
          _jobCount = jobCountResult['count'] ?? 0;
        });
        print('✅ Job count loaded: $_jobCount');
      } else {
        print('⚠️ Could not load job count: ${jobCountResult['error']}');
        // Thử cách khác nếu cách trên không hoạt động
        await _loadJobCountAlternative();
      }
      
      // Load candidate count
      print('👥 Loading candidate count...');
      await _loadCandidateCount();
      
      // Load recent activities
      print('📝 Loading recent activities...');
      await _loadRecentActivities();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      print('✅ Dashboard data loaded successfully');
      print('📊 Stats - Jobs: $_jobCount, Candidates: $_candidateCount, Has Company: $_hasCompany');
      print('📊 Recent activities: ${_recentActivities.length} items');
      
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Thêm method alternative để lấy job count
  Future<void> _loadJobCountAlternative() async {
    try {
      print('🔄 Trying alternative method to load job count...');
      
      // Thử lấy danh sách công ty trước
      final companyResult = await _companyService.getRecruiterCompanies();
      if (companyResult['success'] == true && companyResult['companies'] is List) {
        final companies = companyResult['companies'] as List;
        print('🏢 Found ${companies.length} companies');
        
        if (companies.isNotEmpty) {
          // Lấy company đầu tiên
          final firstCompany = companies[0];
          final companyId = firstCompany['_id'] ?? firstCompany['id'];
          
          if (companyId != null) {
            print('🏢 Getting jobs for company: $companyId');
            final jobsResult = await _jobService.getJobsByCompany(companyId: companyId);
            
            if (jobsResult['success'] == true) {
              setState(() {
                _jobCount = jobsResult['total'] ?? 0;
              });
              print('✅ Alternative job count loaded: $_jobCount');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Alternative job count error: $e');
    }
  }

  // Thêm method để load candidate count - Đơn giản hóa
Future<void> _loadCandidateCount() async {
  try {
    // Kiểm tra đã có company chưa
    if (!_hasCompany) {
      setState(() {
        _candidateCount = 0;
      });
      return;
    }
    
    // Cách 1: Dùng getRecruiterCandidateCount từ JobService
    final candidateResult = await _jobService.getRecruiterCandidateCount();
    
    if (candidateResult['success'] == true) {
      final count = candidateResult['count'] ?? 0;
      setState(() {
        _candidateCount = count;
      });
      return;
    }
    
    // Cách 2: Nếu cách 1 không được, đếm từ danh sách job
    final jobsResult = await _jobService.getRecruiterJobs(page: 1, limit: 100);
    
    if (jobsResult['success'] == true) {
      final jobs = jobsResult['jobs'] ?? [];
      int totalCandidates = 0;
      
      // Duyệt qua từng job và lấy số ứng viên
      for (var job in jobs) {
        // Mỗi job có thể có applicants count
        if (job is JobModel) {
          // Kiểm tra xem job có thuộc tính applicationsCount không
          // Hoặc gọi API lấy ứng viên cho từng job
          try {
            final applicantsResult = await _applicationService.getApplicants(job.id);
            if (applicantsResult['success'] == true) {
              final jobData = applicantsResult['job'] ?? {};
              final applicants = jobData['applications'] ?? jobData['applicants'] ?? [];
              if (applicants is List) {
                totalCandidates += applicants.length;
              }
            }
          } catch (e) {
            // Bỏ qua job có lỗi
            continue;
          }
        }
      }
      
      setState(() {
        _candidateCount = totalCandidates;
      });
    } else {
      setState(() {
        _candidateCount = 0;
      });
    }
    
  } catch (e) {
    // Nếu tất cả đều lỗi, set về 0
    setState(() {
      _candidateCount = 0;
    });
  }
}
Future<void> _loadRecentActivities() async {
    try {
      print('📝 Attempting to load recent activities...');
      
      // Cách 1: Thử từ job service
      final activitiesResult = await _jobService.getRecentActivities();
      
      if (activitiesResult['success'] == true) {
        setState(() {
          _recentActivities = activitiesResult['activities'] ?? [];
        });
        print('✅ Recent activities loaded from job service: ${_recentActivities.length} items');
      } else {
        // Cách 2: Fallback - tạo dữ liệu mẫu hoặc lấy từ ứng viên mới nhất
        print('⚠️ No recent activities from job service, creating fallback data');
        await _loadFallbackActivities();
      }
    } catch (e) {
      print('❌ Error loading recent activities: $e');
      // Fallback
      await _loadFallbackActivities();
    }
  }

  // Thêm method fallback cho activities
  Future<void> _loadFallbackActivities() async {
    try {
      // Tạo activities từ danh sách ứng viên gần đây
      List<dynamic> fallbackActivities = [];
      
      if (_hasCompany && _jobCount > 0) {
        // Tạo activities mẫu dựa trên số liệu
        fallbackActivities = [
          {
            'title': 'Số việc làm hiện tại',
            'description': 'Bạn đang có $_jobCount việc làm đang tuyển',
            'time': 'Hiện tại',
            'icon': 'briefcase'
          },
          {
            'title': 'Số ứng viên',
            'description': 'Có $_candidateCount ứng viên đã ứng tuyển',
            'time': 'Hiện tại',
            'icon': 'people'
          }
        ];
      } else if (!_hasCompany) {
        fallbackActivities = [
          {
            'title': 'Chào mừng đến với HiringNow',
            'description': 'Hãy tạo công ty đầu tiên để bắt đầu đăng tuyển',
            'time': 'Hôm nay',
            'icon': 'building'
          },
          {
            'title': 'Chưa có công ty',
            'description': 'Bạn cần tạo công ty để sử dụng đầy đủ tính năng',
            'time': 'Hiện tại',
            'icon': 'info'
          }
        ];
      } else {
        fallbackActivities = [
          {
            'title': 'Bắt đầu hành trình',
            'description': 'Đăng công việc đầu tiên để thu hút ứng viên',
            'time': 'Hôm nay',
            'icon': 'upload'
          }
        ];
      }
      
      setState(() {
        _recentActivities = fallbackActivities;
      });
      print('✅ Fallback activities loaded: ${fallbackActivities.length} items');
    } catch (e) {
      print('❌ Error creating fallback activities: $e');
      setState(() {
        _recentActivities = [];
      });
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isLoading = true;
    });
    await _loadDashboardData();
  }

  Future<void> _handleLogout() async {
    await _authService.logout(context);
  }

  Widget _buildNoCompanyMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Icon(Iconsax.building, size: 40, color: Colors.blue.shade400),
          const SizedBox(height: 12),
          Text(
            'Bạn chưa có công ty',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cần tạo công ty để bắt đầu đăng tuyển việc làm',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/recruiter/company'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Tạo công ty ngay',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
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
            'Xin chào,',
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
          onPressed: _refreshDashboard,
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
                  _handleLogout();
                },
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
            // Profile section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
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
                            fontSize: 14,
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
                padding: const EdgeInsets.all(16),
                child: ListView.builder(
                  itemCount: _navigationItems.length,
                  itemBuilder: (context, index) {
                    final item = _navigationItems[index];
                    final currentRoute = GoRouterState.of(context).uri.toString();
                    final isActive = currentRoute == item.route;
                    
                    return ListTile(
                      leading: Icon(
                        item.icon,
                        size: 20,
                        color: isActive ? Colors.blue : Colors.grey,
                      ),
                      title: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isActive ? Colors.blue : Colors.black,
                        ),
                      ),
                      tileColor: isActive ? Colors.blue.withOpacity(0.1) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () => context.go(item.route),
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
                leading: const Icon(Iconsax.logout, size: 16, color: Colors.red),
                title: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: _handleLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với tiêu đề và thông báo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng quan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Thống kê và hoạt động mới nhất',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (!_hasCompany) 
                Icon(Iconsax.info_circle, color: Colors.orange.shade400, size: 24),
            ],
          ),
          const SizedBox(height: 20),
          
          // Thông báo nếu chưa có công ty
          if (!_hasCompany) ...[
            _buildNoCompanyMessage(),
            const SizedBox(height: 20),
          ],
          
          // Stats Grid - Hiển thị cả job và candidate
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                icon: Iconsax.briefcase,
                title: 'Việc làm',
                value: _jobCount.toString(),
                color: Colors.blue,
                isLoading: _isLoading,
                onTap: _hasCompany ? () => context.go('/recruiter/jobs') : null,
              ),
              _buildStatCard(
                icon: Iconsax.profile_2user,
                title: 'Ứng viên',
                value: _candidateCount.toString(),
                color: Colors.green,
                isLoading: _isLoading,
                onTap: _hasCompany ? () => context.go('/recruiter/candidates') : null,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Recent Activities
          if (_recentActivities.isNotEmpty) ...[
            Text(
              'Hoạt động gần đây',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildRecentActivities(),
            const SizedBox(height: 32),
          ],
          
          // Quick Actions - Chỉ hiển thị action có ý nghĩa
          Text(
            'Hành động nhanh',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Iconsax.add_square,
                  label: 'Đăng việc mới',
                  color: Colors.blue,
                  onTap: _hasCompany ? () => context.go('/recruiter/jobs') : null,
                  enabled: _hasCompany,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Iconsax.edit,
                  label: _hasCompany ? 'Quản lý công ty' : 'Tạo công ty',
                  color: Colors.green,
                  onTap: () => context.go('/recruiter/company'),
                  enabled: true,
                ),
              ),
            ],
          ),
          
          // Empty State for recent activities
          if (_recentActivities.isEmpty && !_isLoading && _hasCompany) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Iconsax.activity,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có hoạt động nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đăng tin tuyển dụng đầu tiên để bắt đầu',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/recruiter/jobs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Đăng tin ngay',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)
                  const SizedBox(
                    height: 28,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentActivities() {
    return _recentActivities.map((activity) {
      // Xác định icon dựa trên type hoặc icon field
      IconData icon;
      Color iconColor;
      
      final iconName = activity['icon']?.toString().toLowerCase() ?? '';
      switch (iconName) {
        case 'briefcase':
          icon = Iconsax.briefcase;
          iconColor = Colors.blue;
          break;
        case 'people':
          icon = Iconsax.profile_2user;
          iconColor = Colors.green;
          break;
        case 'building':
          icon = Iconsax.building;
          iconColor = Colors.orange;
          break;
        case 'upload':
          icon = Iconsax.export;
          iconColor = Colors.purple;
          break;
        case 'info':
          icon = Iconsax.info_circle;
          iconColor = Colors.blueGrey;
          break;
        default:
          icon = Iconsax.activity;
          iconColor = Colors.blue;
      }
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['title']?.toString() ?? 'Hoạt động',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity['description']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              activity['time']?.toString() ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? color.withOpacity(0.3) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: enabled ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: enabled ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                'Đang tải dữ liệu...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: _buildAppBar(),
        drawer: _buildMobileSidebar(),
        body: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: _buildDashboardContent(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          _buildDesktopSidebar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildDashboardContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Model Classes
class User {
  final String? fullname;
  final String? email;
  final String role;
  final Profile? profile;

  User({
    this.fullname,
    this.email,
    required this.role,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      fullname: json['fullname'],
      email: json['email'],
      role: json['role'],
      profile: json['profile'] != null ? Profile.fromJson(json['profile']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullname': fullname,
      'email': email,
      'role': role,
      'profile': profile?.toJson(),
    };
  }
}

class Profile {
  final ProfilePhoto? profilePhoto;

  Profile({this.profilePhoto});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      profilePhoto: json['profilePhoto'] != null 
          ? ProfilePhoto.fromJson(json['profilePhoto'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profilePhoto': profilePhoto?.toJson(),
    };
  }
}

class ProfilePhoto {
  final String url;

  ProfilePhoto({required this.url});

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(url: json['url']);
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
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