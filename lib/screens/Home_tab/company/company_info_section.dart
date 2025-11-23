import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/company_model.dart';

class CompanyInfoSection extends StatelessWidget {
  final CompanyModel company;

  const CompanyInfoSection({
    Key? key,
    required this.company,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với Logo và Thông tin cơ bản
          _buildCompanyHeader(),
          
          // Thông tin chi tiết công ty
          if (company.description != null && company.description!.isNotEmpty)
            _buildCompanyDescription(),
          
          // Thông tin liên hệ và pháp lý
          _buildContactAndLegalInfo(),
          
          // Thống kê công ty
          _buildCompanyStats(),
        ],
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.white],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              image: company.hasLogo
                  ? DecorationImage(
                      image: NetworkImage(company.logo!),
                      fit: BoxFit.cover,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: company.hasLogo
                ? null
                : Icon(Icons.business, color: Colors.blue[300], size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue[900],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Slug/ID công ty
                if (company.slug != null)
                  Text(
                    'ID: ${company.slug!}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // Địa chỉ
                if (company.displayLocation != null)
                  _buildInfoRow(
                    Icons.location_on,
                    company.displayLocation!,
                  ),
                
                // Lĩnh vực hoạt động
                if (company.field != null && company.field!.isNotEmpty)
                  _buildInfoRow(
                    Icons.category,
                    company.field!,
                  ),
                
                // User quản lý (nếu có)
                if (company.userName != null)
                  _buildInfoRow(
                    Icons.person,
                    'Quản lý: ${company.userName!}',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDescription() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Giới thiệu công ty',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            company.description!,
            style: GoogleFonts.inter(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildContactAndLegalInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin liên hệ & Pháp lý',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          
          // Website
          if (company.formattedWebsite != null)
            _buildClickableInfoRow(
              Icons.language,
              'Website',
              company.formattedWebsite!,
              onTap: () => _launchWebsite(company.formattedWebsite!),
            ),
          
          // Địa chỉ chi tiết
          if (company.address != null && company.address != company.location)
            _buildInfoRow(
              Icons.home_work,
              'Địa chỉ trụ sở: ${company.address!}',
            ),
          
          // Mã số thuế
          if (company.taxCode != null)
            _buildInfoRow(
              Icons.receipt_long,
              'Mã số thuế: ${company.taxCode!}',
            ),
          
          // Giấy phép kinh doanh
          if (company.hasBusinessLicense)
            _buildClickableInfoRow(
              Icons.assignment,
              'Giấy phép kinh doanh',
              company.businessLicense!,
              onTap: () => _launchWebsite(company.businessLicense!),
            ),
        ],
      ),
    );
  }

  Widget _buildCompanyStats() {
    final stats = company.companyStats;
    if (stats.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin công ty',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stats.map((stat) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Text(
                  stat,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          
          // Ngày tạo/cập nhật
          const SizedBox(height: 16),
          if (company.createdAt != null || company.updatedAt != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildDateInfo(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableInfoRow(IconData icon, String label, String value, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildDateInfo() {
    String info = '';
    if (company.createdAt != null) {
      info += 'Tạo: ${_formatDate(company.createdAt!)}';
    }
    if (company.updatedAt != null) {
      if (info.isNotEmpty) info += ' • ';
      info += 'Cập nhật: ${_formatDate(company.updatedAt!)}';
    }
    return info;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _launchWebsite(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
      }
    } catch (e) {
      print('Could not launch $url: $e');
    }
  }
}