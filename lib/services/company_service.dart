// services/company_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/secure_storage.dart';

class CompanyService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
    receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
  ));

  final SecureStorage _secureStorage = SecureStorage();

  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final token = await _secureStorage.getToken();
      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
    } catch (e) {
      print('❌ Error in getAuthHeaders: $e');
      rethrow;
    }
  }

  // Lấy tất cả công ty - PUBLIC endpoint
  Future<Map<String, dynamic>> getAllCompanies() async {
    try {
      print('🚀 Fetching public companies...');
      
      final response = await _dio.get(
        ApiConfig.getAllCompanies,
        options: Options(validateStatus: (status) => status! < 500),
      );
      
      final responseData = response.data;
      print('📦 Companies response: ${response.statusCode}');

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

  // Lấy công ty của recruiter (GET /company)
  Future<Map<String, dynamic>> getRecruiterCompanies() async {
    try {
      print('🚀 Fetching recruiter companies...');
      
      final headers = await _getAuthHeaders();
      
      final response = await _dio.get(
        '/company', // Đúng theo API của web: /company (không phải /company/recruiter-companies)
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
      );
      
      final responseData = response.data;
      print('📦 Recruiter companies response: ${response.statusCode}');
      print('📦 Response data: $responseData');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'companies': responseData['companies'] ?? responseData['data'] ?? [],
          'total': responseData['total'] ?? 0,
        };
      } else if (response.statusCode == 401) {
        await _secureStorage.clearAll();
        return {
          'success': false,
          'error': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
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
      print('❌ Get recruiter companies error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
        'companies': [],
        'total': 0,
      };
    }
  }

  // Tạo công ty mới (POST /company/create) với file upload
  Future<Map<String, dynamic>> createCompany(Map<String, dynamic> companyData) async {
    try {
      print('🚀 Creating company...');
      
      final token = await _secureStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No authentication token found. Please login again.',
        };
      }

      // Tạo FormData cho file upload
      final formData = FormData();
      
      // Thêm các trường text
      formData.fields.addAll([
        MapEntry('name', companyData['name'] ?? ''),
        MapEntry('description', companyData['description'] ?? ''),
        MapEntry('location', companyData['location'] ?? ''),
        MapEntry('address', companyData['address'] ?? ''),
        MapEntry('website', companyData['website'] ?? ''),
        MapEntry('taxCode', companyData['taxCode'] ?? ''),
      ]);
      
      // Thêm file logo nếu có
      if (companyData['logo'] is File) {
        final logoFile = companyData['logo'] as File;
        formData.files.add(MapEntry(
          'logo',
          await MultipartFile.fromFile(logoFile.path, filename: 'logo.jpg'),
        ));
      }
      
      // Thêm file business license nếu có
      if (companyData['businessLicense'] is File) {
        final licenseFile = companyData['businessLicense'] as File;
        formData.files.add(MapEntry(
          'businessLicense',
          await MultipartFile.fromFile(licenseFile.path, filename: 'business_license.jpg'),
        ));
      }

      final response = await _dio.post(
        ApiConfig.createCompany,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            // Content-Type sẽ tự động được set thành multipart/form-data
          },
          validateStatus: (status) => status! < 500,
        ),
      );
      
      final responseData = response.data;
      print('📦 Create company response: ${response.statusCode}');
      print('📦 Response data: $responseData');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (responseData['success'] == true) {
          return {
            'success': true,
            'company': responseData['company'] ?? responseData['data'],
            'message': responseData['message'] ?? 'Tạo công ty thành công',
          };
        }
      }

      if (response.statusCode == 401) {
        await _secureStorage.clearAll();
        return {
          'success': false,
          'error': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        };
      }

      return {
        'success': false,
        'error': responseData['message'] ?? 'Tạo công ty thất bại',
      };

    } on DioException catch (e) {
      print('❌ Create company Dio error: ${e.type}');
      print('❌ Error: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        await _secureStorage.clearAll();
        return {
          'success': false,
          'error': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        };
      }
      
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Lỗi: ${e.message}',
      };
    } catch (e) {
      print('❌ Create company unexpected error: $e');
      return {
        'success': false,
        'error': 'Lỗi: $e',
      };
    }
  }

  // Cập nhật công ty (PUT /company/update-company/:id) với file upload
  Future<Map<String, dynamic>> updateCompany({
    required String companyId,
    required Map<String, dynamic> companyData,
  }) async {
    try {
      print('🚀 Updating company: $companyId');
      
      final token = await _secureStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No authentication token found. Please login again.',
        };
      }

      // Tạo FormData cho file upload
      final formData = FormData();
      
      // Thêm các trường text
      formData.fields.addAll([
        MapEntry('name', companyData['name'] ?? ''),
        MapEntry('description', companyData['description'] ?? ''),
        MapEntry('location', companyData['location'] ?? ''),
        MapEntry('address', companyData['address'] ?? ''),
        MapEntry('website', companyData['website'] ?? ''),
        MapEntry('taxCode', companyData['taxCode'] ?? ''),
      ]);
      
      // Thêm file logo nếu có
      if (companyData['logo'] is File) {
        final logoFile = companyData['logo'] as File;
        formData.files.add(MapEntry(
          'logo',
          await MultipartFile.fromFile(logoFile.path, filename: 'logo.jpg'),
        ));
      }
      
      // Thêm file business license nếu có
      if (companyData['businessLicense'] is File) {
        final licenseFile = companyData['businessLicense'] as File;
        formData.files.add(MapEntry(
          'businessLicense',
          await MultipartFile.fromFile(licenseFile.path, filename: 'business_license.jpg'),
        ));
      }

      final response = await _dio.put(
        '${ApiConfig.updateCompany}/$companyId',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            // Content-Type sẽ tự động được set thành multipart/form-data
          },
          validateStatus: (status) => status! < 500,
        ),
      );
      
      final responseData = response.data;
      print('📦 Update company response: ${response.statusCode}');
      print('📦 Response data: $responseData');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'company': responseData['company'] ?? responseData['data'],
          'message': responseData['message'] ?? 'Cập nhật công ty thành công',
        };
      }

      if (response.statusCode == 401) {
        await _secureStorage.clearAll();
        return {
          'success': false,
          'error': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        };
      }

      return {
        'success': false,
        'error': responseData['message'] ?? 'Cập nhật công ty thất bại',
      };

    } on DioException catch (e) {
      print('❌ Update company Dio error: ${e.type}');
      print('❌ Error: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        await _secureStorage.clearAll();
        return {
          'success': false,
          'error': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        };
      }
      
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Lỗi: ${e.message}',
      };
    } catch (e) {
      print('❌ Update company unexpected error: $e');
      return {
        'success': false,
        'error': 'Lỗi: $e',
      };
    }
  }

  // Xóa công ty (DELETE /company/:id)
  Future<Map<String, dynamic>> deleteCompany(String companyId) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await _dio.delete(
        '${ApiConfig.deleteCompany}/$companyId',
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
      );
      
      final responseData = response.data;
      print('📦 Delete company response: ${response.statusCode}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Xóa công ty thành công',
        };
      } else if (response.statusCode == 401) {
        await _secureStorage.clearAll();
        return {
          'success': false,
          'error': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Xóa công ty thất bại',
        };
      }
    } on DioException catch (e) {
      print('❌ Delete company Dio error: ${e.type}');
      print('❌ Error: ${e.message}');
      
      if (e.response?.statusCode == 401) {
        await _secureStorage.clearAll();
        return {
          'success': false,
          'error': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        };
      }
      
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Lỗi: ${e.message}',
      };
    } catch (e) {
      print('❌ Delete company unexpected error: $e');
      return {
        'success': false,
        'error': 'Lỗi: $e',
      };
    }
  }

  // Kiểm tra recruiter đã có công ty chưa
  Future<bool> hasCompany() async {
    try {
      final result = await getRecruiterCompanies();
      if (result['success'] == true) {
        final companies = result['companies'] as List;
        return companies.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('❌ Check has company error: $e');
      return false;
    }
  }
}