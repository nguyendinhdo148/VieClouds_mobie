import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
class ApiConfig {
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

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Auth endpoints
  static const String login = '/user/login';
  static const String register = '/user/register';
  static const String logout = '/user/logout';
  static const String refreshToken = '/user/refresh-token';
  static const String getProfile = '/user/profile';
  static const String updateProfile = '/user/profile/update';
  static const String updateAvatar = '/user/profile/avatar/mobile';
  static const String forgotPassword = '/user/forgot-password';
  static const String resetPassword = '/user/reset-password';

  // Job endpoints
  static const String getAllJobs = '/job/all-jobs';
  static const String getJobById = '/job'; // /job/:id
  static const String getRecruiterJobs = '/job/recruiter-jobs';
  static const String createJob = '/job/create-job';
  static const String updateJob = '/job/update-job'; // /job/update-job/:id
  static const String deleteJob = '/job/delete-job'; // /job/delete-job/:id
  static const String jobSuggestions = '/job/suggestions';

  // Company endpoints - dựa trên route web
  static const String getAllCompanies = '/company/public/all';
  static const String getCompanyById = '/company'; // /company/:id
  static const String createCompany = '/company/create';
  static const String updateCompany = '/company/update-company';
  static const String deleteCompany = '/company'; // /company/:id
}