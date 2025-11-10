import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api.dart';
import '../core/secure_storage.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class AuthService {
  final ApiClient _api = ApiClient();
  final SecureStorage _storage = SecureStorage();

  /// ===== LOGIN =====
  Future<Map<String, dynamic>> login(String email, String password, String role) async {
    try {
      print('🔐 Attempting login for: $email');
      
      final response = await _api.post(ApiConfig.login, {
        'email': email.trim(),
        'password': password,
        'role': role,
      });

      final responseData = response.data;
      print('📦 Login response: $responseData');

      if (responseData['success'] == true) {
        final userData = responseData['user'];

        // Lưu user data
        await _storage.saveUserData(jsonEncode(userData));
        
        // QUAN TRỌNG: LƯU TOKEN TỪ RESPONSE
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];
        
        if (accessToken != null) {
          await _storage.saveToken(accessToken);
          print('✅ Token saved: ${accessToken.substring(0, 30)}...');
        }
        
        if (refreshToken != null) {
          await _storage.saveRefreshToken(refreshToken);
          print('✅ Refresh token saved');
        }
        
        await _storage.setSessionActive();

        // Debug storage sau khi login
        await _storage.debugStorage();

        return {
          'success': true,
          'user': UserModel.fromJson(userData),
          'token': accessToken,
        };
      }

      return {
        'success': false,
        'error': responseData['message'] ?? 'Đăng nhập thất bại',
      };
    } catch (e) {
      print('❌ Login error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  
  /// ===== GET CURRENT USER =====
  Future<UserModel?> getCurrentUser() async {
    try {
      final userData = await _storage.getUserData();
      if (userData != null) {
        return UserModel.fromJson(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// ===== CHECK LOGIN =====
  Future<bool> isLoggedIn() async {
    // Kiểm tra cả token và session
    final token = await _storage.getToken();
    final userData = await _storage.getUserData();
    final sessionActive = await _storage.isSessionActive();
    final loggedIn = (token != null || sessionActive) && userData != null;
    print('🔐 Is logged in: $loggedIn');
    return loggedIn;
  }

Future<void> logout(BuildContext context) async {
  try {
    print('🚪 Starting logout process...');
    _api.setContext(context);
    final response = await _api.post(ApiConfig.logout, {});
    print('✅ Logout API called successfully: ${response.data}');
  } on DioException catch (e) {
    if (e.response?.statusCode != 401) {
      print('⚠️ Logout API error: $e');
    } else {
      print('ℹ️ Token expired during logout - continuing with cleanup');
    }
  } catch (e) {
    print('⚠️ Other logout error: $e');
  } finally {
    await _storage.clearAll();
    print('🗑️ Storage cleared');
    // Use GoRouter for navigation to avoid page-based route error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        try {
          // Use GoRouter for navigation
          // Requires: import 'package:go_router/go_router.dart';
          GoRouter.of(context).go('/login');
          print('🔄 Navigated to login screen using GoRouter');
        } catch (e) {
          print('❌ Navigation error: $e');
        }
      }
    });
  }
}

  /// ===== UPDATE AVATAR =====
  Future<Map<String, dynamic>> updateAvatar(File imageFile) async {
  try {
    print('🖼️ Starting avatar upload...');

    // Kiểm tra đăng nhập
    final userLoggedIn = await isLoggedIn();
    if (!userLoggedIn) {
      return {
        'success': false,
        'error': 'Chưa đăng nhập. Vui lòng đăng nhập lại.',
      };
    }

    // Chuẩn bị FormData
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });

    print('📤 Uploading avatar to: ${ApiConfig.updateAvatar}');
    final response = await _api.put(ApiConfig.updateAvatar, formData);

    final responseData = response.data;
    print('📦 Avatar upload response: $responseData');

    if (responseData['success'] == true) {
      // Cập nhật user local
      await _storage.saveUserData(jsonEncode(responseData['user']));
      print('✅ Avatar updated successfully');
      return {
        'success': true,
        'user': UserModel.fromJson(responseData['user']),
      };
    }

    return {
      'success': false,
      'error': responseData['message'] ?? 'Cập nhật ảnh thất bại',
    };
  } catch (e) {
    print('❌ Avatar upload error: $e');
    return {
      'success': false,
      'error': e.toString().replaceAll('Exception: ', ''),
    };
  }
}
/// ===== UPDATE PROFILE =====
Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
  try {
    print('📝 Updating profile...');

    final response = await _api.put(ApiConfig.updateProfile, profileData);
    final responseData = response.data;

    if (responseData['success'] == true) {
      // Update local user data
      await _storage.saveUserData(jsonEncode(responseData['user']));
      
      print('✅ Profile updated successfully');
      return {
        'success': true,
        'user': UserModel.fromJson(responseData['user']),
      };
    }

    return {
      'success': false,
      'error': responseData['message'] ?? 'Cập nhật thất bại',
    };
  } catch (e) {
    print('❌ Update profile error: $e');
    return {
      'success': false,
      'error': e.toString().replaceAll('Exception: ', ''),
    };
  }
}
/// ===== UPDATE PROFILE WITH FILE =====
Future<Map<String, dynamic>> updateProfileWithFile({
  required Map<String, dynamic> profileData,
  required File? file,
}) async {
  try {
    print('📝 Updating profile with file...');

    FormData formData = FormData.fromMap(profileData);
    
    if (file != null) {
      formData.files.add(MapEntry(
        'file',
        await MultipartFile.fromFile(
          file.path,
          filename: 'resume_${DateTime.now().millisecondsSinceEpoch}.pdf',
        ),
      ));
    }

    final response = await _api.put(ApiConfig.updateProfile, formData);
    final responseData = response.data;

    if (responseData['success'] == true) {
      await _storage.saveUserData(jsonEncode(responseData['user']));
      print('✅ Profile updated successfully with file');
      return {
        'success': true,
        'user': UserModel.fromJson(responseData['user']),
      };
    }

    return {
      'success': false,
      'error': responseData['message'] ?? 'Cập nhật thất bại',
    };
  } catch (e) {
    print('❌ Update profile with file error: $e');
    return {
      'success': false,
      'error': e.toString().replaceAll('Exception: ', ''),
    };
  }
}

