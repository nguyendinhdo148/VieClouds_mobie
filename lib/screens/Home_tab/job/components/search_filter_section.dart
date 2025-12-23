import 'dart:async';
import 'package:flutter/material.dart';
import 'package:viejob_app/screens/Home_tab/job/components/job_list_section.dart';
import 'package:viejob_app/screens/Home_tab/job/components/empty_state_section.dart';
import 'package:viejob_app/screens/Home_tab/job/components/job_description_section.dart';
import 'package:viejob_app/services/application_service.dart';
import 'package:viejob_app/services/job_service.dart';
import 'package:viejob_app/models/job_model.dart';
import 'package:viejob_app/models/application_model.dart';

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
  
  List<JobModel> _jobs = [];
  List<JobModel> _filteredJobs = [];
  List<ApplicationModel> _appliedJobs = [];
  bool _isLoading = true;
  bool _isApplying = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearch;
    _loadInitialData();
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
          _filteredJobs = _jobs;
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
            hintText: 'Tìm kiếm công việc...',
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          onSubmitted: (value) => _refreshJobs(),
        ),
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
          // Simple Search Bar
          _buildSearchBar(),

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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}