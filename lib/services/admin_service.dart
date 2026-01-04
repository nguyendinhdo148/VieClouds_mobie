// services/admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../core/secure_storage.dart';

class AdminService {
  final String baseUrl = ApiConfig.baseUrl;
  final SecureStorage _secureStorage = SecureStorage();

  // Helper method để lấy token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Quản lý Users
  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      
      final uri = Uri.parse('$baseUrl${ApiConfig.adminGetAllUsers}')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'users': data['users'] ?? [],
          'total': data['total'] ?? 0,
          'page': data['page'] ?? page,
          'pages': data['pages'] ?? 1,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get users: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting users: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl${ApiConfig.adminUpdateProfile}/$userId');
      
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(profileData),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': data['user'],
          'message': data['message'] ?? 'User updated successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to update user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error updating user: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl${ApiConfig.adminDeleteUser}/$userId');
      
      final response = await http.delete(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'User deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to delete user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error deleting user: $e',
      };
    }
  }

  // 2. Quản lý Jobs
  Future<Map<String, dynamic>> getAllJobs({
    int page = 1,
    int limit = 20,
    String? status,
    String? approval,
    String? search,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null && status.isNotEmpty && status != 'all') 'status': status,
        if (approval != null && approval.isNotEmpty && approval != 'all') 'approval': approval,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      
      final uri = Uri.parse('$baseUrl${ApiConfig.adminGetAllJobs}')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'jobs': data['jobs'] ?? [],
          'total': data['total'] ?? 0,
          'page': data['page'] ?? page,
          'pages': data['pages'] ?? 1,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get jobs: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting jobs: $e',
      };
    }
  }

  Future<Map<String, dynamic>> approveJob(String jobId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl${ApiConfig.adminApproveJob}/$jobId');
      
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode({
          'approval': 'approved',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'job': data['job'],
          'message': data['message'] ?? 'Job approved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to approve job',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error approving job: $e',
      };
    }
  }

  Future<Map<String, dynamic>> rejectJob(String jobId, String reason) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl${ApiConfig.adminApproveJob}/$jobId');
      
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode({
          'approval': 'rejected',
          'approvalNote': reason,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'job': data['job'],
          'message': data['message'] ?? 'Job rejected successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to reject job',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error rejecting job: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteJob(String jobId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl${ApiConfig.adminDeleteJob}/$jobId');
      
      final response = await http.delete(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Job deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to delete job',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error deleting job: $e',
      };
    }
  }

  // 3. Quản lý Companies
  Future<Map<String, dynamic>> getAllCompanies({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      
      final uri = Uri.parse('$baseUrl${ApiConfig.adminGetAllCompanies}')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'companies': data['companies'] ?? [],
          'total': data['total'] ?? 0,
          'page': data['page'] ?? page,
          'pages': data['pages'] ?? 1,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get companies: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting companies: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteCompany(String companyId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl${ApiConfig.adminDeleteCompany}/$companyId');
      
      final response = await http.delete(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Company deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to delete company',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error deleting company: $e',
      };
    }
  }

  // 4. Dashboard Overview
  Future<Map<String, dynamic>> getOverview() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl${ApiConfig.adminGetOverview}');
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final overviewData = data['data'] ?? {};
        
        return {
          'success': true,
          'data': overviewData,
        };
      } else {
        return {
          'success': false,
          'error': 'Lỗi API: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi kết nối: $e',
      };
    }
  }

  // 5. Thống kê tổng quan
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final overviewResult = await getOverview();
      
      if (overviewResult['success'] == true) {
        final data = overviewResult['data'] ?? {};
        
        return {
          'success': true,
          'totalUsers': data['totalUsers'] ?? 0,
          'totalJobs': data['totalJobs'] ?? 0,
          'totalCompanies': data['totalCompanies'] ?? 0,
          'totalBlogs': data['totalBlogs'] ?? 0,
        };
      }
      
      return {
        'success': false,
        'error': overviewResult['error'] ?? 'Không thể lấy dữ liệu thống kê',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi kết nối: $e',
      };
    }
  }
// services/admin_service.dart
// Sửa lại phần quản lý Blogs:

// 4. Quản lý Blogs
Future<Map<String, dynamic>> getAllBlogs({
  int page = 1,
  int limit = 20,
  String? status,
  String? approval,
  String? search,
  String? category,
}) async {
  try {
    final headers = await _getHeaders();
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null && status.isNotEmpty && status != 'all') 'status': status,
      if (approval != null && approval.isNotEmpty && approval != 'all') 'approval': approval,
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty && category != 'all') 'category': category,
    };
    
    // Sửa lại: gọi /blog/all-blogs giống web React
    final uri = Uri.parse('$baseUrl${ApiConfig.getAllBlogs}')
        .replace(queryParameters: queryParams);
    
    print('Calling getAllBlogs API: $uri'); // Debug
    
    final response = await http.get(uri, headers: headers);
    
    print('GetAllBlogs response status: ${response.statusCode}'); // Debug
    print('GetAllBlogs response body: ${response.body}'); // Debug
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'blogs': data['blogs'] ?? [],
        'total': data['total'] ?? 0,
        'page': data['page'] ?? page,
        'pages': data['pages'] ?? 1,
      };
    } else {
      return {
        'success': false,
        'error': 'Failed to get blogs: ${response.statusCode}',
      };
    }
  } catch (e) {
    print('GetAllBlogs error: $e'); // Debug
    return {
      'success': false,
      'error': 'Error getting blogs: $e',
    };
  }
}

Future<Map<String, dynamic>> approveBlog(String blogId) async {
  try {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl${ApiConfig.adminApproveBlog}/$blogId');
    
    print('Approve blog API: $uri'); // Debug
    
    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode({
        'approval': 'approved',
      }),
    );
    
    print('Approve blog response: ${response.statusCode}'); // Debug
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'blog': data['blog'],
        'message': data['message'] ?? 'Blog approved successfully',
      };
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? 'Failed to approve blog',
      };
    }
  } catch (e) {
    print('Approve blog error: $e'); // Debug
    return {
      'success': false,
      'error': 'Error approving blog: $e',
    };
  }
}

Future<Map<String, dynamic>> rejectBlog(String blogId, String reason) async {
  try {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl${ApiConfig.adminApproveBlog}/$blogId');
    
    print('Reject blog API: $uri with reason: $reason'); // Debug
    
    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode({
        'approval': 'rejected',
        'approvalNote': reason,
      }),
    );
    
    print('Reject blog response: ${response.statusCode}'); // Debug
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'blog': data['blog'],
        'message': data['message'] ?? 'Blog rejected successfully',
      };
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? 'Failed to reject blog',
      };
    }
  } catch (e) {
    print('Reject blog error: $e'); // Debug
    return {
      'success': false,
      'error': 'Error rejecting blog: $e',
    };
  }
}

Future<Map<String, dynamic>> deleteBlog(String blogId) async {
  try {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl${ApiConfig.deleteBlog}/$blogId');
    
    print('Delete blog API: $uri'); // Debug
    
    final response = await http.delete(uri, headers: headers);
    
    print('Delete blog response: ${response.statusCode}'); // Debug
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': data['message'] ?? 'Blog deleted successfully',
      };
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? 'Failed to delete blog',
      };
    }
  } catch (e) {
    print('Delete blog error: $e'); // Debug
    return {
      'success': false,
      'error': 'Error deleting blog: $e',
    };
  }
}
}