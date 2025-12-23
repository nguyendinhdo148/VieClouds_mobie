import 'package:flutter/material.dart';
import 'package:viejob_app/models/company_model.dart';
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
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
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
            // Logo công ty
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
            
            // Tên công ty - LÀM ĐẬM HƠN
            Expanded(
              child: Text(
                company.name,
                style: _TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700, // ĐẬM HƠN (từ 600 lên 700)
                  color: _PastelColors.dark,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Badge nổi bật - LÀM ĐẬM HƠN
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
                    fontWeight: FontWeight.w700, // ĐẬM HƠN (từ 500 lên 700)
                    color: _PastelColors.yellow.withOpacity(0.9), // ĐẬM MÀU HƠN
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
  static const Color yellow = Color(0xFFFFD166);
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

  static final TextStyle caption = TextStyle(
    fontSize: 12,
    color: _PastelColors.grey,
    fontWeight: FontWeight.w600, // THÊM ĐẬM
  );
}