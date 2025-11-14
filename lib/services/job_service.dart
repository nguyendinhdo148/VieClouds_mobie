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
  Future<Map<String, dynamic>> getRecruiterJobs({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await _api.get(
        ApiConfig.getRecruiterJobs,
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

  // Tạo công việc mới (chỉ recruiter)
  Future<Map<String, dynamic>> createJob(Map<String, dynamic> jobData) async {
    try {
      final response = await _api.post(ApiConfig.createJob, jobData);
      final responseData = response.data;

      if (responseData['success'] == true) {
        return {
          'success': true,
          'job': JobModel.fromJson(responseData['job'] ?? responseData['data']),
          'message': responseData['message'] ?? 'Tạo công việc thành công',
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Tạo công việc thất bại',
        };
      }
    } catch (e) {
      print('❌ Create job error: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // Cập nhật công việc (chỉ recruiter)
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
        'companyId': companyId, // QUAN TRỌNG: query parameter
        'page': page.toString(),
        'limit': limit.toString(),
      };

      print('🚀 Fetching jobs by company with endpoint: ${ApiConfig.getJobsByCompany}');
      print('🚀 Query params: $queryParams');
      
      // Sử dụng endpoint getJobsByCompany với query parameter companyId
      final response = await _api.get(
        ApiConfig.getJobsByCompany, // '/job/company-jobs'
        queryParameters: queryParams,
      );

      final responseData = response.data;
      print('📦 Company jobs response: ${response.statusCode}');
      print('📦 Company jobs data: $responseData');

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
}