// services/job_service.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../config/api_config.dart';
import '../core/api.dart';
import '../models/job_model.dart';

class JobService {
  final ApiClient _api = ApiClient();
  
  // Lấy tất cả công việc (public)
  Future<Map<String, dynamic>> getAllJobs({
    String? search,
    String? category,
    String? location,
    String? salaryRange,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null && category.isNotEmpty && category != 'Tất cả') {
        queryParams['category'] = category;
      }
      if (location != null && location.isNotEmpty && location != 'Tất cả địa điểm') {
        queryParams['location'] = location;
      }
      if (salaryRange != null && salaryRange.isNotEmpty && salaryRange != 'Tất cả mức lương') {
        final range = _parseSalaryRange(salaryRange);
        if (range != null) {
          queryParams['minSalary'] = range['min'].toString();
          queryParams['maxSalary'] = range['max'].toString();
        }
      }

      print('🚀 Fetching jobs with params: $queryParams');
      
      final response = await _api.get(
        ApiConfig.getAllJobs,
        queryParameters: queryParams,
      );

      final responseData = response.data;
      print('📦 Jobs response: ${response.statusCode}');

      if (responseData['success'] == true) {
        final List<dynamic> jobsData = responseData['jobs'] ?? [];
        final List<JobModel> jobs = jobsData
            .map((job) => JobModel.fromJson(job))
            .toList();

        return {
          'success': true,
          'jobs': jobs,
          'total': responseData['total'] ?? 0,
          'page': responseData['page'] ?? page,
          'totalPages': responseData['totalPages'] ?? 1,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Không thể tải danh sách công việc',
          'jobs': [],
          'total': 0,
        };
      }
    } catch (e) {
      print('❌ Get all jobs error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
        'jobs': [],
        'total': 0,
      };
    }
  }

  // Lấy chi tiết công việc theo ID
  Future<Map<String, dynamic>> getJobById(String jobId) async {
    try {
      final response = await _api.get('${ApiConfig.getJobById}/$jobId');
      final responseData = response.data;

      if (responseData['success'] == true) {
        return {
          'success': true,
          'job': JobModel.fromJson(responseData['job'] ?? responseData['data']),
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Không thể tải thông tin công việc',
        };
      }
    } catch (e) {
      print('❌ Get job by id error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // Lấy công việc của recruiter (cần authentication)
  // Trong getRecruiterJobs() của JobService, thêm debug:
Future<Map<String, dynamic>> getRecruiterJobs({
  int page = 1,
  int limit = 10,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    print('🚀 Calling API: ${ApiConfig.getRecruiterJobs}');
    print('🚀 Query params: $queryParams');
    
    final response = await _api.get(
      ApiConfig.getRecruiterJobs,
      queryParameters: queryParams,
    );

    final responseData = response.data;
    print('📦 Recruiter jobs API response status: ${response.statusCode}');
    print('📦 Recruiter jobs API response data: $responseData');

    if (responseData['success'] == true) {
      final List<dynamic> jobsData = responseData['jobs'] ?? [];
      final List<JobModel> jobs = jobsData
          .map((job) => JobModel.fromJson(job))
          .toList();

      print('✅ Recruiter jobs loaded: ${jobs.length} jobs');
      print('✅ Total count from API: ${responseData['total']}');
      
      return {
        'success': true,
        'jobs': jobs,
        'total': responseData['total'] ?? 0,
        'page': responseData['page'] ?? page,
        'totalPages': responseData['totalPages'] ?? 1,
      };
    } else {
      print('❌ API returned error: ${responseData['message']}');
      return {
        'success': false,
        'error': responseData['message'] ?? 'Không thể tải công việc của bạn',
        'jobs': [],
        'total': 0,
      };
    }
  } catch (e) {
    print('❌ Get recruiter jobs error: $e');
    return {
      'success': false,
      'error': e.toString().replaceAll('Exception: ', ''),
      'jobs': [],
      'total': 0,
    };
  }
}
// services/job_service.dart - Cập nhật createJob method
Future<Map<String, dynamic>> createJob(Map<String, dynamic> jobData) async {
  try {
    print('🚀 [JOB SERVICE] Creating job...');
    print('   Endpoint: ${ApiConfig.createJob}');
    print('   Data: $jobData');
    
    final response = await _api.post(ApiConfig.createJob, jobData);
    final responseData = response.data;
    
    print('📦 [JOB SERVICE] Response status: ${response.statusCode}');
    print('📦 [JOB SERVICE] Response data: $responseData');

    if (responseData['success'] == true) {
      print('✅ [JOB SERVICE] Job created successfully');
      return {
        'success': true,
        'job': JobModel.fromJson(responseData['job'] ?? responseData['data']),
        'message': responseData['message'] ?? 'Tạo công việc thành công',
      };
    } else {
      print('❌ [JOB SERVICE] API Error: ${responseData['message']}');
      return {
        'success': false,
        'error': responseData['message'] ?? 'Tạo công việc thất bại',
      };
    }
  } catch (e) {
    print('❌ [JOB SERVICE] Exception: $e');
    return {
      'success': false,
      'error': e.toString().replaceAll('Exception: ', ''),
    };
  }
} // Cập nhật công việc (chỉ recruiter)
  Future<Map<String, dynamic>> updateJob(String jobId, Map<String, dynamic> jobData) async {
    try {
      final response = await _api.put('${ApiConfig.updateJob}/$jobId', jobData);
      final responseData = response.data;

      if (responseData['success'] == true) {
        return {
          'success': true,
          'job': JobModel.fromJson(responseData['job'] ?? responseData['data']),
          'message': responseData['message'] ?? 'Cập nhật công việc thành công',
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Cập nhật công việc thất bại',
        };
      }
    } catch (e) {
      print('❌ Update job error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // Xóa công việc (chỉ recruiter)
  Future<Map<String, dynamic>> deleteJob(String jobId) async {
    try {
      final response = await _api.delete('${ApiConfig.deleteJob}/$jobId');
      final responseData = response.data;

      if (responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Xóa công việc thành công',
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Xóa công việc thất bại',
        };
      }
    } catch (e) {
      print('❌ Delete job error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // Gợi ý công việc (có rate limiting)
  Future<Map<String, dynamic>> getJobSuggestions(String query) async {
    try {
      final response = await _api.get(
        ApiConfig.jobSuggestions,
        queryParameters: {'q': query},
      );

      final responseData = response.data;

      if (responseData['success'] == true) {
        return {
          'success': true,
          'suggestions': responseData['suggestions'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Không thể tải gợi ý',
          'suggestions': [],
        };
      }
    } catch (e) {
      print('❌ Get job suggestions error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
        'suggestions': [],
      };
    }
  }

  // Tìm kiếm công việc
  Future<Map<String, dynamic>> searchJobs({
    required String query,
    String? category,
    String? location,
    String? salaryRange,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'search': query,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null && category.isNotEmpty && category != 'Tất cả') {
        queryParams['category'] = category;
      }
      if (location != null && location.isNotEmpty && location != 'Tất cả địa điểm') {
        queryParams['location'] = location;
      }
      if (salaryRange != null && salaryRange.isNotEmpty && salaryRange != 'Tất cả mức lương') {
        final range = _parseSalaryRange(salaryRange);
        if (range != null) {
          queryParams['minSalary'] = range['min'].toString();
          queryParams['maxSalary'] = range['max'].toString();
        }
      }

      final response = await _api.get(
        ApiConfig.getAllJobs,
        queryParameters: queryParams,
      );

      final responseData = response.data;

      if (responseData['success'] == true) {
        final List<dynamic> jobsData = responseData['jobs'] ?? [];
        final List<JobModel> jobs = jobsData
            .map((job) => JobModel.fromJson(job))
            .toList();

        return {
          'success': true,
          'jobs': jobs,
          'total': responseData['total'] ?? 0,
          'page': responseData['page'] ?? page,
          'totalPages': responseData['totalPages'] ?? 1,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Tìm kiếm thất bại',
          'jobs': [],
          'total': 0,
        };
      }
    } catch (e) {
      print('❌ Search jobs error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
        'jobs': [],
        'total': 0,
      };
    }
  }

  // Lấy công việc theo công ty
  Future<Map<String, dynamic>> getJobsByCompany({
    required String companyId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'companyId': companyId,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      print('🚀 Fetching jobs by company with endpoint: ${ApiConfig.getJobsByCompany}');
      
      final response = await _api.get(
        ApiConfig.getJobsByCompany,
        queryParameters: queryParams,
      );

      final responseData = response.data;
      print('📦 Company jobs response: ${response.statusCode}');

      if (responseData['success'] == true) {
        final List<dynamic> jobsData = responseData['jobs'] ?? [];
        final List<JobModel> jobs = jobsData
            .map((job) => JobModel.fromJson(job))
            .toList();

        return {
          'success': true,
          'jobs': jobs,
          'total': responseData['total'] ?? 0,
          'page': responseData['page'] ?? page,
          'totalPages': responseData['totalPages'] ?? 1,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Không thể tải danh sách công việc của công ty',
          'jobs': [],
          'total': 0,
        };
      }
    } catch (e) {
      print('❌ Get company jobs error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
        'jobs': [],
        'total': 0,
      };
    }
  }

  // Lấy công việc theo category
  Future<Map<String, dynamic>> getJobsByCategory(String category, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'category': category,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await _api.get(
        ApiConfig.getAllJobs,
        queryParameters: queryParams,
      );

      final responseData = response.data;

      if (responseData['success'] == true) {
        final List<dynamic> jobsData = responseData['jobs'] ?? [];
        final List<JobModel> jobs = jobsData
            .map((job) => JobModel.fromJson(job))
            .toList();

        return {
          'success': true,
          'jobs': jobs,
          'total': responseData['total'] ?? 0,
          'page': responseData['page'] ?? page,
          'totalPages': responseData['totalPages'] ?? 1,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Không thể tải công việc theo danh mục',
          'jobs': [],
          'total': 0,
        };
      }
    } catch (e) {
      print('❌ Get jobs by category error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
        'jobs': [],
        'total': 0,
      };
    }
  }

Future<Map<String, dynamic>> getRecruiterCandidates({
  int page = 1,
  int limit = 10,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    print('🚀 Calling API: ${ApiConfig.getApplicantsForRecruiter}');
    print('🚀 Query params: $queryParams');
    
    final response = await _api.get(
      ApiConfig.getApplicantsForRecruiter,
      queryParameters: queryParams,
    );

    final responseData = response.data;
    print('📦 Recruiter candidates API response status: ${response.statusCode}');
    
    // Debug chi tiết response
    print('📦 Response keys: ${responseData.keys.toList()}');
    print('📦 Has success: ${responseData.containsKey('success')}');
    print('📦 Success value: ${responseData['success']}');

    if (responseData['success'] == true) {
      // Kiểm tra nhiều tên trường có thể có
      final List<dynamic> candidatesData = 
          responseData['applicants'] ?? 
          responseData['applications'] ?? 
          responseData['data'] ?? 
          [];
      
      print('✅ Recruiter candidates loaded: ${candidatesData.length} candidates');
      print('✅ Total from API: ${responseData['total']}');
      
      // Debug first candidate để xem cấu trúc
      if (candidatesData.isNotEmpty) {
        print('📋 First candidate structure:');
        print('   - Keys: ${candidatesData[0].keys.toList()}');
        print('   - Has user field: ${candidatesData[0].containsKey('user')}');
        print('   - Has job field: ${candidatesData[0].containsKey('job')}');
        print('   - Has status field: ${candidatesData[0].containsKey('status')}');
      }
      
      return {
        'success': true,
        'candidates': candidatesData,
        'total': responseData['total'] ?? candidatesData.length,
        'page': responseData['page'] ?? page,
        'totalPages': responseData['totalPages'] ?? 1,
      };
    } else {
      print('❌ API returned error: ${responseData['message']}');
      return {
        'success': false,
        'error': responseData['message'] ?? 'Không thể tải danh sách ứng viên',
        'candidates': [],
        'total': 0,
      };
    }
  } catch (e) {
    print('❌ Get recruiter candidates error: $e');
    return {
      'success': false,
      'error': e.toString().replaceAll('Exception: ', ''),
      'candidates': [],
      'total': 0,
    };
  }
}

/// Lấy số lượng ứng viên của recruiter (cho Dashboard) - Tối ưu hơn
Future<Map<String, dynamic>> getRecruiterCandidateCount() async {
  try {
    print('📊 Fetching recruiter candidate count...');
    
    // Gọi API lấy ứng viên với limit nhỏ để chỉ lấy count
    final result = await getRecruiterCandidates(page: 1, limit: 5);
    
    print('📦 Recruiter candidates response: ${result['success']}');
    
    if (result['success'] == true) {
      // Lấy total từ API hoặc đếm từ list
      final int totalFromAPI = result['total'] ?? 0;
      final int countFromList = (result['candidates'] as List).length;
      
      // Ưu tiên dùng total từ API
      final int actualCount = totalFromAPI > 0 ? totalFromAPI : countFromList;
      
      print('📊 Candidates - API total: $totalFromAPI');
      print('📊 Candidates - List count: $countFromList');
      print('📊 Candidates - Final count: $actualCount');
      
      return {
        'success': true,
        'count': actualCount,
        'candidates': result['candidates'],
      };
    } else {
      print('⚠️ Candidate count failed: ${result['error']}');
      return {
        'success': false,
        'error': result['error'] ?? 'Không thể đếm ứng viên',
        'count': 0,
        'candidates': [],
      };
    }
  } catch (e) {
    print('❌ Get recruiter candidate count error: $e');
    return {
      'success': false,
      'error': e.toString().replaceAll('Exception: ', ''),
      'count': 0,
      'candidates': [],
    };
  }
}

/// Lấy dashboard stats với debug chi tiết
  Future<Map<String, dynamic>> getRecruiterDashboardStats() async {
    try {
      print('📊 Fetching recruiter dashboard stats...');
      
      // Get job count
      final jobCountResult = await getRecruiterJobCount();
      
      if (jobCountResult['success'] == true) {
        return {
          'success': true,
          'jobCount': jobCountResult['count'],
          'candidateCount': 0, // TODO: Replace with actual API
          'messageCount': 0,   // TODO: Replace with actual API
          'viewCount': 0,      // TODO: Replace with actual API
        };
      } else {
        return {
          'success': false,
          'error': jobCountResult['error'] ?? 'Không thể lấy thống kê',
          'jobCount': 0,
          'candidateCount': 0,
          'messageCount': 0,
          'viewCount': 0,
        };
      }
    } catch (e) {
      print('❌ Get dashboard stats error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
        'jobCount': 0,
        'candidateCount': 0,
        'messageCount': 0,
        'viewCount': 0,
      };
    }
  }
// Lấy số lượng công việc của recruiter (tối ưu, chỉ lấy total)
Future<Map<String, dynamic>> getRecruiterJobCount() async {
  try {
    print('📊 Fetching recruiter job count...');
    
    // Gọi API lấy công việc của recruiter với limit lớn để lấy tất cả
    final result = await getRecruiterJobs(page: 1, limit: 100);
    
    print('📦 Recruiter jobs response: ${result['success']}');
    
    if (result['success'] == true) {
      // Nếu API trả về total thì dùng, nếu không thì đếm từ list jobs
      final List<JobModel> jobs = result['jobs'] ?? [];
      final int countFromList = jobs.length;
      final int countFromTotal = result['total'] ?? 0;
      
      // Ưu tiên dùng total từ API, nếu không có thì đếm từ list
      final int actualCount = countFromTotal > 0 ? countFromTotal : countFromList;
      
      print('📊 Count from list: $countFromList');
      print('📊 Count from total: $countFromTotal');
      print('📊 Actual count: $actualCount');
      
      return {
        'success': true,
        'count': actualCount,
        'jobs': jobs,
      };
    } else {
      return {
        'success': false,
        'error': result['error'] ?? 'Không thể đếm công việc',
        'count': 0,
        'jobs': [],
      };
    }
  } catch (e) {
    print('❌ Get recruiter job count error: $e');
    return {
      'success': false,
      'error': e.toString().replaceAll('Exception: ', ''),
      'count': 0,
      'jobs': [],
    };
  }
}

  /// Lấy hoạt động gần đây (recent activities)
  Future<Map<String, dynamic>> getRecentActivities({
    int limit = 5,
  }) async {
    try {
      final jobsResult = await getRecruiterJobs(page: 1, limit: limit);
      
      if (jobsResult['success'] == true) {
        final List<JobModel> jobs = jobsResult['jobs'] ?? [];
        
        final activities = jobs.map((job) {
          return {
            'id': job.id,
            'type': 'job_created',
            'title': 'Đăng tin tuyển dụng mới',
            'description': job.title,
            'time': _formatTimeAgo(job.createdAt),
            'icon': Iconsax.briefcase,
            'color': Colors.blue,
          };
        }).toList();
        
        return {
          'success': true,
          'activities': activities,
        };
      } else {
        return {
          'success': false,
          'error': jobsResult['error'] ?? 'Không thể lấy hoạt động',
          'activities': [],
        };
      }
    } catch (e) {
      print('❌ Get recent activities error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
        'activities': [],
      };
    }
  }

  // Helper method to parse salary range text to numeric values
  Map<String, double>? _parseSalaryRange(String salaryRange) {
    switch (salaryRange) {
      case 'Dưới 10 triệu':
        return {'min': 0, 'max': 10000000};
      case '10 - 15 triệu':
        return {'min': 10000000, 'max': 15000000};
      case '15 - 20 triệu':
        return {'min': 15000000, 'max': 20000000};
      case '20 - 30 triệu':
        return {'min': 20000000, 'max': 30000000};
      case 'Trên 30 triệu':
        return {'min': 30000000, 'max': 100000000};
      default:
        return null;
    }
  }

  /// Helper method to format time ago
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}