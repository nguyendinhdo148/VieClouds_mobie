import 'package:json_annotation/json_annotation.dart';
import 'job_model.dart';
import 'user_model.dart';

part 'savejob_model.g.dart'; // SỬA THÀNH savejob_model.g.dart

@JsonSerializable()
class SaveJobModel {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'user', fromJson: _parseUserId)
  final String userId;

  @JsonKey(name: 'job', fromJson: _parseJobId)
  final String jobId;

  @JsonKey(name: 'savedAt')
  final DateTime savedAt;

  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;

  // Populated data
  final UserModel? userInfo;
  final JobModel? jobInfo;

  SaveJobModel({
    required this.id,
    required this.userId,
    required this.jobId,
    required this.savedAt,
    required this.createdAt,
    required this.updatedAt,
    this.userInfo,
    this.jobInfo,
  });

  factory SaveJobModel.fromJson(Map<String, dynamic> json) =>
      _$SaveJobModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaveJobModelToJson(this);

  // Helper method to parse user ID from various formats
  static String _parseUserId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      // Handle populated user: { _id: "...", fullname: "...", ... }
      return value['_id']?.toString() ?? '';
    }
    return value.toString();
  }

  // Helper method to parse job ID from various formats
  static String _parseJobId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      // Handle populated job: { _id: "...", title: "...", ... }
      return value['_id']?.toString() ?? '';
    }
    return value.toString();
  }

  // Helper method to get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(savedAt);
    
    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inHours < 1) return '${difference.inMinutes} phút trước';
    if (difference.inDays < 1) return '${difference.inHours} giờ trước';
    if (difference.inDays < 7) return '${difference.inDays} ngày trước';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} tuần trước';
    return '${(difference.inDays / 30).floor()} tháng trước';
  }

  // Get formatted saved date
  String get formattedDate {
    return '${savedAt.day}/${savedAt.month}/${savedAt.year}';
  }

  // Get job title
  String get jobTitle {
    return jobInfo?.title ?? 'Không có tiêu đề';
  }

  // Get company name
  String get companyName {
    return jobInfo?.companyName ?? 'Công ty ẩn danh';
  }

  // Get job location
  String get jobLocation {
    return jobInfo?.location ?? 'Không xác định';
  }

  // Get job salary
  String get jobSalary {
    return jobInfo?.formattedSalary ?? 'Thương lượng';
  }

  // Get job type
  String get jobType {
    return jobInfo?.jobTypeText ?? 'Toàn thời gian';
  }

  // Check if saved job is recent (within 3 days)
  bool get isRecent {
    return savedAt.difference(DateTime.now()).inDays.abs() <= 3;
  }

  // Get user name
  String get userName {
    return userInfo?.fullname ?? 'Người dùng ẩn danh';
  }

  // Get user email
  String get userEmail {
    return userInfo?.email ?? 'Chưa có email';
  }
}