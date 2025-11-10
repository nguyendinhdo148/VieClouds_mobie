import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Home_tab/find_job.dart'; // THÊM IMPORT
import '../Home_tab/company_page.dart'; // THÊM IMPORT
class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm công việc, công ty...',
                hintStyle: GoogleFonts.inter(color: Colors.grey),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Quick Actions
          Text(
            'Tính năng nhanh',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildQuickAction(
                'Tìm việc', 
                Icons.work, 
                Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FindJobScreen()),
                  );
                },
              ),
              _buildQuickAction('CV của tôi', Icons.description, Colors.green),
              _buildQuickAction('Ứng tuyển', Icons.send, Colors.orange),
              _buildQuickAction(
                'Công ty', 
                Icons.business, Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CompanyPage()),
                  );
                },
              ),
              _buildQuickAction('Lịch phỏng vấn', Icons.calendar_today, Colors.red),
              _buildQuickAction('Tin tức', Icons.article, Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}