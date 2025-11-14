import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/job_service.dart';
import '../../services/company_service.dart';
import '../../models/job_model.dart';
import '../../models/company_model.dart';
import '../Home_tab/job/find_job.dart';
import '../Home_tab/company/company_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final JobService _jobService = JobService();
  final CompanyService _companyService = CompanyService();
  final TextEditingController _searchController = TextEditingController();

  List<JobModel> _recentJobs = [];
  List<CompanyModel> _featuredCompanies = [];
  bool _isLoading = true;
  bool _showSearchSuggestions = false;

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
      final result = await _jobService.getAllJobs(limit: 6);
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

  void _searchJobs() {
    if (_searchController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FindJobScreen(
            initialSearch: _searchController.text,
          ),
        ),
      );
    }
  }

  void _hideSuggestions() {
    setState(() {
      _showSearchSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hideSuggestions,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
            ? _buildLoading()
            : RefreshIndicator(
                onRefresh: _loadHomeData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header với Search
                      _buildHeaderSection(),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActions(),
                      const SizedBox(height: 24),

                      // Recent Jobs
                      if (_recentJobs.isNotEmpty) _buildRecentJobsSection(),
                      
                      // Featured Companies
                      if (_featuredCompanies.isNotEmpty) _buildFeaturedCompaniesSection(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải dữ liệu...',
            style: GoogleFonts.inter(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Text
        Text(
          'Xin chào!',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tìm công việc mơ ước của bạn',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 20),

        // Search Bar với suggestions
        Stack(
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm công việc, công ty, kỹ năng...',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onTap: () {
                        setState(() {
                          _showSearchSuggestions = true;
                        });
                      },
                      onChanged: (value) {
                        setState(() {
                          _showSearchSuggestions = value.isNotEmpty;
                        });
                      },
                      onSubmitted: (_) => _searchJobs(),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search, color: Colors.white, size: 20),
                      onPressed: _searchJobs,
                    ),
                  ),
                ],
              ),
            ),

            // Search Suggestions
            if (_showSearchSuggestions && _searchController.text.isNotEmpty)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: _buildSearchSuggestions(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchSuggestions() {
    // Tạm thời hiển thị các gợi ý cơ bản
    final suggestions = [
      'Lập trình viên',
      'Kế toán',
      'Nhân sự',
      'Marketing',
      'Designer',
      'Quản lý dự án'
    ];

    final filteredSuggestions = suggestions
        .where((suggestion) => suggestion
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Gợi ý tìm kiếm',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          ...filteredSuggestions.map((suggestion) => ListTile(
                title: Text(suggestion),
                leading: Icon(Icons.search, size: 20, color: Colors.grey),
                onTap: () {
                  _searchController.text = suggestion;
                  _searchJobs();
                },
              )),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tính năng nhanh',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickActionItem(
              'Tìm việc',
              Icons.work_outline,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FindJobScreen(initialSearch: '')),
              ),
            ),
            _buildQuickActionItem(
              'Công ty',
              Icons.business,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CompanyPage()),
              ),
            ),
            _buildQuickActionItem(
              'CV của tôi',
              Icons.description,
              Colors.green,
              () {
                // TODO: Navigate to CV screen
              },
            ),
            _buildQuickActionItem(
              'Ứng tuyển',
              Icons.send,
              Colors.orange,
              () {
                // TODO: Navigate to applications screen
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentJobsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Công việc mới nhất',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FindJobScreen(initialSearch: '')),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: Text(
                'Xem tất cả',
                style: GoogleFonts.inter(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentJobs.length,
            itemBuilder: (context, index) {
              final job = _recentJobs[index];
              return _buildJobCard(job);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJobCard(JobModel job) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company info và logo
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  image: job.companyLogo != null
                      ? DecorationImage(
                          image: NetworkImage(job.companyLogo!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: job.companyLogo == null
                    ? Icon(Icons.business, color: Colors.blue[300], size: 18)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      job.companyName,
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Job details
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.location,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.attach_money, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.formattedSalary,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Footer với time và status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.timeAgo,
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: job.isActive ? Colors.green[50] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job.isActive ? 'Đang tuyển' : 'Đã đóng',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: job.isActive ? Colors.green[700] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCompaniesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Công ty nổi bật',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CompanyPage()),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: Text(
                'Xem tất cả',
                style: GoogleFonts.inter(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: _featuredCompanies.length,
          itemBuilder: (context, index) {
            final company = _featuredCompanies[index];
            return _buildCompanyCard(company);
          },
        ),
      ],
    );
  }

  Widget _buildCompanyCard(CompanyModel company) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to company detail
        print('Tapped company: ${company.name}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                image: company.hasLogo
                    ? DecorationImage(
                        image: NetworkImage(company.logo!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: company.hasLogo
                  ? null
                  : Icon(Icons.business, color: Colors.blue[300], size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              company.name,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (company.location != null) ...[
              const SizedBox(height: 4),
              Text(
                company.location!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}