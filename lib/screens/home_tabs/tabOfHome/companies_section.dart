import 'package:flutter/material.dart';
import 'package:viejob_app/models/company_model.dart';
import 'package:viejob_app/screens/Home_tab/company/company_page.dart';

class CompaniesSection extends StatelessWidget {
  final String title;
  final List<CompanyModel> companies;
  final bool isFeatured;
  final bool isHorizontal;

  const CompaniesSection({
    Key? key,
    required this.title,
    required this.companies,
    this.isFeatured = false,
    this.isHorizontal = false,
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
        if (isHorizontal)
          _buildHorizontalCompaniesList()
        else
          _buildCompaniesGrid(),
      ],
    );
  }

  Widget _buildCompaniesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: companies.length,
      itemBuilder: (context, index) {
        final company = companies[index];
        return _buildCompanyCard(company);
      },
    );
  }

  Widget _buildHorizontalCompaniesList() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: companies.length,
        itemBuilder: (context, index) {
          final company = companies[index];
          return _buildHorizontalCompanyCard(company);
        },
      ),
    );
  }

  Widget _buildCompanyCard(CompanyModel company) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to company detail
        print('Tapped company: ${company.name}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _PastelColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _PastelColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                image: company.hasLogo
                    ? DecorationImage(
                        image: NetworkImage(company.logo!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: company.hasLogo
                  ? null
                  : Icon(Icons.business, color: _PastelColors.secondary, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              company.name,
              style: _TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: _PastelColors.dark,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (company.location != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 12, color: _PastelColors.accent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      company.location!,
                      style: _TextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
            if (isFeatured) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _PastelColors.yellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Nổi bật',
                  style: _TextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _PastelColors.yellow,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCompanyCard(CompanyModel company) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _PastelColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _PastelColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              image: company.hasLogo
                  ? DecorationImage(
                      image: NetworkImage(company.logo!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: company.hasLogo
                ? null
                : Icon(Icons.business, color: _PastelColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  company.name,
                  style: _TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _PastelColors.dark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (company.location != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    company.location!,
                    style: _TextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
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
    fontSize: 20,
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