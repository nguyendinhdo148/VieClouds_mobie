import 'package:flutter/material.dart';
import 'package:viejob_app/models/company_model.dart';
import 'package:viejob_app/screens/Home_tab/company/company_page.dart';
import 'package:viejob_app/screens/Home_tab/company/jobByCompany.dart';

class CompaniesSection extends StatelessWidget {
  final String title;
  final List<CompanyModel> companies;
  final bool isFeatured;

  const CompaniesSection({
    Key? key,
    required this.title,
    required this.companies,
    this.isFeatured = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: _TextStyles.displayMedium,
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CompanyPage()),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: Text(
                'Xem tất cả',
                style: _TextStyles.bodyMedium.copyWith(
                  color: _PastelColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCompaniesGrid(context),
      ],
    );
  }

  Widget _buildCompaniesGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Tăng lên 3 cột để hiển thị nhiều hơn
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9, // Điều chỉnh tỷ lệ cho đẹp
      ),
      itemCount: companies.length,
      itemBuilder: (context, index) {
        final company = companies[index];
        return _buildCompanyCard(company, context);
      },
    );
  }

  Widget _buildCompanyCard(CompanyModel company, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobByCompanyScreen(company: company),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _PastelColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _PastelColors.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo công ty - làm nổi bật hơn
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _PastelColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                image: company.logo != null && company.logo!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(company.logo!),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: _PastelColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: company.logo != null && company.logo!.isNotEmpty
                  ? null
                  : Icon(
                      Icons.business,
                      color: _PastelColors.primary,
                      size: 28,
                    ),
            ),
            const SizedBox(height: 12),
            
            // Tên công ty - chỉ hiện tên
            Expanded(
              child: Text(
                company.name,
                style: _TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _PastelColors.dark,
                  fontSize: 13, // Nhỏ hơn một chút
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Badge nổi bật (nếu có)
            if (isFeatured) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _PastelColors.yellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Nổi bật',
                  style: _TextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _PastelColors.yellow.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PastelColors {
  static const Color primary = Color(0xFFA8D8EA);
  static const Color secondary = Color(0xFFAA96DA);
  static const Color accent = Color(0xFFFCBAD3);
  static const Color yellow = Color(0xFFFFD166);
  static const Color white = Color(0xFFFFFFFF);
  static const Color dark = Color(0xFF2D3748);
  static const Color grey = Color(0xFF718096);
}

class _TextStyles {
  static final TextStyle displayMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: _PastelColors.dark,
  );

  static final TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: _PastelColors.dark,
  );

  static final TextStyle caption = TextStyle(
    fontSize: 12,
    color: _PastelColors.grey,
  );
}