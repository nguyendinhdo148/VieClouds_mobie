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
  static const String jobSuggestions = '/job/suggestions';

  // 🏢 COMPANY ENDPOINTS
  static const String getAllCompanies = '/company/public/all';
  static const String getCompanyById = '/company'; // /company/:id
  static const String createCompany = '/company/create';
  static const String updateCompany = '/company/update-company';
  static const String deleteCompany = '/company'; // /company/:id

  // 🧾 APPLICATION (Ứng tuyển) ENDPOINTS
  static const String applyJob = '/application/apply-job'; // + '/:id'
  static const String getAppliedJobs = '/application/applied-jobs';
  static const String getApplicants = '/application/applicants'; // + '/:id'
  static const String getApplicantsForRecruiter =
      '/application/applicantsForRecruiter';
  static const String updateApplicationStatus =
      '/application/update-application-status'; // + '/:id'
  static const String getApplicationOverview = '/application/overview';
}
