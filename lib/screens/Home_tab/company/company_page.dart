import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html_unescape/html_unescape.dart';
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
  final HtmlUnescape _htmlUnescape = HtmlUnescape();
  
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

  // Hàm giải mã HTML
  String _decodeHtml(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) return '';
    return _htmlUnescape.convert(htmlString);
  }

  // Rút gọn mô tả với giải mã HTML
  String _getShortDescription(String? description) {
    if (description == null) return '';
    final decoded = _decodeHtml(description);
    const maxLength = 120;
    if (decoded.length <= maxLength) return decoded;
    return '${decoded.substring(0, maxLength)}...';
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
          final name = company.name.toLowerCase();
          final description = _decodeHtml(company.description ?? '').toLowerCase();
          final location = company.location?.toLowerCase() ?? '';
          final taxCode = company.taxCode?.toLowerCase() ?? '';
          
          return name.contains(searchText) ||
                 description.contains(searchText) ||
                 location.contains(searchText) ||
                 taxCode.contains(searchText);
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
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Error Message
          if (_errorMessage.isNotEmpty) _buildErrorWidget(),
          
          // Company List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCompanies,
              color: Colors.blue,
              backgroundColor: Colors.white,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm công ty, địa điểm, mã số thuế...',
            hintStyle: GoogleFonts.inter(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500]),
            suffixIcon: _buildSearchSuffixIcon(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          style: GoogleFonts.inter(fontSize: 14),
          onSubmitted: (value) => _performSearch(),
        ),
      ),
    );
  }

  Widget? _buildSearchSuffixIcon() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue[400],
              ),
            ),
          ),
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: Icon(Icons.clear_rounded, size: 18, color: Colors.grey[500]),
            onPressed: () {
              _searchController.clear();
              _filterCompanies();
            },
          ),
        // Nút reload đã được đẩy lên đây
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _refreshCompanies,
          tooltip: 'Làm mới',
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: GoogleFonts.inter(
                color: Colors.red[700],
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: Colors.red[400]),
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

  Widget _buildContent() {
    if (_isLoading && _companies.isEmpty) {
      return _buildLoadingIndicator();
    } else if (_filteredCompanies.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildCompanyList();
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.blue[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải danh sách công ty...',
            style: GoogleFonts.inter(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearchText = _searchController.text.isNotEmpty;
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearchText ? Icons.search_off_rounded : Icons.business_center_rounded, 
              size: 80, 
              color: Colors.grey[300]
            ),
            const SizedBox(height: 20),
            Text(
              hasSearchText ? 'Không tìm thấy công ty' : 'Chưa có công ty nào',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearchText 
                  ? 'Hãy thử thay đổi từ khóa tìm kiếm của bạn'
                  : 'Hiện chưa có công ty nào trong hệ thống',
              style: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (hasSearchText)
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  _filterCompanies();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Xóa tìm kiếm',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              ElevatedButton(
                onPressed: _refreshCompanies,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Thử lại',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _filteredCompanies.length,
      itemBuilder: (context, index) {
        return _buildCompanyItem(_filteredCompanies[index]);
      },
    );
  }

  Widget _buildCompanyItem(CompanyModel company) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _navigateToCompanyJobs(company),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with logo and basic info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company Logo
                        Container(
                          width: 50,
                          height: 50,
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
                              : Icon(Icons.business_rounded, 
                                  color: Colors.blue[300], size: 24),
                        ),
                        const SizedBox(width: 12),
                        
                        // Company Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.name,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (company.location != null)
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded, 
                                        size: 12, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        company.location!,
                                        style: GoogleFonts.inter(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        
                        // Verified badge
                        if (company.hasBusinessLicense)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[100]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, 
                                    size: 12, color: Colors.green[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Đã xác thực',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Company Description
                    if (company.description != null && company.description!.isNotEmpty)
                      Text(
                        _getShortDescription(company.description),
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Company Details
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (company.taxCode != null)
                          _buildDetailChip('MST: ${company.taxCode}'),
                        if (company.website != null)
                          _buildDetailChip('Website: ${company.formattedWebsite}'),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // View Jobs Button
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4),
                      child: TextButton(
                        onPressed: () => _navigateToCompanyJobs(company),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Xem công việc',
                              style: GoogleFonts.inter(
                                color: Colors.blue[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, 
                                size: 14, color: Colors.blue[700]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Loading overlay
              if (_isNavigating)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.1),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: Colors.grey[600],
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