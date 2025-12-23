import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:viejob_app/services/job_service.dart';
import 'package:viejob_app/services/application_service.dart';
import '../../../models/job_model.dart';
import '../../../models/company_model.dart';
import '../../../models/application_model.dart';
import 'company_info_section.dart'; // File mới tách ra

class JobByCompanyScreen extends StatefulWidget {
  final CompanyModel company;

  const JobByCompanyScreen({
    Key? key,
    required this.company,
  }) : super(key: key);

  @override
  State<JobByCompanyScreen> createState() => _JobByCompanyScreenState();
}

class _JobByCompanyScreenState extends State<JobByCompanyScreen> {
  final JobService _jobService = JobService();
  final ApplicationService _applicationService = ApplicationService();
  
  List<JobModel> _jobs = [];
  List<ApplicationModel> _appliedJobs = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
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
      final result = await _jobService.getJobsByCompany(
        companyId: widget.company.id,
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
      });
    }
  }

  Future<void> _loadAppliedJobs() async {
    try {
      print('🔄 Loading applied jobs...');
      final appliedJobs = await _applicationService.getAppliedJobs();
      
      setState(() {
        _appliedJobs = appliedJobs;
      });
    } catch (e) {
      print('❌ Error loading applied jobs: $e');
    } finally {
      setState(() {
      });
    }
  }

  bool _hasAppliedToJob(String jobId) {
    for (final app in _appliedJobs) {
      if (app.jobId == jobId) {
        return true;
      }
    }
    return false;
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
    if (!hasApplied) return 'Ứng tuyển';
    
    final status = _getApplicationStatus(jobId);
    switch (status) {
      case 'pending': return 'Đã ứng tuyển';
      case 'accepted': return 'Đã được chấp nhận';
      case 'rejected': return 'Đã bị từ chối';
      default: return 'Ứng tuyển';
    }
  }

  Color _getApplyButtonColor(String jobId, bool isActive) {
    if (!isActive) return Colors.grey;
    
    final hasApplied = _hasAppliedToJob(jobId);
    if (!hasApplied) return Colors.blue;
    
    final status = _getApplicationStatus(jobId);
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.blue;
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
        title: Text(
          'Xác nhận ứng tuyển',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn ứng tuyển vào vị trí:',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 8),
            Text(
              job.title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            Text(
              'tại ${widget.company.name}',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
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
                      style: GoogleFonts.inter(
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
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(color: Colors.grey[600]),
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
                : Text(
                    'Xác nhận ứng tuyển',
                    style: GoogleFonts.inter(color: Colors.white),
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
        title: Text(title, style: GoogleFonts.inter(color: color)),
        content: Text(message, style: GoogleFonts.inter()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Công việc tại ${widget.company.name}',
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
          // Company Info Section - ĐÃ TÁCH RA FILE RIÊNG
          CompanyInfoSection(company: widget.company),
          
          // Error Message
          if (_errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
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

          // Job Count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${_jobs.length} công việc đang tuyển',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // Job List
          Expanded(
            child: _isLoading && _jobs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _jobs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _jobs.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _jobs.length) {
                            return _buildLoadMoreButton();
                          }
                          return _buildJobItem(_jobs[index]);
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
            'Không có công việc nào',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.company.name} hiện chưa có công việc nào đang tuyển',
            textAlign: TextAlign.center,
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
              : const Text('Tải thêm công việc'),
        ),
      ),
    );
  }

  Widget _buildJobItem(JobModel job) {
    final canApply = _canApply(job.id, job.isActive);
    final buttonText = _getApplyButtonText(job.id);
    final buttonColor = _getApplyButtonColor(job.id, job.isActive);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Title and Status
          Row(
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: job.isActive ? Colors.green[50] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: job.isActive ? Colors.green[200]! : Colors.grey[300]!,
                  ),
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
          const SizedBox(height: 12),
          
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
          
          // Experience and Position
          Row(
            children: [
              _buildJobDetail(Icons.work_history, job.experienceText),
              const SizedBox(width: 16),
              _buildJobDetail(Icons.badge, job.positionTitle),
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
                onPressed: job.isActive && !_isApplying
                    ? () {
                        if (canApply) {
                          _showApplyDialog(job);
                        } else {
                          _showApplicationStatusDialog(job);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
                child: _isApplying && canApply
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        buttonText,
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
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}