// lib/screens/Home_tab/job/components/job_description_section.dart
import 'package:flutter/material.dart';
import '../../../../models/job_model.dart';

class JobDescriptionSection extends StatelessWidget {
  final JobModel job;

  const JobDescriptionSection({
    Key? key,
    required this.job,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInfoRow('Công ty:', job.companyName),
          _buildInfoRow('Địa điểm:', job.location),
          _buildInfoRow('Mức lương:', job.formattedSalary),
          _buildInfoRow('Loại hình:', job.jobTypeText),
          _buildInfoRow('Kinh nghiệm:', job.experienceText),
          _buildInfoRow('Vị trí:', job.positionTitle),
          const SizedBox(height: 16),
          _buildSectionTitle('Mô tả công việc:'),
          _buildSectionContent(job.description),
          const SizedBox(height: 8),
          if (job.requirements.isNotEmpty) ...[
            _buildSectionTitle('Yêu cầu:'),
            ...job.requirements.map((req) => _buildBulletPoint(req)).toList(),
          ],
          if (job.benefits.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSectionTitle('Phúc lợi:'),
            ...job.benefits.map((benefit) => _buildBulletPoint(benefit)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
        height: 1.4,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 14),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}