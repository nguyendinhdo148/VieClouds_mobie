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
  
  List<JobModel> _jobs = [];
  List<JobModel> _filteredJobs = [];
  List<ApplicationModel> _appliedJobs = [];
  bool _isLoading = true;
  bool _isApplying = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _debounceTimer;

  // Dữ liệu filter
  final List<Map<String, dynamic>> _filterData = [
    {
      'label': 'Địa điểm',
      'filterType': 'location',
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
      'label': 'Việc làm',
      'filterType': 'category',
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
      'label': 'Lương',
      'filterType': 'salary',
      'array': [
        '0 - 5.000.000',
        '5.000.000 - 15.000.000',
        '15.000.000 - 40.000.000',
        '> 40.000.000',
        'Thỏa thuận',
      ],
    },
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

        setState(() {
          if (loadMore) {
            _jobs.addAll(newJobs);
          } else {
            _jobs = newJobs;
          }
          
          _filteredJobs = _applyLocalFilters(_jobs);
          _hasMore = newJobs.length == 20;
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
      return 'Ứng tuyển';
    }
    
    final status = _getApplicationStatus(jobId);
    
    switch (status) {
      case 'pending':
        return 'Đã ứng tuyển';
      case 'accepted':
        return 'Đã được chấp nhận';
      case 'rejected':
        return 'Đã bị từ chối';
      default:
        return 'Ứng tuyển';
    }
  }

  Color _getApplyButtonColor(String jobId, bool isActive) {
    if (!isActive) {
      return Colors.grey;
    }
    
    final hasApplied = _hasAppliedToJob(jobId);
    if (!hasApplied) {
      return Colors.blue;
    }
    
    final status = _getApplicationStatus(jobId);
    
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          status == 'pending' ? 'Đã ứng tuyển' :
          status == 'accepted' ? 'Được chấp nhận' : 'Đã bị từ chối',
          style: TextStyle(
            color: status == 'pending' ? Colors.orange :
                   status == 'accepted' ? Colors.green : Colors.red,
          ),
        ),
        content: Text(
          status == 'pending' 
            ? 'Bạn đã ứng tuyển vào vị trí này. Hồ sơ của bạn đang được xem xét.'
            : status == 'accepted'
            ? 'Chúc mừng! Bạn đã được chấp nhận cho vị trí này.'
            : 'Rất tiếc, hồ sơ của bạn không phù hợp với vị trí này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.9,
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bộ lọc',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  
                  // Filter count
                  if (_selectedLocations.isNotEmpty || 
                      _selectedCategories.isNotEmpty || 
                      _selectedSalaries.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedLocations.length + _selectedCategories.length + _selectedSalaries.length} bộ lọc đang chọn',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên công việc...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Filter sections
                  Expanded(
                    child: ListView(
                      children: _filterData.map((section) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section['label'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
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
                                          fontSize: 14,
                                          color: isSelected ? Colors.white : Colors.black87,
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
                                      selectedColor: Theme.of(context).primaryColor,
                                      backgroundColor: Colors.grey[200],
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Action buttons
                  SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetFilters,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Xóa bộ lọc',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _loadJobs();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Áp dụng',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
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
      ..._selectedLocations,
      ..._selectedCategories,
      ..._selectedSalaries,
    ];
    
    if (allSelected.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ..._selectedLocations.map((location) {
              return _buildFilterChip(
                location,
                'location',
                Icons.location_on,
              );
            }).toList(),
            ..._selectedCategories.map((category) {
              return _buildFilterChip(
                category,
                'category',
                Icons.work,
              );
            }).toList(),
            ..._selectedSalaries.map((salary) {
              return _buildFilterChip(
                salary,
                'salary',
                Icons.attach_money,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String type, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        onDeleted: () {
          setState(() {
            switch (type) {
              case 'location':
                _selectedLocations.remove(label);
                break;
              case 'category':
                _selectedCategories.remove(label);
                break;
              case 'salary':
                _selectedSalaries.remove(label);
                break;
            }
          });
          _loadJobs();
        },
        backgroundColor: Colors.blue[100],
        deleteIconColor: Colors.blue[800],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Bộ lọc',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm công việc...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) => _performSearch(),
            ),
          ),
          
          // Active filter chips
          _buildFilterChips(),
          
          // Filter info
          if (_selectedLocations.isNotEmpty || 
              _selectedCategories.isNotEmpty || 
              _selectedSalaries.isNotEmpty ||
              _searchController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đang hiển thị ${_filteredJobs.length} công việc',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text(
                      'Xóa hết',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
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
                        searchQuery: _searchController.text,
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterBottomSheet,
        child: const Icon(Icons.filter_list),
        tooltip: 'Bộ lọc',
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