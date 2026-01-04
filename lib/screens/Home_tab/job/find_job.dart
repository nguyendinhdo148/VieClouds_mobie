import 'dart:async';
import 'package:flutter/material.dart';
import 'package:viejob_app/screens/Home_tab/job/components/job_list_section.dart';
import 'package:viejob_app/screens/Home_tab/job/components/empty_state_section.dart';
import 'package:viejob_app/screens/Home_tab/job/components/job_description_section.dart';
import 'package:viejob_app/services/application_service.dart';
import '../../../services/job_service.dart';
import '../../../models/job_model.dart';
import '../../../models/application_model.dart';

class FindJobScreen extends StatefulWidget {
  final String initialSearch;

  const FindJobScreen({
    Key? key,
    required this.initialSearch,
  }) : super(key: key);

  @override
  State<FindJobScreen> createState() => _FindJobScreenState();
}

class _FindJobScreenState extends State<FindJobScreen> {
  final TextEditingController _searchController = TextEditingController();
  final JobService _jobService = JobService();
  final ApplicationService _applicationService = ApplicationService();
  
  // Bộ lọc theo kiểu web - nhiều lựa chọn
  List<String> _selectedLocations = [];
  List<String> _selectedCategories = [];
  List<String> _selectedSalaries = [];
  String _selectedJobType = 'Tất cả'; // Loại công việc
  
  List<JobModel> _jobs = [];
  List<JobModel> _filteredJobs = [];
  List<ApplicationModel> _appliedJobs = [];
  bool _isLoading = true;
  bool _isApplying = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _debounceTimer;

  // Dữ liệu filter - Pastel Modern
  final List<Map<String, dynamic>> _filterData = [
    {
      'label': '📍 Địa điểm',
      'filterType': 'location',
      'icon': Icons.location_on,
      'color': Color(0xFFA8D8EA), // Pastel blue
      'array': [
        'Hà Nội',
        'Hồ Chí Minh',
        'Đà Nẵng',
        'Quảng Ninh',
        'Cần Thơ',
        'Thái Bình',
        'Hải Phòng',
        'Làm việc từ xa',
      ],
    },
    {
      'label': '💼 Việc làm',
      'filterType': 'category',
      'icon': Icons.work,
      'color': Color(0xFFAA96DA), // Pastel purple
      'array': [
        'Lập trình viên',
        'Kinh doanh',
        'Marketing',
        'Design',
        'Kế toán',
        'Nhân sự',
        'Bán hàng',
        'IT - Phần mềm',
        'Quản lý',
        'Tư vấn',
      ],
    },
    {
      'label': '💰 Lương',
      'filterType': 'salary',
      'icon': Icons.attach_money,
      'color': Color(0xFFFCBAD3), // Pastel pink
      'array': [
        '0 - 5.000.000',
        '5.000.000 - 15.000.000',
        '15.000.000 - 40.000.000',
        '> 40.000.000',
        'Thỏa thuận',
      ],
    },
  ];

  // Loại công việc
  final List<String> _jobTypes = [
    'Tất cả',
    'Full-time',
    'Part-time',
    'Thực tập',
    'Remote',
    'Freelance'
  ];

