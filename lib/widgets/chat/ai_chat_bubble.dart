// widgets/chat/ai_chat_bubble.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:viejob_app/models/job_model.dart';
import 'package:viejob_app/screens/Home_tab/job/components/job_description_section.dart';

class AIChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final List<JobModel>? suggestedJobs;

  const AIChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.suggestedJobs,
  }) : super(key: key);

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showJobDetail(BuildContext context, JobModel job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          job.title,
          style: const TextStyle(
            fontWeight: FontWeight.w900, // ĐẬM HƠN NỮA
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: JobDescriptionSection(job: job),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đóng',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w800, // ĐẬM HƠN
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotMessage(String text, BuildContext context) {
    if (suggestedJobs != null && suggestedJobs!.isNotEmpty) {
      return _buildJobList(text, context);
    }
    
    return _buildTextWithLinks(text);
  }

  Widget _buildJobList(String text, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900, // RẤT ĐẬM
            color: Color(0xFFA8D8EA),
            fontSize: 16, // TO HƠN
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        ...suggestedJobs!.asMap().entries.map((entry) {
          final idx = entry.key;
          final job = entry.value;
          
          return GestureDetector(
            onTap: () => _showJobDetail(context, job),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFA8D8EA).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFA8D8EA).withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.12),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Logo công ty
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFAA96DA).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      image: job.companyLogo != null
                          ? DecorationImage(
                              image: NetworkImage(job.companyLogo!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      border: Border.all(
                        color: const Color(0xFFAA96DA).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: job.companyLogo == null
                        ? const Icon(
                            Icons.business,
                            color: Color(0xFFAA96DA),
                            size: 22,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),

                  // Thông tin công việc
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900, // RẤT ĐẬM
                            color: Color(0xFF1A202C),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          job.companyName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800, // ĐẬM
                            color: const Color(0xFF4A5568),
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Vị trí
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 13,
                              color: const Color(0xFFFCBAD3),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                job.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800, // ĐẬM
                                  color: const Color(0xFF4A5568),
                                  letterSpacing: -0.1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 3),

                        // Lương
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 13,
                              color: const Color(0xFFFCBAD3),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              job.formattedSalary,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900, // RẤT ĐẬM
                                color: const Color(0xFF2E7D32), // XANH ĐẬM
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Kinh nghiệm và loại công việc
                        Row(
                          children: [
                            _buildDetailChip(
                              job.experienceText,
                              Colors.blue[100]!,
                              Colors.blue[900]!, // XANH RẤT ĐẬM
                            ),
                            const SizedBox(width: 8),
                            _buildDetailChip(
                              job.jobTypeText,
                              Colors.purple[100]!,
                              Colors.purple[900]!, // TÍM RẤT ĐẬM
                            ),
                            if (job.isUrgent) ...[
                              const SizedBox(width: 8),
                              _buildDetailChip(
                                'URGENT',
                                Colors.red[100]!,
                                Colors.red[900]!, // ĐỎ RẤT ĐẬM
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status và thời gian
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: job.isActive
                              ? const Color(0xFFE8F5E9) // XANH NHẠT ĐẬM
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: job.isActive
                                ? Colors.green[300]!
                                : Colors.grey[400]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          job.isActive ? 'ĐANG TUYỂN' : 'ĐÃ ĐÓNG',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900, // RẤT ĐẬM
                            color: job.isActive
                                ? const Color(0xFF1B5E20) // XANH RẤT ĐẬM
                                : const Color(0xFF424242), // XÁM ĐẬM
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        job.timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800, // ĐẬM
                          color: const Color(0xFF4A5568),
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'XEM CHI TIẾT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900, // RẤT ĐẬM
                              color: const Color(0xFFA8D8EA),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward,
                            size: 13,
                            color: const Color(0xFFA8D8EA),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDetailChip(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: textColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800, // ĐẬM
          color: textColor,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildTextWithLinks(String text) {
    final urlRegex = RegExp(r'(https?://[^\s]+)|(/job/detail/\w+)');
    final parts = text.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((line) {
        final matches = urlRegex.allMatches(line);
        if (matches.isEmpty) {
          return Text(
            line,
            style: const TextStyle(
              fontSize: 14.5, 
              height: 1.5,
              fontWeight: FontWeight.w600, // ĐẬM HƠN
              color: Colors.black,
              letterSpacing: -0.1,
            ),
          );
        }

        final textSpans = <TextSpan>[];
        int currentIndex = 0;

        for (final match in matches) {
          if (match.start > currentIndex) {
            textSpans.add(TextSpan(
              text: line.substring(currentIndex, match.start),
              style: const TextStyle(
                fontSize: 14.5, 
                height: 1.5,
                fontWeight: FontWeight.w600, // ĐẬM
                color: Colors.black,
                letterSpacing: -0.1,
              ),
            ));
          }

          final url = match.group(0)!;
          textSpans.add(TextSpan(
            text: url,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: Color(0xFFA8D8EA),
              fontWeight: FontWeight.w700, // RẤT ĐẬM
              decoration: TextDecoration.underline,
              letterSpacing: -0.1,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchURL(url),
          ));

          currentIndex = match.end;
        }

        if (currentIndex < line.length) {
          textSpans.add(TextSpan(
            text: line.substring(currentIndex),
            style: const TextStyle(
              fontSize: 14.5, 
              height: 1.5,
              fontWeight: FontWeight.w600, // ĐẬM
              color: Colors.black,
              letterSpacing: -0.1,
            ),
          ));
        }

        return RichText(
          text: TextSpan(
            children: textSpans,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600, // ĐẬM
              letterSpacing: -0.1,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFA8D8EA).withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA8D8EA).withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Image.asset(
                  'assets/images/ai_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          if (!isUser) const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser 
                  ? const Color(0xFFA8D8EA)
                  : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(6),
                  bottomRight: isUser ? const Radius.circular(6) : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: isUser
                    ? const Color(0xFFA8D8EA).withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        height: 1.5,
                        fontWeight: FontWeight.w600, // ĐẬM
                        letterSpacing: -0.1,
                      ),
                    )
                  else
                    _buildBotMessage(message, context),
                  const SizedBox(height: 6),
                  Text(
                    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isUser 
                        ? Colors.white.withOpacity(0.9)
                        : const Color(0xFF718096),
                      fontSize: 11,
                      fontWeight: FontWeight.w700, // ĐẬM
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 10),
          if (isUser)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFA8D8EA).withOpacity(0.3),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFA8D8EA).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person, 
                size: 18, 
                color: Color(0xFF2D3748),
              ),
            ),
        ],
      ),
    );
  }
}