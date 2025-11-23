import 'package:flutter/material.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/home_header.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/quick_actions.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/recent_jobs_section.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/companies_section.dart'; // Đảm bảo import đúng
import '../../services/job_service.dart';
import '../../services/company_service.dart';
import '../../models/job_model.dart';
import '../../models/company_model.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final JobService _jobService = JobService();
  final CompanyService _companyService = CompanyService();

  List<JobModel> _recentJobs = [];
  List<CompanyModel> _companies = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await Future.wait([
        _loadRecentJobs(),
        _loadCompanies(),
      ]);
    } catch (e) {
      print('Error loading home data: $e');
      setState(() {
        _errorMessage = 'Lỗi tải dữ liệu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentJobs() async {
    try {
      final result = await _jobService.getAllJobs(limit: 8);
      if (result['success'] == true) {
        setState(() {
          _recentJobs = result['jobs'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading recent jobs: $e');
    }
  }

  Future<void> _loadCompanies() async {
    try {
      print('🔄 [HomeTab] Loading companies...');
      final result = await _companyService.getAllCompanies();
      
      if (result['success'] == true) {
        final List<dynamic> companiesData = result['companies'] ?? [];
        final List<CompanyModel> companies = companiesData
            .map((company) => CompanyModel.fromJson(company))
            .toList();

        setState(() {
          _companies = companies;
        });
        
        print('✅ [HomeTab] Loaded ${_companies.length} companies');
        for (var company in _companies) {
          print('   - ${company.name}');
        }
      } else {
        print('❌ [HomeTab] Failed to load companies: ${result['error']}');
        setState(() {
          _errorMessage = result['error'] ?? 'Không thể tải danh sách công ty';
        });
      }
    } catch (e) {
      print('❌ [HomeTab] Error loading companies: $e');
      setState(() {
        _errorMessage = 'Lỗi tải công ty: $e';
      });
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_PastelColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải dữ liệu...',
            style: _TextStyles.bodyMedium.copyWith(color: _PastelColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (_errorMessage.isEmpty) return const SizedBox();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: _TextStyles.bodyMedium.copyWith(
                color: Colors.red[700],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              setState(() {
                _errorMessage = '';
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🏠 [HomeTab] Building...');
    print('   - Recent jobs: ${_recentJobs.length}');
    print('   - Companies: ${_companies.length}');
    print('   - isLoading: $_isLoading');

    return Scaffold(
      backgroundColor: _PastelColors.background,
      body: _isLoading
          ? _buildLoading()
          : RefreshIndicator(
              onRefresh: _loadHomeData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header với Logo
                    HomeHeader(
                      onSearch: (query) {
                        // Xử lý tìm kiếm
                      },
                    ),
                    const SizedBox(height: 28),

                    // Quick Actions
                    const QuickActionsSection(),
                    const SizedBox(height: 28),

                    // Error Message
                    _buildErrorWidget(),

                    // Recent Jobs - GIỮ NGUYÊN
                    if (_recentJobs.isNotEmpty) ...[
                      RecentJobsSection(jobs: _recentJobs),
                      const SizedBox(height: 32),
                    ],

                    // Companies Section - CHỈ HIỆN MỘT SECTION DUY NHẤT
                    if (_companies.isNotEmpty)
                      CompaniesSection(
                        title: 'Công ty hàng đầu',
                        companies: _companies,
                        isFeatured: false,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PastelColors {
  static const Color primary = Color(0xFFA8D8EA);
  static const Color secondary = Color(0xFFAA96DA);
  static const Color accent = Color(0xFFFCBAD3);
  static const Color yellow = Color(0xFFFFFDD2);
  static const Color background = Color(0xFFF8F9FA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color dark = Color(0xFF2D3748);
  static const Color grey = Color(0xFF718096);
  static const Color lightGrey = Color(0xFFA0AEC0);
}

class _TextStyles {
  static final TextStyle displayLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: _PastelColors.dark,
  );

  static final TextStyle displayMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: _PastelColors.dark,
  );

  static final TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: _PastelColors.dark,
  );

  static final TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: _PastelColors.dark,
  );

  static final TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: _PastelColors.grey,
  );

  static final TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: _PastelColors.grey,
  );

  static final TextStyle caption = TextStyle(
    fontSize: 11,
    color: _PastelColors.lightGrey,
  );
}