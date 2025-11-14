import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/secure_storage.dart';
import '../models/application_model.dart';

class ApplicationService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
    receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
  ));

  // Sử dụng singleton instance
  final SecureStorage _secureStorage = SecureStorage();

  Future<Map<String, String>> getAuthHeaders() async {
    try {
      print('🔄 Getting token from SecureStorage...');
      
      final token = await _secureStorage.getToken();
      
      print('🔐 Token retrieval result:');
      print('   - Token: ${token != null ? "PRESENT" : "NULL"}');
      
      if (token == null) {
        // Debug thêm: kiểm tra storage trực tiếp
        await _secureStorage.debugStorage();
        throw Exception('No authentication token found. Please login again.');
      }

      print('✅ Token obtained successfully, length: ${token.length}');
      
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      print('✅ Headers prepared successfully');
      return headers;
    } catch (e) {
      print('❌ Error in getAuthHeaders: $e');
      rethrow;
    }
  }

  /// Ứng tuyển công việc
  Future<Map<String, dynamic>> applyJob(String jobId) async {
    try {
      print('🚀 Starting apply job for: $jobId');
      
      // Debug: kiểm tra storage trước khi lấy headers
      print('📋 Pre-request storage check:');
      await _secureStorage.debugStorage();
      
      final headers = await getAuthHeaders();
      
      print('📤 Sending POST request to: ${ApiConfig.applyJob}/$jobId');

      final response = await _dio.post(
        '${ApiConfig.applyJob}/$jobId',
        options: Options(
          headers: headers,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );
      
      print('✅ Apply job response status: ${response.statusCode}');
      print('✅ Apply job response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.data['success'] == true) {
          return {
            'success': true,
            'message': response.data['message'] ?? 'Ứng tuyển thành công!',
          };
        }
      }

      if (response.statusCode == 401) {
        await _secureStorage.clearAll();
        return {
          'success': false,
          'message': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          'shouldLogout': true,
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Bạn đã ứng tuyển công việc này rồi.',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Ứng tuyển thất bại.',
      };

    } on DioException catch (e) {
      print('❌ Apply job Dio error: ${e.type}');
      print('❌ Error message: ${e.message}');
      print('❌ Response status: ${e.response?.statusCode}');
      print('❌ Response data: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        await _secureStorage.clearAll();
        return {
          'success': false,
          'message': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          'shouldLogout': true,
        };
      }
      
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Lỗi kết nối: ${e.message}',
      };
    } catch (e) {
      print('❌ Apply job unexpected error: $e');
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

/// Lấy danh sách công việc đã ứng tuyển - FIXED VERSION
Future<List<ApplicationModel>> getAppliedJobs() async {
  try {
    print('🚀 Starting get applied jobs');
    
    final headers = await getAuthHeaders();
    
    print('📤 Sending GET request to: ${ApiConfig.getAppliedJobs}');

    final response = await _dio.get(
      ApiConfig.getAppliedJobs,
      options: Options(
        headers: headers,
        validateStatus: (status) => status! < 500,
      ),
    );
    
    print('📦 Applied jobs response status: ${response.statusCode}');
    print('📦 FULL RESPONSE DATA: ${response.data}');
    print('📦 Response data type: ${response.data.runtimeType}');

    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> applicationsJson = response.data['applications'] ?? [];
      
      print('\n🔍 Found ${applicationsJson.length} applications in response\n');
      
      if (applicationsJson.isEmpty) {
        print('⚠️ No applications found');
      }
      
      final List<ApplicationModel> applications = [];
      
      for (int i = 0; i < applicationsJson.length; i++) {
        final appJson = applicationsJson[i];
        try {
          print('\n═══════════════════════════════════════');
          print('📍 [$i] Processing application:');
          print('   Raw JSON: $appJson');
          print('   JSON keys: ${appJson.keys.toList()}');
          print('   _id: ${appJson['_id']} (type: ${appJson['_id']?.runtimeType})');
          print('   status: ${appJson['status']}');
          print('   job field:');
          print('      - Type: ${appJson['job']?.runtimeType}');
          print('      - Value: ${appJson['job']}');
          print('      - Is String: ${appJson['job'] is String}');
          print('      - Is Map: ${appJson['job'] is Map}');
          print('      - Is List: ${appJson['job'] is List}');
          
          if (appJson['job'] is Map) {
            print('      - Map keys: ${(appJson['job'] as Map).keys.toList()}');
            print('      - Map _id: ${(appJson['job'] as Map)['_id']}');
            print('      - Map id: ${(appJson['job'] as Map)['id']}');
          }
          
          // Parse application
          print('   🔄 Calling ApplicationModel.fromJson...');
          final application = ApplicationModel.fromJson(appJson);
          
          print('   ✅ Parsed successfully');
          print('   Parsed jobId: "${application.jobId}"');
          print('   Parsed jobId length: ${application.jobId.length}');
          print('   Parsed jobId isEmpty: ${application.jobId.isEmpty}');
          print('   Parsed status: ${application.status}');
          print('═══════════════════════════════════════\n');
          
          if (application.id.isNotEmpty) {
            applications.add(application);
          }
        } catch (e) {
          print('   ❌ Error parsing: $e');
          print('   Stack: ${StackTrace.current}');
        }
      }
      
      print('\n✅ Successfully loaded ${applications.length} applied jobs');
      return applications;
    } else if (response.statusCode == 401) {
      await _secureStorage.clearAll();
      print('⚠️ Token invalid, cleared storage');
      return [];
    } else {
      print('❌ API error: ${response.data['message']}');
      return [];
    }
  } on DioException catch (e) {
    print('❌ Get applied jobs Dio error: ${e.type}');
    print('❌ Error: ${e.message}');
    print('❌ Response: ${e.response?.data}');
    
    if (e.response?.statusCode == 401) {
      await _secureStorage.clearAll();
    }
    
    return [];
  } catch (e) {
    print('❌ Get applied jobs unexpected error: $e');
    print('❌ Stack: $e');
    return [];
  }
}

  /// Kiểm tra xem user đã ứng tuyển job này chưa
  Future<bool> hasAppliedToJob(String jobId) async {
    try {
      print('🔍 Checking if applied to job: $jobId');
      
      final appliedJobs = await getAppliedJobs();
      final hasApplied = appliedJobs.any((application) => application.jobId == jobId);
      
      print('📊 Application check result: $hasApplied');
      return hasApplied;
    } catch (e) {
      print('❌ Error checking application status: $e');
      return false;
    }
  }

  /// Lấy trạng thái ứng tuyển cụ thể cho job
  Future<String?> getApplicationStatus(String jobId) async {
    try {
      final appliedJobs = await getAppliedJobs();
      final application = appliedJobs.firstWhere(
        (app) => app.jobId == jobId,
        orElse: () => ApplicationModel(
          id: '',
          jobId: '',
          applicantId: '',
          status: 'not_applied',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      final status = application.status;
      print('📊 Application status for job $jobId: $status');
      return status == 'not_applied' ? null : status;
    } catch (e) {
      print('❌ Error getting application status: $e');
      return null;
    }
  }

  /// Lấy thông tin application cụ thể cho job
  Future<ApplicationModel?> getApplicationForJob(String jobId) async {
    try {
      final appliedJobs = await getAppliedJobs();
      final application = appliedJobs.firstWhere(
        (app) => app.jobId == jobId,
        orElse: () => ApplicationModel(
          id: '',
          jobId: '',
          applicantId: '',
          status: 'not_applied',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      return application.status == 'not_applied' ? null : application;
    } catch (e) {
      print('❌ Error getting application for job: $e');
      return null;
    }
  }

  /// Lấy danh sách ứng viên của 1 job (dành cho recruiter)
  Future<Map<String, dynamic>> getApplicants(String jobId) async {
    try {
      final headers = await getAuthHeaders();
      final response = await _dio.get(
        '${ApiConfig.getApplicants}/$jobId',
        options: Options(headers: headers),
      );
      
      if (response.data['success'] == true) {
        return {
          'success': true,
          'job': response.data['job'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Không thể tải danh sách ứng viên',
        };
      }
    } on DioException catch (e) {
      print('❌ Get applicants error: $e');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Lỗi tải danh sách ứng viên',
      };
    }
  }

  /// Lấy tất cả ứng viên từ các job của recruiter
  Future<List<ApplicationModel>> getApplicantsForRecruiter() async {
    try {
      final headers = await getAuthHeaders();
      final response = await _dio.get(
        ApiConfig.getApplicantsForRecruiter,
        options: Options(headers: headers),
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> applicationsJson = response.data['applications'] ?? [];
        return applicationsJson
            .map((json) => ApplicationModel.fromJson(json))
            .toList();
      } else {
        throw Exception(response.data['message'] ?? 'Không thể tải danh sách ứng viên');
      }
    } on DioException catch (e) {
      print('❌ Get recruiter applicants error: $e');
      throw Exception(e.response?.data['message'] ?? 'Lỗi tải danh sách ứng viên');
    }
  }

  /// Cập nhật trạng thái hồ sơ (accepted / rejected / pending)
  Future<Map<String, dynamic>> updateApplicationStatus(
      String applicationId, String status) async {
    try {
      final headers = await getAuthHeaders();
      final response = await _dio.put(
        '${ApiConfig.updateApplicationStatus}/$applicationId',
        data: {'status': status},
        options: Options(headers: headers),
      );
      
      if (response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Cập nhật trạng thái thành công',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Cập nhật trạng thái thất bại',
        };
      }
    } on DioException catch (e) {
      print('❌ Update application status error: $e');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Lỗi cập nhật trạng thái',
      };
    }
  }

  /// Lấy dữ liệu tổng quan (dashboard của recruiter)
  Future<Map<String, dynamic>> getOverview() async {
    try {
      final headers = await getAuthHeaders();
      final response = await _dio.get(
        ApiConfig.getApplicationOverview,
        options: Options(headers: headers),
      );
      
      if (response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'] ?? {},
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Không thể tải dữ liệu tổng quan',
        };
      }
    } on DioException catch (e) {
      print('❌ Get overview error: $e');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Lỗi tải dữ liệu tổng quan',
      };
    }
  }
}