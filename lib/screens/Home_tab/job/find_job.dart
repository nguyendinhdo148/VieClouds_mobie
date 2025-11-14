import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/job_service.dart';
import '../../../models/job_model.dart';

class FindJobScreen extends StatefulWidget {
  const FindJobScreen({Key? key, required String initialSearch}) : super(key: key);

  @override
  State<FindJobScreen> createState() => _FindJobScreenState();
}

class _FindJobScreenState extends State<FindJobScreen> {
  final TextEditingController _searchController = TextEditingController();
  final JobService _jobService = JobService();
  
  String _selectedCategory = 'Tất cả';
  String _selectedLocation = 'Tất cả địa điểm';
  String _selectedSalary = 'Tất cả mức lương';
  
  List<JobModel> _jobs = [];
  List<JobModel> _filteredJobs = [];
  bool _isLoading = true;
  bool _isSearching = false;
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
    _loadJobs();
    _setupSearchListener();
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        _filterJobs();
      }
    });
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
          _hasMore = newJobs.length == 10; // Assuming 10 items per page
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
    _loadJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tìm việc làm',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Search Bar
                Container(
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
                      hintText: 'Tìm kiếm công việc, kỹ năng, công ty...',
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
                          IconButton(
                            icon: const Icon(Icons.tune, color: Colors.grey),
                            onPressed: _showAdvancedFilter,
                          ),
                        ],
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (value) => _performSearch(),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Lĩnh vực', _selectedCategory, _showCategoryFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Địa điểm', _selectedLocation, _showLocationFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Mức lương', _selectedSalary, _showSalaryFilter),
                    ],
                  ),
                ),
              ],
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

          // Job List
          Expanded(
            child: _isLoading && _jobs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredJobs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredJobs.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _filteredJobs.length) {
                            return _buildLoadMoreButton();
                          }
                          return _buildJobItem(_filteredJobs[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy công việc phù hợp',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
            style: GoogleFonts.inter(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _refreshJobs,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ElevatedButton(
          onPressed: _isLoading ? null : () => _loadJobs(loadMore: true),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tải thêm'),
        ),
      ),
    );
  }

  Widget _buildJobItem(JobModel job) {
    return Container(
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
                width: 50,
                height: 50,
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
                child: job.companyLogo != null
                    ? null
                    : const Icon(Icons.business, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.companyName,
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: Colors.grey),
                onPressed: () {
                  // TODO: Implement save job
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Job Details
          Row(
            children: [
              _buildJobDetail(Icons.location_on, job.location),
              const SizedBox(width: 16),
              _buildJobDetail(Icons.attach_money, job.formattedSalary),
              const SizedBox(width: 16),
              _buildJobDetail(Icons.access_time, job.jobTypeText),
            ],
          ),
          const SizedBox(height: 12),
          
          // Job Description
          Text(
            job.description,
            style: GoogleFonts.inter(
              color: Colors.grey[600],
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // Posted Time and Apply Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.timeAgo,
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _showJobDetail(job);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
                child: Text(
                  'Ứng tuyển',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text.length > 15 ? '${text.substring(0, 15)}...' : text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showJobDetail(JobModel job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(job.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Công ty: ${job.companyName}'),
              Text('Địa điểm: ${job.location}'),
              Text('Mức lương: ${job.formattedSalary}'),
              Text('Loại hình: ${job.jobTypeText}'),
              Text('Kinh nghiệm: ${job.experienceText}'),
              Text('Vị trí: ${job.positionTitle}'),
              const SizedBox(height: 16),
              const Text('Mô tả công việc:'),
              Text(job.description),
              const SizedBox(height: 8),
              if (job.requirements.isNotEmpty) ...[
                const Text('Yêu cầu:'),
                ...job.requirements.map((req) => Text('• $req')).toList(),
              ],
              if (job.benefits.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Phúc lợi:'),
                ...job.benefits.map((benefit) => Text('• $benefit')).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement apply job
              Navigator.pop(context);
            },
            child: const Text('Ứng tuyển'),
          ),
        ],
      ),
    );
  }

  // Các method filter khác giữ nguyên...
  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value.length > 15 ? '${value.substring(0, 15)}...' : value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return _buildFilterBottomSheet(
          'Chọn lĩnh vực',
          _categories,
          _selectedCategory,
          (value) {
            setState(() {
              _selectedCategory = value;
            });
            Navigator.pop(context);
            _loadJobs();
          },
        );
      },
    );
  }

  void _showLocationFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return _buildFilterBottomSheet(
          'Chọn địa điểm',
          _locations,
          _selectedLocation,
          (value) {
            setState(() {
              _selectedLocation = value;
            });
            Navigator.pop(context);
            _loadJobs();
          },
        );
      },
    );
  }

  void _showSalaryFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return _buildFilterBottomSheet(
          'Chọn mức lương',
          _salaries,
          _selectedSalary,
          (value) {
            setState(() {
              _selectedSalary = value;
            });
            Navigator.pop(context);
            _loadJobs();
          },
        );
      },
    );
  }

  Widget _buildFilterBottomSheet(
    String title,
    List<String> options,
    String selectedValue,
    ValueChanged<String> onSelected,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((option) => ListTile(
            title: Text(option),
            trailing: option == selectedValue
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
            onTap: () => onSelected(option),
          )).toList(),
          const SizedBox(height: 20),
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
                  Text(
                    'Bộ lọc nâng cao',
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
                        setState(() {
                          _selectedCategory = 'Tất cả';
                          _selectedLocation = 'Tất cả địa điểm';
                          _selectedSalary = 'Tất cả mức lương';
                          _searchController.clear();
                        });
                        Navigator.pop(context);
                        _loadJobs();
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