  // Map alias cho địa điểm
  final Map<String, List<String>> _locationAliasMap = {
    'Hồ Chí Minh': ['hochiminh', 'hcm', 'ho chi minh', 'tp hồ chí minh', 'tphcm'],
    'Hà Nội': ['hanoi', 'hn', 'hà nội'],
    'Đà Nẵng': ['danang', 'dn', 'đà nẵng'],
    'Quảng Ninh': ['quangninh', 'quảng ninh'],
    'Cần Thơ': ['cantho', 'cần thơ'],
    'Thái Bình': ['thaibinh', 'thái bình'],
    'Hải Phòng': ['haiphong', 'hải phòng'],
    'Làm việc từ xa': ['remote', 'làm việc từ xa', 'work from home', 'wfh'],
  };

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearch;
    _loadInitialData();
    _setupSearchListener();
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      if (_debounceTimer?.isActive ?? false) {
        _debounceTimer!.cancel();
      }
      
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (_searchController.text.isEmpty) {
          _applyFilters();
        } else {
          _performSearch();
        }
      });
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadJobs(),
      _loadAppliedJobs(),
    ]);
  }

  Future<void> _loadJobs({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      _currentPage = 1;
    }

    try {
      // Chỉ gửi 1 filter đầu tiên nếu có
      String? categoryFilter;
      if (_selectedCategories.isNotEmpty) {
        categoryFilter = _selectedCategories.first;
      }
      
      String? locationFilter;
      if (_selectedLocations.isNotEmpty) {
        locationFilter = _selectedLocations.first;
      }
      
      String? salaryFilter;
      if (_selectedSalaries.isNotEmpty) {
        salaryFilter = _selectedSalaries.first;
      }

      final result = await _jobService.getAllJobs(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        category: categoryFilter,
        location: locationFilter,
        salaryRange: salaryFilter,
        page: _currentPage,
        limit: 20,
      );

      if (result['success'] == true) {
        final List<JobModel> newJobs = result['jobs'] ?? [];
        
        // Lọc chỉ lấy công việc đang hoạt động
        final List<JobModel> activeJobs = newJobs.where((job) => job.isActive).toList();

        setState(() {
          if (loadMore) {
            _jobs.addAll(activeJobs);
          } else {
            _jobs = activeJobs;
          }
          
          _filteredJobs = _applyLocalFilters(_jobs);
          _hasMore = activeJobs.length == 20;
          _currentPage++;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Không thể tải danh sách công việc';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Hàm normalize text để tìm kiếm không dấu
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'[đ]'), 'd')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(' ', '');
  }

  // Hàm parse lương từ string
  double? _parseSalary(String salaryText) {
    try {
      final regex = RegExp(r'(\d+(?:\.\d+)?)');
      final matches = regex.allMatches(salaryText);
      
      if (matches.isEmpty) return null;
      
      final numbers = matches
          .map((match) => double.parse(match.group(1)!))
          .toList();
      
      if (numbers.length > 1) {
        return numbers.reduce((a, b) => a + b) / numbers.length;
      }
      
      return numbers.first;
    } catch (e) {
      return null;
    }
  }

  // Hàm áp dụng filter local
  List<JobModel> _applyLocalFilters(List<JobModel> jobs) {
    return jobs.where((job) {
      // Kiểm tra search text
      final searchText = _searchController.text.trim().toLowerCase();
      if (searchText.isNotEmpty) {
        final normalizedSearch = _normalize(searchText);
        final normalizedJobTitle = _normalize(job.title);
        final normalizedCompanyName = _normalize(job.companyName);
        final normalizedLocation = _normalize(job.location);
        final normalizedCategory = _normalize(job.category);
        
        if (!normalizedJobTitle.contains(normalizedSearch) &&
            !normalizedCompanyName.contains(normalizedSearch) &&
            !normalizedLocation.contains(normalizedSearch) &&
            !normalizedCategory.contains(normalizedSearch)) {
          return false;
        }
      }

      // Kiểm tra job type
      if (_selectedJobType != 'Tất cả') {
        if (_selectedJobType == 'Remote') {
          if (!job.location.toLowerCase().contains('remote') &&
              !job.location.toLowerCase().contains('từ xa') &&
              !job.title.toLowerCase().contains('remote')) {
            return false;
          }
        } else if (!job.jobType.toLowerCase().contains(_selectedJobType.toLowerCase())) {
          return false;
        }
      }

      // Kiểm tra location
      if (_selectedLocations.isNotEmpty) {
        bool locationMatch = false;
        final normalizedJobLocation = _normalize(job.location);
        
        for (var selectedLocation in _selectedLocations) {
          final aliases = _locationAliasMap[selectedLocation] ?? [_normalize(selectedLocation)];
          if (aliases.any((alias) => normalizedJobLocation.contains(alias))) {
            locationMatch = true;
            break;
          }
        }
        
        if (!locationMatch) return false;
      }

      // Kiểm tra category
      if (_selectedCategories.isNotEmpty) {
        final normalizedJobCategory = _normalize(job.category);
        final match = _selectedCategories.any((category) {
          return normalizedJobCategory.contains(_normalize(category));
        });
        
        if (!match) return false;
      }

      // Kiểm tra salary
      if (_selectedSalaries.isNotEmpty) {
        final jobSalary = job.salary.toString().toLowerCase();
        bool salaryMatch = false;
        
        for (var salaryRange in _selectedSalaries) {
          if (salaryRange == 'Thỏa thuận') {
            if (jobSalary.contains('thỏa thuận') || 
                jobSalary.contains('negotiable') ||
                jobSalary.contains('thoa thuan')) {
              salaryMatch = true;
              break;
            }
            continue;
          }
          
          final jobSalaryValue = _parseSalary(job.salary as String);
          if (jobSalaryValue == null) continue;
          
          if (salaryRange.contains('>')) {
            // Trên 40 triệu
            if (jobSalaryValue > 40) {
              salaryMatch = true;
              break;
            }
          } else {
            final parts = salaryRange.split(' - ');
            if (parts.length == 2) {
              final min = _parseSalary(parts[0]) ?? 0;
              final max = _parseSalary(parts[1]) ?? double.infinity;
              
              if (jobSalaryValue >= min && jobSalaryValue <= max) {
                salaryMatch = true;
                break;
              }
            }
          }
        }
        
        if (!salaryMatch) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _loadAppliedJobs() async {
    try {
      final appliedJobs = await _applicationService.getAppliedJobs();
      setState(() {
        _appliedJobs = appliedJobs;
      });
    } catch (e) {
      print('❌ Error loading applied jobs in FindJobScreen: $e');
    } finally {
      setState(() {
      });
    }
  }

  bool _hasAppliedToJob(String jobId) {
    return _appliedJobs.any((app) => app.jobId == jobId);
  }

  String _getApplicationStatus(String jobId) {
    try {
      final application = _appliedJobs.firstWhere(
        (app) => app.jobId == jobId,
        orElse: () => ApplicationModel(
          id: '',
          jobId: '',
          applicantId: '',
          status: 'not_applied',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return application.status;
    } catch (e) {
      return 'not_applied';
    }
  }

  String _getApplyButtonText(String jobId) {
    final hasApplied = _hasAppliedToJob(jobId);
    
    if (!hasApplied) {
      return 'ỨNG TUYỂN';
    }
    
    final status = _getApplicationStatus(jobId);
    
    switch (status) {
      case 'pending':
        return 'ĐÃ ỨNG TUYỂN';
      case 'accepted':
        return 'ĐƯỢC CHẤP NHẬN';
      case 'rejected':
        return 'ĐÃ BỊ TỪ CHỐI';
      default:
        return 'ỨNG TUYỂN';
    }
  }

  Color _getApplyButtonColor(String jobId, bool isActive) {
    if (!isActive) {
      return Colors.grey;
    }
    
    final hasApplied = _hasAppliedToJob(jobId);
    if (!hasApplied) {
      return Color(0xFFA8D8EA); // Pastel blue
    }
    
    final status = _getApplicationStatus(jobId);
    
    switch (status) {
      case 'pending':
        return Color(0xFFFFC857); // Pastel yellow/orange
      case 'accepted':
        return Color(0xFF7FB685); // Pastel green
      case 'rejected':
        return Color(0xFFF28482); // Pastel red
      default:
        return Color(0xFFA8D8EA);
    }
  }

  bool _canApply(String jobId, bool isActive) {
    return isActive && !_hasAppliedToJob(jobId);
  }

  Future<void> _applyForJob(JobModel job) async {
    setState(() {
      _isApplying = true;
    });

    try {
      final result = await _applicationService.applyJob(job.id);

      if (result['success'] == true) {
        await _loadAppliedJobs();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Ứng tuyển thành công!',
                style: TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Color(0xFF7FB685),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Ứng tuyển thất bại',
                style: TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Color(0xFFF28482),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e',
              style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: Color(0xFFF28482),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isApplying = false;
      });
    }
  }

  void _showApplyDialog(JobModel job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'XÁC NHẬN ỨNG TUYỂN',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D3748),
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tại ${job.companyName}',
                    style: TextStyle(
                      color: Color(0xFF718096),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFFA8D8EA),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Color(0xFF4A90E2), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CV của bạn sẽ được gửi đến nhà tuyển dụng',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A90E2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'HUỶ',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isApplying
                ? null
                : () async {
                    Navigator.pop(context);
                    await _applyForJob(job);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFA8D8EA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 2,
            ),
            child: _isApplying
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'XÁC NHẬN ỨNG TUYỂN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showApplicationStatusDialog(JobModel job) {
    final status = _getApplicationStatus(job.id);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          status == 'pending' ? '📝 ĐÃ ỨNG TUYỂN' :
          status == 'accepted' ? '✅ ĐƯỢC CHẤP NHẬN' : '❌ ĐÃ BỊ TỪ CHỐI',
          style: TextStyle(
            color: status == 'pending' ? Color(0xFFFFC857) :
                   status == 'accepted' ? Color(0xFF7FB685) : Color(0xFFF28482),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tại ${job.companyName}',
                    style: TextStyle(
                      color: Color(0xFF718096),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              status == 'pending' 
                ? 'Hồ sơ của bạn đang được nhà tuyển dụng xem xét. Vui lòng chờ phản hồi!'
                : status == 'accepted'
                ? '🎉 Chúc mừng! Bạn đã được chấp nhận cho vị trí này. Hãy liên hệ với nhà tuyển dụng để biết thêm chi tiết.'
                : 'Rất tiếc, hồ sơ của bạn không phù hợp với vị trí này. Đừng nản lòng, hãy tiếp tục tìm kiếm cơ hội khác!',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFA8D8EA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'ĐÓNG',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    setState(() {
    });
    _loadJobs();
  }

  void _applyFilters() {
    setState(() {
      _filteredJobs = _applyLocalFilters(_jobs);
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedLocations.clear();
      _selectedCategories.clear();
      _selectedSalaries.clear();
      _selectedJobType = 'Tất cả';
      _searchController.clear();
    });
    _loadJobs();
  }

  void _refreshJobs() {
    _loadInitialData();
  }

  void _showJobDetail(JobModel job) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(0xFFA8D8EA).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        image: job.companyLogo != null
                            ? DecorationImage(
                                image: NetworkImage(job.companyLogo!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: job.companyLogo == null
                          ? Icon(Icons.business,
                              color: Color(0xFFA8D8EA), size: 24)
                          : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Color(0xFF2D3748),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            job.companyName,
                            style: TextStyle(
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: JobDescriptionSection(job: job),
                ),
              ),
              
              // Footer with apply button
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          'ĐÓNG',
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (_canApply(job.id, job.isActive)) {
                            _showApplyDialog(job);
                          } else {
                            _showApplicationStatusDialog(job);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getApplyButtonColor(job.id, job.isActive),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          elevation: 3,
                        ),
                        child: Text(
                          _getApplyButtonText(job.id),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color(0xFFF8F9FA),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🎯 BỘ LỌC NÂNG CAO',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Filter count
                  if (_selectedLocations.isNotEmpty || 
                      _selectedCategories.isNotEmpty || 
                      _selectedSalaries.isNotEmpty ||
                      _selectedJobType != 'Tất cả')
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      margin: EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFFE8F4FD),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.filter_alt, size: 16, color: Color(0xFF4A90E2)),
                                SizedBox(width: 6),
                                Text(
                                  '${_selectedLocations.length + _selectedCategories.length + _selectedSalaries.length + (_selectedJobType != 'Tất cả' ? 1 : 0)} bộ lọc',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4A90E2),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: _resetFilters,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.clear_all, size: 16, color: Color(0xFFDC2626)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Xóa hết',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Job Type Filter
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎯 LOẠI CÔNG VIỆC',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _jobTypes.map((type) {
                                bool isSelected = _selectedJobType == type;
                                return ChoiceChip(
                                  label: Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : Color(0xFF2D3748),
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedJobType = selected ? type : 'Tất cả';
                                    });
                                  },
                                  selectedColor: Color(0xFFA8D8EA),
                                  backgroundColor: Color(0xFFF1F5F9),
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Filter sections
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: _filterData.map((section) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              color: Colors.white,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: (section['color'] as Color).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            section['icon'] as IconData,
                                            color: section['color'] as Color,
                                            size: 18,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          section['label'].toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: Color(0xFF2D3748),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: (section['array'] as List<String>).map((item) {
                                        bool isSelected = false;
                                        List<String> selectedList = [];
                                        
                                        switch (section['filterType']) {
                                          case 'location':
                                            selectedList = _selectedLocations;
                                            break;
                                          case 'category':
                                            selectedList = _selectedCategories;
                                            break;
                                          case 'salary':
                                            selectedList = _selectedSalaries;
                                            break;
                                        }
                                        
                                        isSelected = selectedList.contains(item);
                                        
                                        return ChoiceChip(
                                          label: Text(
                                            item,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected ? Colors.white : Color(0xFF2D3748),
                                            ),
                                          ),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                selectedList.add(item);
                                              } else {
                                                selectedList.remove(item);
                                              }
                                            });
                                          },
                                          selectedColor: section['color'] as Color,
                                          backgroundColor: Color(0xFFF1F5F9),
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  
                  // Action buttons
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetFilters,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Color(0xFFF28482)),
                            ),
                            child: Text(
                              'XÓA BỘ LỌC',
                              style: TextStyle(
                                color: Color(0xFFF28482),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _loadJobs();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFA8D8EA),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: Text(
                              'ÁP DỤNG',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChips() {
    final allSelected = [
      if (_selectedJobType != 'Tất cả') _selectedJobType,
      ..._selectedLocations,
      ..._selectedCategories,
      ..._selectedSalaries,
    ];
    
    if (allSelected.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0F7FF),
            Color(0xFFE8F4FD),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt, size: 18, color: Color(0xFF4A90E2)),
              SizedBox(width: 8),
              Text(
                'Bộ lọc đang áp dụng:',
                style: TextStyle(
                  color: Color(0xFF4A90E2),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: allSelected.map((item) {
                IconData icon;
                Color color;
                
                if (item == _selectedJobType) {
                  icon = Icons.category;
                  color = Color(0xFFA8D8EA);
                } else if (_selectedLocations.contains(item)) {
                  icon = Icons.location_on;
                  color = Color(0xFFA8D8EA);
                } else if (_selectedCategories.contains(item)) {
                  icon = Icons.work;
                  color = Color(0xFFAA96DA);
                } else {
                  icon = Icons.attach_money;
                  color = Color(0xFFFCBAD3);
                }
                
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: color),
                        SizedBox(width: 6),
                        Text(
                          item,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (item == _selectedJobType) {
                                _selectedJobType = 'Tất cả';
                              } else if (_selectedLocations.contains(item)) {
                                _selectedLocations.remove(item);
                              } else if (_selectedCategories.contains(item)) {
                                _selectedCategories.remove(item);
                              } else if (_selectedSalaries.contains(item)) {
                                _selectedSalaries.remove(item);
                              }
                            });
                            _loadJobs();
                          },
                          child: Icon(Icons.close, size: 14, color: color),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red[100]!),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.error_outline, color: Colors.red[600], size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Có lỗi xảy ra',
                      style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: Colors.red[600]),
                onPressed: () {
                  setState(() {
                    _errorMessage = '';
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        title: Text(
          '🔍 TÌM VIỆC LÀM',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D3748),
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: EdgeInsets.only(left: 8),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
              splashRadius: 20,
            ),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: IconButton(
                icon: Icon(Icons.refresh_rounded, size: 20),
                onPressed: _refreshJobs,
                tooltip: 'Làm mới',
                splashRadius: 20,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8),
            child: Material(
              color: Color(0xFFA8D8EA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              child: IconButton(
                icon: Icon(Icons.filter_alt_rounded, size: 20, color: Color(0xFFA8D8EA)),
                onPressed: _showFilterBottomSheet,
                tooltip: 'Bộ lọc',
                splashRadius: 20,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with gradient
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFF8F9FA),
                ],
              ),
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 3,
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: '🔍 Tìm kiếm công việc, kỹ năng, công ty...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Container(
                    margin: EdgeInsets.only(left: 12),
                    child: Icon(Icons.search_rounded, 
                      color: Color(0xFFA8D8EA), size: 24),
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.clear_rounded, 
                              size: 18, color: Color(0xFF64748B)),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch();
                          },
                          splashRadius: 20,
                        )
                      : null,
                ),
                onSubmitted: (value) => _performSearch(),
              ),
            ),
          ),
          
          // Active filter chips
          _buildFilterChips(),
          
          // Result info
          if (_selectedLocations.isNotEmpty || 
              _selectedCategories.isNotEmpty || 
              _selectedSalaries.isNotEmpty ||
              _selectedJobType != 'Tất cả' ||
              _searchController.text.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(0xFFA8D8EA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.work_rounded, 
                      size: 18, color: Color(0xFFA8D8EA)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tìm thấy ${_filteredJobs.length} công việc phù hợp',
                      style: TextStyle(
                        color: Color(0xFF2D3748),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (_selectedLocations.isNotEmpty || 
                      _selectedCategories.isNotEmpty || 
                      _selectedSalaries.isNotEmpty ||
                      _selectedJobType != 'Tất cả')
                    GestureDetector(
                      onTap: _resetFilters,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFFEE2E2).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'XÓA LỌC',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          // Error Message
          if (_errorMessage.isNotEmpty)
            _buildErrorMessage(),
          
          // Job List
          Expanded(
            child: _isLoading && _jobs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA8D8EA)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Đang tải công việc...',
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredJobs.isEmpty
                    ? EmptyStateSection(
                        onRetry: _refreshJobs,
                        hasSearchText: _searchController.text.isNotEmpty,
                      )
                    : JobListSection(
                        jobs: _filteredJobs,
                        hasMore: _hasMore,
                        isLoading: _isLoading,
                        appliedJobs: _appliedJobs,
                        isApplying: _isApplying,
                        onLoadMore: () => _loadJobs(loadMore: true),
                        onJobTap: _showJobDetail,
                        onApply: _applyForJob,
                        onShowStatus: _showApplicationStatusDialog,
                        hasAppliedToJob: _hasAppliedToJob,
                        getApplyButtonText: _getApplyButtonText,
                        getApplyButtonColor: _getApplyButtonColor,
                        canApply: _canApply,
                        searchQuery: _searchController.text,
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterBottomSheet,
        backgroundColor: Color(0xFFA8D8EA),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.filter_alt_rounded, size: 24),
        tooltip: 'Bộ lọc',
        elevation: 4,
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}