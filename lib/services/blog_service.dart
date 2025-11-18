import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/blog_model.dart';
import '../config/api_config.dart';
import '../core/api.dart';

class BlogService {
  final ApiClient _api = ApiClient();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // Create blog
  Future<ApiResponse<BlogModel>> createBlog({
    required String title,
    required String content,
    required String category,
    List<String>? tags,
    String? imagePath,
  }) async {
    try {
      var formData = FormData.fromMap({
        'title': title,
        'content': content,
        'category': category,
        if (tags != null && tags.isNotEmpty)
          'tags': tags.join(', '),
        if (imagePath != null)
          'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _api.post(ApiConfig.createBlog, formData);
      final jsonResponse = response.data;

      if (jsonResponse['success'] == true) {
        final blog = BlogModel.fromJson(jsonResponse['newBlog']);
        return ApiResponse(
          success: true,
          data: blog,
          message: jsonResponse['message'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to create blog',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error creating blog: $e',
      );
    }
  }

  // Get blog by slug
  Future<ApiResponse<BlogModel>> getBlogBySlug(String slug) async {
    try {
      final response = await _api.get(
        '${ApiConfig.getBlogBySlug}/$slug',
      );
      final jsonResponse = response.data;

      if (jsonResponse['success'] == true) {
        final blog = BlogModel.fromJson(jsonResponse['blog']);
        return ApiResponse(
          success: true,
          data: blog,
          message: jsonResponse['message'],
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Blog not found',
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to get blog',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error getting blog: $e',
      );
    }
  }

  // Get blog by ID for update
  Future<ApiResponse<BlogModel>> getBlogUpdateById(String id) async {
    try {
      final response = await _api.get(
        '${ApiConfig.getBlogUpdateById}/$id',
      );
      final jsonResponse = response.data;

      if (jsonResponse['success'] == true) {
        final blog = BlogModel.fromJson(jsonResponse['blog']);
        return ApiResponse(
          success: true,
          data: blog,
          message: jsonResponse['message'],
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Blog not found',
        );
      } else if (response.statusCode == 403) {
        return ApiResponse(
          success: false,
          message: 'Not authorized to update this blog',
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to get blog',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error getting blog: $e',
      );
    }
  }

  // Get all blogs
  Future<ApiResponse<BlogListResponse>> getAllBlogs() async {
    try {
      print('🚀 Fetching all blogs from: ${ApiConfig.getAllBlogs}');
      
      final response = await _api.get(ApiConfig.getAllBlogs);
      final jsonResponse = response.data;

      print('📦 Response status: ${response.statusCode}');
      print('📦 Response data type: ${jsonResponse.runtimeType}');
      print('📦 Response success: ${jsonResponse['success']}');

      if (jsonResponse['success'] == true) {
        final blogsData = jsonResponse['blogs'];
        
        print('🔍 Blogs data type: ${blogsData.runtimeType}');
        print('🔍 Blogs count: ${blogsData is List ? blogsData.length : "N/A"}');
        
        if (blogsData is! List) {
          print('❌ ERROR: blogs field is not a List! Type: ${blogsData.runtimeType}');
          print('❌ Blogs data: $blogsData');
          return ApiResponse(
            success: false,
            message: 'Invalid blogs data format from server',
          );
        }

        final List<BlogModel> blogs = [];
        
        for (int i = 0; i < blogsData.length; i++) {
          try {
            final blogJson = blogsData[i];
            
            print('   📍 Blog $i:');
            print('      - Type: ${blogJson.runtimeType}');
            print('      - Keys: ${blogJson is Map ? (blogJson as Map).keys.toList() : "N/A"}');
            
            // Validate before parsing
            if (blogJson is! Map<String, dynamic>) {
              print('      ❌ ERROR: Blog $i is not a Map! Type: ${blogJson.runtimeType}');
              print('      ❌ Value: $blogJson');
              continue;
            }
            
            final blog = BlogModel.fromJson(blogJson);
            blogs.add(blog);
            
            print('      ✅ Successfully parsed: ${blog.title}');
          } catch (e) {
            print('      ❌ Error parsing blog $i: $e');
            print('      ❌ Blog data: ${blogsData[i]}');
            // Continue with next blog instead of failing
            continue;
          }
        }
        
        print('✅ Successfully loaded ${blogs.length} blogs');
        
        return ApiResponse(
          success: true,
          data: BlogListResponse(
            blogs: blogs,
            blogsCount: jsonResponse['blogsCount'] ?? blogs.length,
          ),
          message: jsonResponse['message'],
        );
      } else if (response.statusCode == 404) {
        print('⚠️ No blogs found (404)');
        return ApiResponse(
          success: false,
          message: 'No blogs found',
        );
      } else {
        print('❌ API error: ${jsonResponse['message']}');
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to get blogs',
        );
      }
    } catch (e) {
      print('❌ Unexpected error in getAllBlogs: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      
      return ApiResponse(
        success: false,
        message: 'Error getting blogs: $e',
      );
    }
  }

  // Get blog overview by author
  Future<ApiResponse<BlogOverviewResponse>> getBlogOverview() async {
    try {
      final response = await _api.get(ApiConfig.getBlogOverview);
      final jsonResponse = response.data;

      if (jsonResponse['success'] == true) {
        final data = jsonResponse['data'];
        
        final blogs = (data['blogs'] as List)
            .map((blogJson) => BlogModel.fromJson(blogJson))
            .toList();

        return ApiResponse(
          success: true,
          data: BlogOverviewResponse(
            blogs: blogs,
            totalBlogs: data['totalBlogs'],
            yesterdayTotalBlogs: data['yesterdayTotalBlogs'],
            totalViews: data['totalViews'],
            yesterdayViews: data['yesterdayViews'],
            pendingBlogs: data['pendingBlogs'],
            yesterdayPendingBlogs: data['yesterdayPendingBlogs'],
            approvedBlogs: data['approvedBlogs'],
            yesterdayApprovedBlogs: data['yesterdayApprovedBlogs'],
          ),
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to get blog overview',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error getting blog overview: $e',
      );
    }
  }

  // Get random blogs
  Future<ApiResponse<List<BlogModel>>> getRandomBlogs({String? currentSlug}) async {
    try {
      final params = <String, String>{};
      if (currentSlug != null) {
        params['currentSlug'] = currentSlug;
      }

      final response = await _api.get(
        ApiConfig.getRandomBlogs,
        queryParameters: params,
      );
      final jsonResponse = response.data;

      if (jsonResponse['success'] == true) {
        final blogs = (jsonResponse['randomBlogs'] as List)
            .map((blogJson) => BlogModel.fromJson(blogJson))
            .toList();
        
        return ApiResponse(
          success: true,
          data: blogs,
          message: jsonResponse['message'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to get random blogs',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error getting random blogs: $e',
      );
    }
  }

  // Update blog
  Future<ApiResponse<BlogModel>> updateBlog({
    required String id,
    required String title,
    required String content,
    required String category,
    List<String>? tags,
    String? imagePath,
  }) async {
    try {
      var formData = FormData.fromMap({
        'title': title,
        'content': content,
        'category': category,
        if (tags != null && tags.isNotEmpty)
          'tags': tags.join(', '),
        if (imagePath != null)
          'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _api.put(
        '${ApiConfig.updateBlog}/$id',
        formData,
      );
      final jsonResponse = response.data;

      if (jsonResponse['success'] == true) {
        final blog = BlogModel.fromJson(jsonResponse['updatedBlog']);
        return ApiResponse(
          success: true,
          data: blog,
          message: jsonResponse['message'],
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Blog not found',
        );
      } else if (response.statusCode == 403) {
        return ApiResponse(
          success: false,
          message: 'Not authorized to update this blog',
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to update blog',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error updating blog: $e',
      );
    }
  }

  // Delete blog
  Future<ApiResponse<void>> deleteBlog(String id) async {
    try {
      final response = await _api.delete(
        '${ApiConfig.deleteBlog}/$id',
      );
      final jsonResponse = response.data;

      if (jsonResponse['success'] == true) {
        return ApiResponse(
          success: true,
          message: jsonResponse['message'],
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Blog not found',
        );
      } else if (response.statusCode == 403) {
        return ApiResponse(
          success: false,
          message: 'Not authorized to delete this blog',
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to delete blog',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error deleting blog: $e',
      );
    }
  }
}

// Response models
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    this.message = '',
    this.data,
  });
}

class BlogListResponse {
  final List<BlogModel> blogs;
  final int blogsCount;

  BlogListResponse({
    required this.blogs,
    required this.blogsCount,
  });
}

class BlogOverviewResponse {
  final List<BlogModel> blogs;
  final int totalBlogs;
  final int yesterdayTotalBlogs;
  final int totalViews;
  final int yesterdayViews;
  final int pendingBlogs;
  final int yesterdayPendingBlogs;
  final int approvedBlogs;
  final int yesterdayApprovedBlogs;

  BlogOverviewResponse({
    required this.blogs,
    required this.totalBlogs,
    required this.yesterdayTotalBlogs,
    required this.totalViews,
    required this.yesterdayViews,
    required this.pendingBlogs,
    required this.yesterdayPendingBlogs,
    required this.approvedBlogs,
    required this.yesterdayApprovedBlogs,
  });
}