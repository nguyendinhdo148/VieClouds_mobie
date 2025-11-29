
import '../config/api_config.dart';
import '../core/api.dart';

class CompanyService {
  final ApiClient _api = ApiClient();

  // Lấy tất cả công ty - PUBLIC endpoint
  Future<Map<String, dynamic>> getAllCompanies() async {
    try {
      print('🚀 Fetching public companies...');
      
      // Sử dụng endpoint public mới
      final response = await _api.get(ApiConfig.getAllCompanies);
      
      final responseData = response.data;
      print('📦 Companies response: ${response.statusCode}');
      print('📦 Companies data: $responseData');

      if (responseData['success'] == true) {
        return {
          'success': true,
          'companies': responseData['companies'] ?? responseData['data'] ?? [],
          'total': responseData['total'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Không thể tải danh sách công ty',
          'companies': [],
          'total': 0,
        };
      }
    } catch (e) {
      print('❌ Get companies error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
        'companies': [],
        'total': 0,
      };
    }
  }

  // Lấy chi tiết công ty theo ID - VẪN cần authenticated
  Future<Map<String, dynamic>> getCompanyById(String companyId) async {
    try {
      final response = await _api.get('${ApiConfig.getCompanyById}/$companyId');
      final responseData = response.data;

      if (responseData['success'] == true) {
        return {
          'success': true,
          'company': responseData['company'] ?? responseData['data'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Không thể tải thông tin công ty',
        };
      }
    } catch (e) {
      print('❌ Get company by id error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }
}