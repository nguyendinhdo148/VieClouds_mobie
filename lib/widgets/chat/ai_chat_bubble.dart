// widgets/chat/ai_chat_bubble.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AIChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  const AIChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    required this.timestamp,
  }) : super(key: key);

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildBotMessage(String text) {
    final lines = text.split('\n');
    
    // Kiểm tra nếu là danh sách công việc
    if (text.startsWith("Dưới đây là một số việc làm") || 
        text.startsWith("🔍 Tìm thấy") && text.contains("việc làm phù hợp")) {
      return _buildJobList(text);
    }
    
    // Render thông thường với link detection
    return _buildTextWithLinks(text);
  }

  Widget _buildJobList(String text) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final jobs = <Map<String, String>>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('**') && line.contains('tại')) {
        final jobInfo = line.replaceAll('**', '');
        final nextLine = i + 1 < lines.length ? lines[i + 1] : '';
        final urlMatch = RegExp(r'🔗 Xem chi tiết: (.+)$').firstMatch(nextLine);
        
        jobs.add({
          'info': jobInfo.trim(),
          'url': urlMatch?.group(1) ?? '',
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lines[0],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        ...jobs.asMap().entries.map((entry) {
          final idx = entry.key;
          final job = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job['info']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (job['url']!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _launchURL(job['url']!),
                    child: Row(
                      children: [
                        const Icon(Icons.link, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'Xem chi tiết',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
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
            style: const TextStyle(fontSize: 14, height: 1.4),
          );
        }

        final textSpans = <TextSpan>[];
        int currentIndex = 0;

        for (final match in matches) {
          // Thêm text trước link
          if (match.start > currentIndex) {
            textSpans.add(TextSpan(
              text: line.substring(currentIndex, match.start),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ));
          }

          // Thêm link
          final url = match.group(0)!;
          textSpans.add(TextSpan(
            text: url,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchURL(url),
          ));

          currentIndex = match.end;
        }

        // Thêm text còn lại
        if (currentIndex < line.length) {
          textSpans.add(TextSpan(
            text: line.substring(currentIndex),
            style: const TextStyle(fontSize: 14, height: 1.4),
          ));
        }

        return RichText(
          text: TextSpan(
            children: textSpans,
            style: const TextStyle(color: Colors.black87),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser 
                  ? Colors.blue[600]
                  : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    )
                  else
                    _buildBotMessage(message),
                  const SizedBox(height: 4),
                  Text(
                    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isUser ? Colors.blue[100] : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person, size: 16, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}