import 'package:flutter/material.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/home_header.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/quick_actions.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/recent_jobs_section.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/companies_section.dart';
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
  List<CompanyModel> _featuredCompanies = [];
  List<CompanyModel> _popularCompanies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadRecentJobs(),
        _loadFeaturedCompanies(),
        _loadPopularCompanies(),
      ]);
    } catch (e) {
      print('Error loading home data: $e');
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

  Future<void> _loadFeaturedCompanies() async {
    try {
      final result = await _companyService.getAllCompanies();
      if (result['success'] == true) {
        final companies = result['companies'] ?? [];
        setState(() {
          _featuredCompanies = companies.take(4).toList();
        });
      }
    } catch (e) {
      print('Error loading featured companies: $e');
    }
  }

  Future<void> _loadPopularCompanies() async {
    try {
      final result = await _companyService.getAllCompanies();
      if (result['success'] == true) {
        final companies = result['companies'] ?? [];
        setState(() {
          _popularCompanies = companies.skip(4).take(6).toList();
        });
      }
    } catch (e) {
      print('Error loading popular companies: $e');
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

  @override
  Widget build(BuildContext context) {
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

                    // Recent Jobs
                    if (_recentJobs.isNotEmpty)
                      RecentJobsSection(jobs: _recentJobs),
                    const SizedBox(height: 24),

                    // Featured Companies
                    if (_featuredCompanies.isNotEmpty)
                      CompaniesSection(
                        title: 'Công ty nổi bật',
                        companies: _featuredCompanies,
                        isFeatured: true,
                      ),
                    const SizedBox(height: 24),

                    // Popular Companies
                    if (_popularCompanies.isNotEmpty)
                      CompaniesSection(
                        title: 'Công ty phổ biến',
                        companies: _popularCompanies,
                        isHorizontal: true,
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