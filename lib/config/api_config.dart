import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  // ✅ Base URL tự nhận diện môi trường
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000/api/v1';
    } else {
      return 'http://localhost:8000/api/v1';
    }
  }

  // ⏱ Timeout config
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // 👤 AUTH ENDPOINTS
  static const String login = '/user/login';
  static const String register = '/user/register';
  static const String logout = '/user/logout';
  static const String refreshToken = '/user/refresh-token';
  static const String getProfile = '/user/profile';
  static const String updateProfile = '/user/profile/update';
  static const String updateAvatar = '/user/profile/avatar/mobile';
  static const String forgotPassword = '/user/forgot-password';
  static const String resetPassword = '/user/reset-password';

  // 💼 JOB ENDPOINTS
  static const String getJobsByCompany = '/job/company-jobs';
  static const String getAllJobs = '/job/all-jobs';
  static const String getJobById = '/job'; // /job/:id
  static const String getRecruiterJobs = '/job/recruiter-jobs';
  static const String createJob = '/job/create-job';
  static const String updateJob = '/job/update-job'; // /job/update-job/:id
  static const String deleteJob = '/job/delete-job'; // /job/delete-job/:id
  static const String jobSuggestions = '/job/suggestions'; // ✅ ĐÚNG

  // 🏢 COMPANY ENDPOINTS
  static const String getAllCompanies = '/company/public/all';
  static const String getCompanyById = '/company'; // /company/:id
  static const String createCompany = '/company/create';
  static const String updateCompany = '/company/update-company';
  static const String deleteCompany = '/company'; // /company/:id
  static const String getCompanyDetails = '/company/detail';

  // 🧾 APPLICATION (Ứng tuyển) ENDPOINTS
  static const String applyJob = '/application/apply-job'; // + '/:id'
  static const String getAppliedJobs = '/application/applied-jobs';
  static const String getApplicants = '/application/applicants'; // + '/:id'
  static const String getApplicantsForRecruiter =
      '/application/applicantsForRecruiter';
  static const String updateApplicationStatus =
      '/application/update-application-status'; // + '/:id'
  static const String getApplicationOverview = '/application/overview';

  // 📝 BLOG ENDPOINTS
  static const String getAllBlogs = '/blog/all-blogs';
  static const String getBlogBySlug = '/blog/detail'; // + '/:slug'
  static const String getBlogUpdateById = '/blog/detail/update'; // + '/:id'
  static const String getRandomBlogs = '/blog/random-blogs';
  static const String getBlogOverview = '/blog/blogs-overview';
  static const String createBlog = '/blog/create-blog-mobie';
  static const String updateBlog = '/blog/update-blog'; // + '/:id'
  static const String deleteBlog = '/blog/delete-blog'; // + '/:id'

  // 🤖 AI ENDPOINTS
  static const String generateDescription = '/ai/generate-description';
  static const String chatWithAI = '/ai/chat_with_ai';
  static const String resumeReview = '/ai/resume-review';

  // 🧠 MBTI (Myers-Briggs Type Indicator) ENDPOINTS
  static const String mbtiBasicAnalysis = '/mbti/basic-analysis';
  static const String mbtiAdvancedAnalysis = '/mbti/advanced-analysis';

  // 🎯 MI (Multiple Intelligences - Đa trí thông minh) ENDPOINTS
  static const String miBasicAnalysis = '/mi/basic-analysis';
  static const String miAdvancedAnalysis = '/mi/advanced-analysis';
  static const String miIntelligenceTypes = '/mi/intelligence-types';

  // 👑 ADMIN ENDPOINTS (NEW)
  // User management
  static const String adminGetAllUsers = '/admin/all-users';
  static const String adminUpdateProfile = '/admin/profile/update'; // + '/:id'
  static const String adminDeleteUser = '/admin/delete-user'; // + '/:id'

  // Job management
  static const String adminCreateJob = '/admin/create-job';
  static const String adminGetAllJobs = '/admin/all-jobs';
  static const String adminUpdateJob = '/admin/update-job'; // + '/:id'
  static const String adminApproveJob = '/admin/approve-job'; // + '/:id'
  static const String adminDeleteJob = '/admin/delete-job'; // + '/:id'

  // Company management
  static const String adminCreateCompany = '/admin/company/create';
  static const String adminGetAllCompanies = '/admin/all-companies';
  static const String adminUpdateCompany = '/admin/company'; // + '/:id'
  static const String adminDeleteCompany = '/admin/company'; // + '/:id'

  // Blog management
  static const String adminApproveBlog = '/admin/approve-blog'; // + '/:id'
  // Thêm vào class ApiConfig trong config/api_config.dart
  static const String adminGetAllBlogs = '/admin/all-blogs';

  // Overview
  static const String adminGetOverview = '/admin/overview';
}