import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/company_model.dart';
import '../../../services/company_service.dart';
import '../../home_tab/company/jobByCompany.dart';
import '../../../services/auth_service.dart';

class CompanyPage extends StatefulWidget {
  const CompanyPage({Key? key}) : super(key: key);

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  final CompanyService _companyService = CompanyService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  List<CompanyModel> _companies = [];
  List<CompanyModel> _filteredCompanies = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isNavigating = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _setupSearchListener();
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        _filterCompanies();
      }
    });
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _companyService.getAllCompanies();
      
      if (result['success'] == true) {
        final List<dynamic> companiesData = result['companies'] ?? [];
        final List<CompanyModel> companies = companiesData
            .map((company) => CompanyModel.fromJson(company))
            .toList();

        setState(() {
          _companies = companies;
          _filteredCompanies = companies;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Không thể tải danh sách công ty';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isSearching = false;
      });
    }
  }

  void _filterCompanies() {
    final searchText = _searchController.text.toLowerCase().trim();
    
    setState(() {
      if (searchText.isEmpty) {
        _filteredCompanies = _companies;
      } else {
        _filteredCompanies = _companies.where((company) {
          return company.name.toLowerCase().contains(searchText) ||
                 company.description?.toLowerCase().contains(searchText) == true ||
                 company.location?.toLowerCase().contains(searchText) == true ||
                 company.taxCode?.toLowerCase().contains(searchText) == true;
        }).toList();
      }
    });
  }

  void _performSearch() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
      _filterCompanies();
    }
  }

  void _refreshCompanies() {
    _loadCompanies();
  }

  Future<void> _navigateToCompanyJobs(CompanyModel company) async {
    if (_isNavigating) return;
    
    // Kiểm tra đăng nhập trước khi vào màn hình công việc
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        _showLoginRequiredDialog();
      }
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JobByCompanyScreen(
            company: company,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi mở trang công việc: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Yêu cầu đăng nhập',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bạn cần đăng nhập để xem công việc và ứng tuyển.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Để sau',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to login screen
              // Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
            ),
            child: Text(
              'Đăng nhập',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Danh sách công ty',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCompanies,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm công ty, địa điểm, mã số thuế...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _filterCompanies();
                          },
                        ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onSubmitted: (value) => _performSearch(),
              ),
            ),
          ),

          // Error Message
          if (_errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.inter(
                        color: Colors.red[700],
                        fontSize: 14,
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
            ),

          // Company List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCompanies,
              child: _isLoading && _companies.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCompanies.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCompanies.length,
                          itemBuilder: (context, index) {
                            return _buildCompanyItem(_filteredCompanies[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearchText = _searchController.text.isNotEmpty;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearchText ? Icons.search_off : Icons.business_outlined, 
            size: 80, 
            color: Colors.grey[300]
          ),
          const SizedBox(height: 16),
          Text(
            hasSearchText ? 'Không tìm thấy công ty phù hợp' : 'Không có công ty nào',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearchText 
                ? 'Hãy thử thay đổi từ khóa tìm kiếm'
                : 'Hiện chưa có công ty nào trong hệ thống',
            style: GoogleFonts.inter(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _refreshCompanies,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyItem(CompanyModel company) {
    return GestureDetector(
      onTap: () {
        _navigateToCompanyJobs(company);
      },
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Company Logo
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        image: company.hasLogo
                            ? DecorationImage(
                                image: NetworkImage(company.logo!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: company.hasLogo
                          ? null
                          : const Icon(Icons.business, color: Colors.blue, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (company.location != null)
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  company.location!,
                                  style: GoogleFonts.inter(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onPressed: () {
                        _showCompanyDetail(company);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Company Description
                if (company.description != null && company.description!.isNotEmpty)
                  Text(
                    company.shortDescription,
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const SizedBox(height: 12),
                
                // Company Details
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (company.taxCode != null)
                      _buildCompanyDetail('Mã số thuế: ${company.taxCode}'),
                    if (company.website != null)
                      _buildCompanyDetail('Website: ${company.formattedWebsite}'),
                    if (company.hasBusinessLicense)
                      _buildCompanyDetail('Đã xác thực', isVerified: true),
                  ],
                ),
              ],
            ),
          ),
          if (_isNavigating)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompanyDetail(String text, {bool isVerified = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isVerified ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVerified)
            const Icon(Icons.verified, size: 12, color: Colors.green),
          if (isVerified) const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isVerified ? Colors.green[700] : Colors.grey[600],
              fontWeight: isVerified ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showCompanyDetail(CompanyModel company) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chi tiết công ty',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Company Header
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      image: company.hasLogo
                          ? DecorationImage(
                              image: NetworkImage(company.logo!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: company.hasLogo
                        ? null
                        : const Icon(Icons.business, color: Colors.blue, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (company.location != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                company.location!,
                                style: GoogleFonts.inter(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Company Information
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('Mô tả', company.description ?? 'Chưa có mô tả'),
                      _buildDetailItem('Website', company.formattedWebsite ?? 'Chưa có website'),
                      _buildDetailItem('Mã số thuế', company.taxCode ?? 'Chưa cung cấp'),
                      _buildDetailItem('Địa chỉ', company.location ?? 'Chưa cung cấp'),
                      if (company.hasBusinessLicense)
                        _buildDetailItem('Tình trạng', 'Đã xác thực - Có giấy phép kinh doanh'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _navigateToCompanyJobs(company);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isNavigating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Xem công việc của ${company.name}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}