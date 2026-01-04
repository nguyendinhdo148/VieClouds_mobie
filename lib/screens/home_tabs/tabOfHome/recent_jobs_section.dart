import 'package:flutter/material.dart';
import 'package:viejob_app/models/job_model.dart';
import 'package:viejob_app/models/application_model.dart';
import 'package:viejob_app/services/application_service.dart';
import 'package:viejob_app/screens/Home_tab/job/find_job.dart';
import 'package:viejob_app/screens/Home_tab/job/components/job_description_section.dart';

class RecentJobsSection extends StatefulWidget {
  final List<JobModel> jobs;

  const RecentJobsSection({
    Key? key,
    required this.jobs,
  }) : super(key: key);

  @override
  State<RecentJobsSection> createState() => _RecentJobsSectionState();
}

class _RecentJobsSectionState extends State<RecentJobsSection> {
  int _currentJobPage = 0;
  final PageController _jobPageController = PageController();

  final ApplicationService _applicationService = ApplicationService();
  List<ApplicationModel> _appliedJobs = [];

  // Danh sách công việc đã lọc - chỉ hiển thị các công việc đang hoạt động
  List<JobModel> get _filteredJobs {
    return widget.jobs.where((job) => job.isActive).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAppliedJobs();
  }

  Future<void> _loadAppliedJobs() async {
    try {
      final appliedJobs = await _applicationService.getAppliedJobs();
      setState(() {
        _appliedJobs = appliedJobs;
      });
    } catch (e) {
      print("Error loading applied jobs: $e");
    } finally {
      setState(() {});
    }
  }

  bool _hasAppliedToJob(String jobId) {
    return _appliedJobs.any((app) => app.jobId == jobId);
  }

  String _getApplicationStatus(String jobId) {
    try {
      final app = _appliedJobs.firstWhere((a) => a.jobId == jobId);
      return app.status;
    } catch (_) {
      return "not_applied";
    }
  }

  String _getApplyButtonText(String jobId) {
    if (!_hasAppliedToJob(jobId)) return "Ứng tuyển";

    switch (_getApplicationStatus(jobId)) {
      case "pending":
        return "Đã ứng tuyển";
      case "accepted":
        return "Đã được chấp nhận";
      case "rejected":
        return "Đã bị từ chối";
      default:
        return "Ứng tuyển";
    }
  }

  bool _canApply(String jobId) {
    if (!_hasAppliedToJob(jobId)) return true;
    return false;
  }

  Color _getApplyButtonColor(String jobId, bool isActive) {
    if (!isActive) return Colors.grey;

    if (!_hasAppliedToJob(jobId)) return Colors.blue;

    switch (_getApplicationStatus(jobId)) {
      case "pending":
        return Colors.orange;
      case "accepted":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra nếu không có công việc đang hoạt động
    if (_filteredJobs.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Công việc mới nhất', style: _TextStyles.displayMedium),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const FindJobScreen(initialSearch: '')),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: Text(
                'Xem tất cả',
                style: _TextStyles.bodyMedium.copyWith(
                  color: const Color.fromARGB(255, 0, 59, 210),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _jobPageController,
            // Sử dụng _filteredJobs thay vì widget.jobs
            itemCount: (_filteredJobs.length / 2).ceil(),
            onPageChanged: (page) {
              setState(() {
                _currentJobPage = page;
              });
            },
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * 2;
              final endIndex = startIndex + 2;
              final jobs = _filteredJobs.sublist(
                startIndex,
                endIndex < _filteredJobs.length
                    ? endIndex
                    : _filteredJobs.length,
              );

              return ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: jobs
                    .map((job) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildJobCard(job)))
                    .toList(),
              );
            },
          ),
        ),

        const SizedBox(height: 12),
        // Sử dụng _filteredJobs để tính toán số indicator
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Công việc mới nhất', style: _TextStyles.displayMedium),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const FindJobScreen(initialSearch: '')),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: Text(
                'Xem tất cả',
                style: _TextStyles.bodyMedium.copyWith(
                  color: const Color.fromARGB(255, 0, 59, 210),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.work_off,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Hiện không có công việc nào đang tuyển',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    // Tính toán số trang dựa trên _filteredJobs
    final pageCount = (_filteredJobs.length / 2).ceil();
    
    // Chỉ hiển thị indicator nếu có nhiều hơn 1 trang
    if (pageCount <= 1) return const SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentJobPage == index
                ? _PastelColors.primary
                : _PastelColors.primary.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(JobModel job) {
    // Vì đã lọc nên job.isActive luôn là true
    return GestureDetector(
      onTap: () {
        _showJobDetail(job);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _PastelColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _PastelColors.secondary.withOpacity(0.1),
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
                      color: _PastelColors.secondary, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                      style: _TextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(job.companyName,
                      style: _TextStyles.bodySmall.copyWith(
                        color: _PastelColors.grey,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 12, color: _PastelColors.accent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(job.location,
                            style: _TextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  Row(
                    children: [
                      Icon(Icons.attach_money,
                          size: 12, color: _PastelColors.accent),
                      const SizedBox(width: 4),
                      Text(job.formattedSalary,
                          style: _TextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.green[700],
                          )),
                    ],
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15), // Luôn là xanh vì chỉ hiển thị công việc đang tuyển
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Đang tuyển', // Luôn hiển thị "Đang tuyển" vì đã lọc
                    style: _TextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green[700],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(job.timeAgo,
                    style: _TextStyles.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showJobDetail(JobModel job) {
    final buttonText = _getApplyButtonText(job.id);
    final buttonColor = _getApplyButtonColor(job.id, job.isActive);
    final canApply = _canApply(job.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(job.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            )),
        content: SizedBox(
            width: double.maxFinite,
            child: JobDescriptionSection(job: job)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                )),
          ),
          ElevatedButton(
            onPressed: canApply
                ? () {
                    Navigator.pop(context);
                    _showApplyConfirmation(context, job);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
            ),
            child: Text(buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }

  void _showApplyConfirmation(BuildContext context, JobModel job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận ứng tuyển',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            )),
        content: Text("Bạn có chắc muốn ứng tuyển vào ${job.title}?",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                )),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _applyForJob(job);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Xác nhận ứng tuyển',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }

  Future<void> _applyForJob(JobModel job) async {
    try {
      final result = await _applicationService.applyJob(job.id);

      if (result['success'] == true) {
        _loadAppliedJobs();

        _showApplicationSuccess(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Ứng tuyển thất bại',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                )),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error applying job: $e");
    }
  }

  void _showApplicationSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ứng tuyển thành công!',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            )),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _PastelColors {
  static const Color primary = Color(0xFFA8D8EA);
  static const Color secondary = Color(0xFFAA96DA);
  static const Color accent = Color(0xFFFCBAD3);
  static const Color yellow = Color(0xFFFFFDD2);
  static const Color white = Color(0xFFFFFFFF);
  static const Color dark = Color(0xFF2D3748);
  static const Color grey = Color(0xFF718096);
}

class _TextStyles {
  static final TextStyle displayMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: _PastelColors.dark,
  );

  static final TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: _PastelColors.dark,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: _PastelColors.grey,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle caption = TextStyle(
    fontSize: 11,
    color: _PastelColors.grey,
    fontWeight: FontWeight.w500,
  );
}