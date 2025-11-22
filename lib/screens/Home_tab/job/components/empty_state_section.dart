import 'package:flutter/material.dart';

class EmptyStateSection extends StatelessWidget {
  final VoidCallback onRetry;
  final bool hasSearchText;

  const EmptyStateSection({
    Key? key,
    required this.onRetry,
    required this.hasSearchText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            hasSearchText ? 'Không tìm thấy công việc phù hợp' : 'Không có công việc nào',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearchText 
                ? 'Hãy thử thay đổi bộ lọc hoặc từ khóa tìm kiếm'
                : 'Hiện chưa có công việc nào trong hệ thống',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}