/// ===== REGISTER WITH FILE =====
/// ===== REGISTER WITH FILE =====
Future<Map<String, dynamic>> registerWithFile({
  required String fullname,
  required String email,
  required String password,
  required String phoneNumber,
  required String role,
  required File? file,
}) async {
  try {
    print('📝 Starting registration with file...');
    
    FormData formData = FormData.fromMap({
      'fullname': fullname.trim(),
      'email': email.trim(),
      'password': password,
      'phoneNumber': phoneNumber,
      'role': role,
    });

    if (file != null) {
      print('📎 Adding file to form data: ${file.path}');
      formData.files.add(MapEntry(
        'file',
        await MultipartFile.fromFile(
          file.path,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}',
        ),
      ));
    }

    print('🚀 Sending registration request to: ${ApiConfig.register}');
    final response = await _api.post(ApiConfig.register, formData);

    final responseData = response.data;
    print('📦 Registration response: ${response.statusCode}');
    print('📦 Response data: $responseData');

    if (responseData['success'] == true) {
      print('✅ Registration successful for email: $email');

      // THÊM TIMEOUT CHO AUTO LOGIN
      final autoLoginResult = await autoLoginAfterRegister(
        email: email,
        password: password,
        role: role,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        return {
          'success': false,
          'error': 'Auto login timeout',
        };
      });

      if (autoLoginResult['success'] == true) {
        print('✅ Auto login successful, user is now fully logged in');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Đăng ký và đăng nhập thành công',
          'user': autoLoginResult['user'],
          'token': autoLoginResult['token'],
        };
      } else {
        print('⚠️ Auto login failed, but registration was successful');
        
        // CHỈ LƯU THÔNG TIN CƠ BẢN, KHÔNG SET SESSION ACTIVE
        // để tránh nhầm lẫn trạng thái đã login
        final basicUserData = {
          'email': email,
          'fullname': fullname,
          'phoneNumber': phoneNumber,
          'role': role,
          'isTemporary': true, // ← ĐÁNH DẤU ĐÂY LÀ DATA TẠM THỜI
        };
        await _storage.saveUserData(jsonEncode(basicUserData));
        // KHÔNG gọi setSessionActive() vì chưa thực sự login

        return {
          'success': true,
          'message': '${responseData['message']} Vui lòng đăng nhập thủ công.',
          'warning': autoLoginResult['error'] ?? 'Auto login failed',
          'needsManualLogin': true, // ← THÊM FLAG ĐỂ UI XỬ LÝ
        };
      }
    } else {
      print('❌ Registration failed: ${responseData['message']}');
      return {
        'success': false,
        'error': responseData['message'] ?? 'Đăng ký thất bại',
      };
    }
  } catch (e) {
    print('❌ Register with file error: $e');
    return {
      'success': false,
      'error': e.toString().replaceAll('Exception: ', ''),
    };
  }
}
/// ===== AUTO LOGIN AFTER REGISTER =====
Future<Map<String, dynamic>> autoLoginAfterRegister({
  required String email,
  required String password,
  required String role,
}) async {
  try {
    print('🔄 Attempting auto login after register...');
    
    final loginResult = await login(email, password, role);
    
    if (loginResult['success'] == true) {
      print('✅ Auto login successful');
      return {
        'success': true,
        'user': loginResult['user'],
        'token': loginResult['token'],
      };
    } else {
      print('❌ Auto login failed: ${loginResult['error']}');
      return {
        'success': false,
        'error': 'Đăng ký thành công nhưng không thể tự động đăng nhập',
      };
    }
  } catch (e) {
    print('❌ Auto login error: $e');
    return {
      'success': false,
      'error': 'Đăng ký thành công nhưng có lỗi khi đăng nhập',
    };
  }
}
  /// ===== KIỂM TRA ADMIN EMAIL =====
  bool isAdminEmail(String email) {
    final emailNamePart = email.split('@')[0].toLowerCase();
    return emailNamePart.contains('admin');
  }
}