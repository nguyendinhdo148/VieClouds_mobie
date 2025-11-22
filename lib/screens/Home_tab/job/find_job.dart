import 'package:flutter/material.dart';
import 'package:viejob_app/screens/Home_tab/job/components/job_list_section.dart';
import 'package:viejob_app/screens/Home_tab/job/components/search_filter_section.dart';
import 'package:viejob_app/screens/Home_tab/job/components/empty_state_section.dart';
import 'package:viejob_app/screens/Home_tab/job/components/job_description_section.dart';
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
  
  String _selectedCategory = 'Tất cả';
  String _selectedLocation = 'Tất cả địa điểm';
  String _selectedSalary = 'Tất cả mức lương';
  
  List<JobModel> _jobs = [];
  List<JobModel> _filteredJobs = [];
  List<ApplicationModel> _appliedJobs = [];
  bool _isLoading = true;
  bool _isLoadingApplications = true;
  bool _isSearching = false;
  bool _isApplying = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMore = true;

  final List<String> _categories = [
    'Tất cả',
    'Lập trình',
    'Kinh doanh',
    'Marketing',
    'Design',
    'Kế toán',
    'Nhân sự',
    'Bán hàng'
  ];

  final List<String> _locations = [
    'Tất cả địa điểm',
    'Hà Nội',
    'TP Hồ Chí Minh',
    'Đà Nẵng',
    'Cần Thơ',
    'Hải Phòng',
    'Làm việc từ xa'
  ];

  final List<String> _salaries = [
    'Tất cả mức lương',
    'Dưới 10 triệu',
    '10 - 15 triệu',
    '15 - 20 triệu',
    '20 - 30 triệu',
    'Trên 30 triệu'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearch;
    _loadInitialData();
    _setupSearchListener();
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        _filterJobs();
      }
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
      final result = await _jobService.getAllJobs(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        category: _selectedCategory == 'Tất cả' ? null : _selectedCategory,
        location: _selectedLocation == 'Tất cả địa điểm' ? null : _selectedLocation,
        salaryRange: _selectedSalary == 'Tất cả mức lương' ? null : _selectedSalary,
        page: _currentPage,
        limit: 10,
      );

      if (result['success'] == true) {
        final List<JobModel> newJobs = result['jobs'] ?? [];

        setState(() {
          if (loadMore) {
            _jobs.addAll(newJobs);
          } else {
            _jobs = newJobs;
          }
          _filteredJobs = _jobs;
          _hasMore = newJobs.length == 10;
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
        _isSearching = false;
      });
    }
  }

  Future<void> _loadAppliedJobs() async {
    try {
      print('🔄 Loading applied jobs for FindJobScreen...');
      final appliedJobs = await _applicationService.getAppliedJobs();
      
      // DEBUG: Kiểm tra jobId của từng application
      print('📦 FIND JOB - APPLIED JOBS DEBUG:');
      for (int i = 0; i < appliedJobs.length; i++) {
        final app = appliedJobs[i];
        print('   App $i: ${app.id}');
        print('     - jobId: "${app.jobId}"');
        
        if (app.jobData is Map) {
          final jobData = app.jobData as Map;
          print('     - jobData keys: ${jobData.keys}');
        }
        print('     ---');
      }
      
      setState(() {
        _appliedJobs = appliedJobs;
      });
    } catch (e) {
      print('❌ Error loading applied jobs in FindJobScreen: $e');
    } finally {
      setState(() {
        _isLoadingApplications = false;
      });
    }
  }

  bool _hasAppliedToJob(String jobId) {
    print('🔍 FindJob - Checking application for job: $jobId');
    
    for (final app in _appliedJobs) {
      print('   - Checking app: ${app.id}');
      print('     - app.jobId: "${app.jobId}"');
      
      // SO SÁNH TRỰC TIẾP app.jobId VỚI jobId
      if (app.jobId == jobId) {
        print('     -> ✅ MATCH via app.jobId');
        return true;
      }
    }
    
    print('   - ❌ NO application found for job: $jobId');
    return false;
  }

  String _getApplicationStatus(String jobId) {
    print('📊 FindJob - Getting status for job: $jobId');
    
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
      
      print('   - Application status: ${application.status}');
      return application.status;
    } catch (e) {
      print('   - Error getting status: $e');
      return 'not_applied';
    }
  }

  String _getApplyButtonText(String jobId) {
    final hasApplied = _hasAppliedToJob(jobId);
    print('🔄 FindJob - Getting button text for job: $jobId');
    print('   - Has applied: $hasApplied');
    
    if (!hasApplied) {
      print('   - Button text: Ứng tuyển');
      return 'Ứng tuyển';
    }
    
    final status = _getApplicationStatus(jobId);
    print('   - Application status: $status');
    
    switch (status) {
      case 'pending':
        print('   - Button text: Đã ứng tuyển');
        return 'Đã ứng tuyển';
      case 'accepted':
        print('   - Button text: Đã được chấp nhận');
        return 'Đã được chấp nhận';
      case 'rejected':
        print('   - Button text: Đã bị từ chối');
        return 'Đã bị từ chối';
      default:
        print('   - Button text: Ứng tuyển (default)');
        return 'Ứng tuyển';
    }
  }

  Color _getApplyButtonColor(String jobId, bool isActive) {
    if (!isActive) {
      print('🎨 FindJob - Button color: Grey (inactive)');
      return Colors.grey;
    }
    
    final hasApplied = _hasAppliedToJob(jobId);
    if (!hasApplied) {
      print('🎨 FindJob - Button color: Blue (can apply)');
      return Colors.blue;
    }
    
    final status = _getApplicationStatus(jobId);
    print('🎨 FindJob - Button color for status $status');
    
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  bool _canApply(String jobId, bool isActive) {
    final canApply = isActive && !_hasAppliedToJob(jobId);
    print('🔓 FindJob - Can apply for job $jobId: $canApply (isActive: $isActive)');
    return canApply;
  }

  Future<void> _applyForJob(JobModel job) async {
    setState(() {
      _isApplying = true;
    });

    try {
      final result = await _applicationService.applyJob(job.id);

      if (result['success'] == true) {
        // Reload applied jobs để cập nhật UI
        print('🔄 FindJob - Reloading applied jobs after successful application...');
        await _loadAppliedJobs();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Ứng tuyển thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Ứng tuyển thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
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
        title: const Text(
          'Xác nhận ứng tuyển',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc muốn ứng tuyển vào vị trí:'),
            const SizedBox(height: 8),
            Text(
              job.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            Text(
              'tại ${job.companyName}',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CV của bạn sẽ được gửi đến nhà tuyển dụng',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
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
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.grey),
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
              backgroundColor: Colors.blue[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isApplying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Xác nhận ứng tuyển',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  void _showApplicationStatusDialog(JobModel job) {
    final status = _getApplicationStatus(job.id);
    String title = '';
    String message = '';
    Color color = Colors.blue;

    switch (status) {
      case 'pending':
        title = 'Đã ứng tuyển';
        message = 'Bạn đã ứng tuyển vào vị trí này. Hồ sơ của bạn đang được xem xét.';
        color = Colors.orange;
        break;
      case 'accepted':
        title = 'Được chấp nhận';
        message = 'Chúc mừng! Bạn đã được chấp nhận cho vị trí này. Nhà tuyển dụng sẽ liên hệ với bạn sớm.';
        color = Colors.green;
        break;
      case 'rejected':
        title = 'Đã bị từ chối';
        message = 'Rất tiếc, hồ sơ của bạn không phù hợp với vị trí này. Hãy thử ứng tuyển các vị trí khác.';
        color = Colors.red;
        break;
      default:
        title = 'Trạng thái ứng tuyển';
        message = 'Không thể xác định trạng thái ứng tuyển.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: color)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _filterJobs() {
    final searchText = _searchController.text.toLowerCase();
    
    setState(() {
      if (searchText.isEmpty) {
        _filteredJobs = _jobs;
      } else {
        _filteredJobs = _jobs.where((job) {
          return job.title.toLowerCase().contains(searchText) ||
                 job.companyName.toLowerCase().contains(searchText) ||
                 job.description.toLowerCase().contains(searchText) ||
                 job.category.toLowerCase().contains(searchText);
        }).toList();
      }
    });
  }

  void _performSearch() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
      _loadJobs();
    }
  }

  void _refreshJobs() {
    _loadInitialData();
  }

  void _updateFilter(String type, String value) {
    setState(() {
      switch (type) {
        case 'category':
          _selectedCategory = value;
          break;
        case 'location':
          _selectedLocation = value;
          break;
        case 'salary':
          _selectedSalary = value;
          break;
      }
    });
    _loadJobs();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'Tất cả';
      _selectedLocation = 'Tất cả địa điểm';
      _selectedSalary = 'Tất cả mức lương';
      _searchController.clear();
    });
    _loadJobs();
  }

  void _showJobDetail(JobModel job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          job.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: JobDescriptionSection(job: job),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle apply action if needed
              if (_canApply(job.id, job.isActive)) {
                _showApplyDialog(job);
              } else {
                _showApplicationStatusDialog(job);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getApplyButtonColor(job.id, job.isActive),
            ),
            child: Text(
              _getApplyButtonText(job.id),
              style: const TextStyle(color: Colors.white),
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
        title: const Text(
          'Tìm việc làm',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshJobs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          SearchFilterSection(
            searchController: _searchController,
            selectedCategory: _selectedCategory,
            selectedLocation: _selectedLocation,
            selectedSalary: _selectedSalary,
            isSearching: _isSearching,
            categories: _categories,
            locations: _locations,
            salaries: _salaries,
            onSearch: _performSearch,
            onFilterChanged: _updateFilter,
            onAdvancedFilter: _showAdvancedFilter,
          ),

          // Error Message
          if (_errorMessage.isNotEmpty)
            _buildErrorMessage(),

          // Job List
          Expanded(
            child: _isLoading && _jobs.isEmpty
                ? const Center(child: CircularProgressIndicator())
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
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
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
              style: TextStyle(
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
    );
  }

  void _showAdvancedFilter() {
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
                  const Text(
                    'Bộ lọc nâng cao',
                    style: TextStyle(
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
              const SizedBox(height: 20),
              // TODO: Add more advanced filter options
              Expanded(
                child: ListView(
                  children: [
                    // Add more filter sections here
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _resetFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Đặt lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadJobs();
                      },
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}