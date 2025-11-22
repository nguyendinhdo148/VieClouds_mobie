import 'package:flutter/material.dart';
import 'package:viejob_app/screens/Home_tab/blog/blog_page.dart';
import 'package:viejob_app/screens/Home_tab/job/find_job.dart';
import 'package:viejob_app/screens/Home_tab/company/company_page.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tính năng nhanh',
          style: _TextStyles.displayMedium,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickActionItem(
              'Tìm việc',
              Icons.work_outline,
              _VibrantColors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FindJobScreen(initialSearch: '')),
              ),
            ),
            _buildQuickActionItem(
              'Công ty',
              Icons.business_center,
              _VibrantColors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CompanyPage()),
              ),
            ),
            _buildQuickActionItem(
              'CV của tôi',
              Icons.description,
              _VibrantColors.pink,
              () {
                // TODO: Navigate to CV screen
              },
            ),
            _buildQuickActionItem(
              'Góc chia sẻ',
              Icons.article,
              _VibrantColors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BlogPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

Widget _buildQuickActionItem(
    String title, IconData icon, Color color, VoidCallback onTap) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              Color.alphaBlend(Colors.black.withOpacity(0.1), color),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0.5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon với hiệu ứng nổi
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(-2, -2),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: _TextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );
}

}

// Màu sắc nổi bật và tươi sáng
class _VibrantColors {
  static const Color blue = Color(0xFF4361EE);
  static const Color purple = Color(0xFF7209B7);
  static const Color pink = Color(0xFFF72585);
  static const Color orange = Color(0xFFFB5607);
  static const Color green = Color(0xFF4CC9F0);
}

class _PastelColors {
  static const Color dark = Color(0xFF2D3748);
  static const Color white = Color(0xFFFFFFFF);
}

class _TextStyles {
  static final TextStyle displayMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: _PastelColors.dark,
  );

  static final TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: _PastelColors.dark,
  );
}