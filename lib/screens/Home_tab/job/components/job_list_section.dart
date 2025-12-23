import 'package:flutter/material.dart';
import 'package:viejob_app/models/job_model.dart';
import 'package:viejob_app/models/application_model.dart';

class JobListSection extends StatelessWidget {
  final List<JobModel> jobs;
  final bool hasMore;
  final bool isLoading;
  final List<ApplicationModel> appliedJobs;
  final bool isApplying;
  final VoidCallback onLoadMore;
  final Function(JobModel) onJobTap;
  final Function(JobModel) onApply;
  final Function(JobModel) onShowStatus;
  final bool Function(String) hasAppliedToJob;
  final String Function(String) getApplyButtonText;
  final Color Function(String, bool) getApplyButtonColor;
  final bool Function(String, bool) canApply;

  const JobListSection({
    Key? key,
    required this.jobs,
    required this.hasMore,
    required this.isLoading,
    required this.appliedJobs,
    required this.isApplying,
    required this.onLoadMore,
    required this.onJobTap,
    required this.onApply,
    required this.onShowStatus,
    required this.hasAppliedToJob,
    required this.getApplyButtonText,
    required this.getApplyButtonColor,
    required this.canApply, required String searchQuery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == jobs.length) {
          return _buildLoadMoreButton();
        }
        return _buildJobItem(jobs[index]);
      },
    );
  }

  Widget _buildJobItem(JobModel job) {
    final canApplyJob = canApply(job.id, job.isActive);
    final buttonText = getApplyButtonText(job.id);
    final buttonColor = getApplyButtonColor(job.id, job.isActive);

    return GestureDetector(
      onTap: () => onJobTap(job),
      child: Container(
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.companyName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
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
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: job.isActive ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
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
              style: TextStyle(
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
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                ElevatedButton(
                  onPressed: job.isActive && !isApplying
                      ? () {
                          if (canApplyJob) {
                            onApply(job);
                          } else {
                            onShowStatus(job);
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
                  child: isApplying && canApplyJob
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
                          style: const TextStyle(
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
      ),
    );
  }

  Widget _buildJobDetail(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text.length > 15 ? '${text.substring(0, 15)}...' : text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
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
          onPressed: isLoading ? null : onLoadMore,
          child: isLoading
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
}