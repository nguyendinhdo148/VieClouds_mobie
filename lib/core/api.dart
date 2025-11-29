import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../config/api_config.dart';
import 'secure_storage.dart';
import 'package:flutter/material.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  ApiClient._internal() {
    _setupDio();
  }

  late final Dio _dio;
  final SecureStorage _storage = SecureStorage();
  BuildContext? _context;

  void setContext(BuildContext ctx) {
    _context = ctx;
    print('🎯 ApiClient context set');
  }

  void _setupDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Debug storage trước khi request
        await _storage.debugStorage();
        
        // GỬI TOKEN NẾU CÓ - BACKEND ĐÃ CÓ TOKEN THẬT
        final token = await _storage.getToken();
        final sessionActive = await _storage.isSessionActive();
        
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('✅ Token added to request: ${token.substring(0, 30)}...');
        } else if (sessionActive) {
          print('🔐 Using session authentication');
        } else {
          print('❌ No authentication available');
        }

        // Đặc biệt quan trọng với multipart
        if (options.data is FormData) {
          options.headers['Content-Type'] = 'multipart/form-data';
          print('📁 Multipart form data detected');
        }

        print('🚀 [Request] ${options.method} ${options.uri}');
        print('📋 Headers: ${options.headers}');
        return handler.next(options);
      },
      
      onResponse: (response, handler) {
        print('✅ [Response] ${response.statusCode} ${response.requestOptions.uri}');
        print('📦 Response data: ${response.data}');
        return handler.next(response);
      },
      
      onError: (DioException error, handler) async {
        print('❌ [Error] ${error.response?.statusCode} ${error.requestOptions.uri}');
        print('📦 Error data: ${error.response?.data}');

        if (error.response?.statusCode == 401) {
          print('🔐 401 Unauthorized - Clearing storage and redirecting to login');
          await _storage.clearAll();

          if (_context != null && _context!.mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                GoRouter.of(_context!).go('/login');
                print('🔄 Redirected to login screen (GoRouter)');
              } catch (e) {
                print('❌ Navigation error: $e');
                _fallbackNavigation();
              }
            });
          }
        }
        return handler.next(error);
      },
    ));
  }
void _fallbackNavigation() {
  try {
    if (_context != null && _context!.mounted) {
      GoRouter.of(_context!).go('/login');
      print('🔄 Fallback navigation to login (GoRouter)');
    }
  } catch (e) {
    print('❌ Fallback navigation also failed: $e');
  }
}
  Future<Response> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(String endpoint, dynamic data) async {
    try {
      return await _dio.post(endpoint, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(String endpoint, dynamic data) async {
    try {
      return await _dio.put(endpoint, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(String endpoint) async {
    try {
      return await _dio.delete(endpoint);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final errorData = e.response!.data;

      switch (statusCode) {
        case 400:
          return Exception(errorData['message'] ?? 'Yêu cầu không hợp lệ');
        case 401:
          return Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
        case 403:
          return Exception('Bạn không có quyền truy cập');
        case 404:
          return Exception('Không tìm thấy tài nguyên');
        case 500:
          return Exception('Lỗi máy chủ: ${errorData['message'] ?? 'Vui lòng thử lại sau'}');
        default:
          return Exception(errorData['message'] ?? 'Có lỗi xảy ra');
      }
    } else {
      return Exception('Lỗi kết nối: ${e.message}');
    }
  }

  void dispose() {
    _dio.close();
  }
}