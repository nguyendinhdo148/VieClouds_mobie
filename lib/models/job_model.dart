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

  // Chỉ giữ 1 field duy nhất để parse dữ liệu company (đã populate từ BE)
  @JsonKey(name: 'company', fromJson: _parseCompanyData)
  final Map<String, dynamic>? companyData;

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

  // Optional info (không bị map trùng)
  final CompanyModel? companyInfo;
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
    this.companyData,
    this.createdByUser,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) =>
      _$JobModelFromJson(json);

  Map<String, dynamic> toJson() => _$JobModelToJson(this);

  // ======== PARSE METHODS ========

  static String _parseCreatedBy(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) return value['_id']?.toString() ?? '';
    return value.toString();
  }

  static Map<String, dynamic>? _parseCompanyData(dynamic value) {
    if (value == null) return null;
    if (value is Map) return value as Map<String, dynamic>;
    return null;
  }

  // ======== DERIVED GETTERS ========

  /// Lấy companyId từ dữ liệu đã populate
  String get companyId {
    if (companyData == null) return '';
    return companyData!['_id']?.toString() ?? '';
  }

  /// Lấy tên công ty hiển thị
  String get companyName {
    if (companyInfo?.name != null && companyInfo!.name.isNotEmpty) {
      return companyInfo!.name;
    }
    if (companyData != null && companyData!['name'] != null) {
      return companyData!['name'].toString();
    }
    return 'Công ty ẩn danh';
  }

  /// Lấy logo công ty
  String? get companyLogo {
    if (companyInfo?.logo != null && companyInfo!.logo!.isNotEmpty) {
      return companyInfo!.logo;
    }
    if (companyData != null && companyData!['logo'] != null) {
      return companyData!['logo'].toString();
    }
    return null;
  }

  /// Trạng thái việc làm
  bool get isActive => status == 'active' && approval == 'approved';

  /// Hiển thị lương
  String get formattedSalary {
    if (salary == 0) return 'Thương lượng';
    if (salary >= 1000000) {
      return '${(salary / 1000000).toStringAsFixed(0)} triệu';
    }
    return '${salary.toStringAsFixed(0)} VNĐ';
  }

  /// Mức kinh nghiệm
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

  /// Vị trí
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

  /// Kiểu công việc (dịch sang tiếng Việt)
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

  /// Trạng thái việc làm
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

  /// Trạng thái duyệt
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

  /// Thời gian đăng tin
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    return '${(diff.inDays / 30).floor()} tháng trước';
  }

  /// Kiểm tra job mới (<=3 ngày)
  bool get isUrgent => createdAt.difference(DateTime.now()).inDays.abs() <= 3;

  /// Lấy tên người tạo
  String get creatorName {
    if (createdByUser != null) {
      return createdByUser?['fullname'] ?? createdByUser?['name'] ?? 'Ẩn danh';
    }
    return 'Ẩn danh';
  }
}
