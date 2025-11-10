import 'package:json_annotation/json_annotation.dart';
import 'company_model.dart';

part 'job_model.g.dart';

@JsonSerializable()
class JobModel {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'description')
  final String description;

  @JsonKey(name: 'requirements')
  final List<String> requirements;

  @JsonKey(name: 'salary')
  final double salary;

  @JsonKey(name: 'experienceLevel')
  final int experienceLevel;

  @JsonKey(name: 'benefits')
  final List<String> benefits;

  @JsonKey(name: 'location')
  final String location;

  @JsonKey(name: 'jobType')
  final String jobType;

  @JsonKey(name: 'position')
  final int position;

  @JsonKey(name: 'company', fromJson: _parseCompanyId)
  final String companyId;

  @JsonKey(name: 'status')
  final String status;

  @JsonKey(name: 'approval')
  final String approval;

  @JsonKey(name: 'approvalNote')
  final String approvalNote;

  @JsonKey(name: 'category')
  final String category;

  @JsonKey(name: 'created_by', fromJson: _parseCreatedBy)
  final String createdBy;

  @JsonKey(name: 'applications')
  final List<String> applications;

  @JsonKey(name: 'interviewTest')
  final String? interviewTest;

  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;

  // Company info (sẽ được populate từ API) - ĐỔI TÊN FIELD NÀY
  final CompanyModel? companyInfo;

  // User info (sẽ được populate từ API)
  final Map<String, dynamic>? createdByUser;

  JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.requirements,
    required this.salary,
    required this.experienceLevel,
    required this.benefits,
    required this.location,
    required this.jobType,
    required this.position,
    required this.companyId,
    required this.status,
    required this.approval,
    required this.approvalNote,
    required this.category,
    required this.createdBy,
    required this.applications,
    this.interviewTest,
    required this.createdAt,
    required this.updatedAt,
    this.companyInfo,
    this.createdByUser,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) =>
      _$JobModelFromJson(json);

  Map<String, dynamic> toJson() => _$JobModelToJson(this);

  // Helper method to parse company ID from various formats
  static String _parseCompanyId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      // Handle populated company: { _id: "...", name: "...", ... }
      return value['_id']?.toString() ?? '';
    }
    return value.toString();
  }

  // Helper method to parse created_by from various formats
  static String _parseCreatedBy(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      // Handle populated user: { _id: "...", fullname: "...", ... }
      return value['_id']?.toString() ?? '';
    }
    return value.toString();
  }

  // Helper method to get formatted salary
  String get formattedSalary {
    if (salary == 0) return 'Thương lượng';
    
    if (salary >= 1000000) {
      return '${(salary / 1000000).toStringAsFixed(0)} triệu';
    } else {
      return '${salary.toStringAsFixed(0)} VNĐ';
    }
  }

  // Helper method to get experience level text
  String get experienceText {
    switch (experienceLevel) {
      case 0:
        return 'Không yêu cầu kinh nghiệm';
      case 1:
        return 'Dưới 1 năm';
      case 2:
        return '1 - 2 năm';
      case 3:
        return '2 - 3 năm';
      case 4:
        return '3 - 5 năm';
      case 5:
        return 'Trên 5 năm';
      default:
        return 'Không yêu cầu';
    }
  }

  // Helper method to get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inHours < 1) return '${difference.inMinutes} phút trước';
    if (difference.inDays < 1) return '${difference.inHours} giờ trước';
    if (difference.inDays < 7) return '${difference.inDays} ngày trước';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} tuần trước';
    return '${(difference.inDays / 30).floor()} tháng trước';
  }

  // Check if job is active and approved
  bool get isActive => status == 'active' && approval == 'approved';

  // Get company name
  String get companyName {
    return companyInfo?.name ?? 'Công ty ẩn danh';
  }

  // Get company logo
  String? get companyLogo {
    return companyInfo?.logo;
  }

  // Get position title
  String get positionTitle {
    switch (position) {
      case 1:
        return 'Nhân viên';
      case 2:
        return 'Chuyên viên';
      case 3:
        return 'Trưởng nhóm';
      case 4:
        return 'Quản lý';
      case 5:
        return 'Trưởng phòng';
      case 6:
        return 'Giám đốc';
      default:
        return 'Nhân viên';
    }
  }

  // Parse job type to Vietnamese
  String get jobTypeText {
    switch (jobType.toLowerCase()) {
      case 'fulltime':
      case 'full_time':
        return 'Toàn thời gian';
      case 'parttime':
      case 'part_time':
        return 'Bán thời gian';
      case 'contract':
        return 'Hợp đồng';
      case 'internship':
        return 'Thực tập';
      case 'freelance':
        return 'Freelance';
      case 'remote':
        return 'Làm việc từ xa';
      default:
        return jobType;
    }
  }

  // Get status text in Vietnamese
  String get statusText {
    switch (status) {
      case 'active':
        return 'Đang tuyển';
      case 'draft':
        return 'Bản nháp';
      case 'closed':
        return 'Đã đóng';
      default:
        return status;
    }
  }

  // Get approval status text in Vietnamese
  String get approvalText {
    switch (approval) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      default:
        return approval;
    }
  }

  // Check if job is urgent (new job within 3 days)
  bool get isUrgent {
    return createdAt.difference(DateTime.now()).inDays.abs() <= 3;
  }

  // Get creator name
  String get creatorName {
    if (createdByUser != null) {
      return createdByUser?['fullname'] ?? createdByUser?['name'] ?? 'Ẩn danh';
    }
    return 'Ẩn danh';
  }
}