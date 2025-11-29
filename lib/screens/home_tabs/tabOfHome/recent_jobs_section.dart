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
  bool _isLoadingApplications = true;

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
      setState(() {
        _isLoadingApplications = false;
      });
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
                  fontWeight: FontWeight.w700, // ĐẬM HƠN
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
            itemCount: (widget.jobs.length / 2).ceil(),
            onPageChanged: (page) {
              setState(() {
                _currentJobPage = page;
              });
            },
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * 2;
              final endIndex = startIndex + 2;
              final jobs = widget.jobs.sublist(
                startIndex,
                endIndex < widget.jobs.length ? endIndex : widget.jobs.length,
              );

              return ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: jobs
                    .map((job) =>
                        Padding(padding: const EdgeInsets.only(bottom: 8.0), child: _buildJobCard(job)))
                    .toList(),
              );
            },
          ),
        ),

        const SizedBox(height: 12),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        (widget.jobs.length / 2).ceil(),
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
                          fontWeight: FontWeight.w700), // ĐẬM HƠN
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(job.companyName,
                      style: _TextStyles.bodySmall.copyWith(
                        color: _PastelColors.grey,
                        fontWeight: FontWeight.w600, // ĐẬM HƠN
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
                              fontWeight: FontWeight.w600, // ĐẬM HƠN
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
                            fontWeight: FontWeight.w700, // ĐẬM HƠN
                            color: Colors.green[700], // MÀU XANH ĐẬM ĐỂ NỔI BẬT
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: job.isActive
                        ? _PastelColors.yellow.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.isActive ? 'Đang tuyển' : 'Đã đóng',
                    style: _TextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700, // ĐẬM HƠN
                      color: job.isActive
                          ? Colors.green[700] // MÀU XANH ĐẬM CHO "ĐANG TUYỂN"
                          : Colors.grey[700], // MÀU XÁM ĐẬM CHO "ĐÃ ĐÓNG"
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(job.timeAgo,
                    style: _TextStyles.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600, // ĐẬM HƠN
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
        title: Text(job.title, style: const TextStyle(
          fontWeight: FontWeight.w700, // ĐẬM HƠN
          fontSize: 18,
        )),
        content: SizedBox(width: double.maxFinite, child: JobDescriptionSection(job: job)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600, // ĐẬM HƠN
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
            child: Text(buttonText, style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700, // ĐẬM HƠN
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
        title: const Text('Xác nhận ứng tuyển', style: TextStyle(
          fontWeight: FontWeight.w700, // ĐẬM HƠN
          fontSize: 16,
        )),
        content: Text("Bạn có chắc muốn ứng tuyển vào ${job.title}?",
          style: const TextStyle(
            fontWeight: FontWeight.w600, // ĐẬM HƠN
          )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600, // ĐẬM HƠN
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
            child: const Text('Xác nhận ứng tuyển', style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700, // ĐẬM HƠN
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
                fontWeight: FontWeight.w600, // ĐẬM HƠN
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
            fontWeight: FontWeight.w700, // ĐẬM HƠN
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
    fontWeight: FontWeight.w800, // ĐẬM HƠN (từ 700 lên 800)
    color: _PastelColors.dark,
  );

  static final TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: _PastelColors.dark,
    fontWeight: FontWeight.w600, // THÊM ĐẬM
  );

  static final TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: _PastelColors.grey,
    fontWeight: FontWeight.w500, // THÊM ĐẬM
  );

  static final TextStyle caption = TextStyle(
    fontSize: 11,
    color: _PastelColors.grey,
    fontWeight: FontWeight.w500, // THÊM ĐẬM
  );
}