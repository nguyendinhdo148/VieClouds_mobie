import 'package:json_annotation/json_annotation.dart';
import 'job_model.dart';
import 'user_model.dart';

part 'application_model.g.dart';

@JsonSerializable()
class ApplicationModel {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'job', fromJson: _parseJobId)
  final String jobId;

  @JsonKey(name: 'applicant', fromJson: _parseApplicantId)
  final String applicantId;

  @JsonKey(name: 'status')
  final String status;

  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;

  // Populated data - THÊM JSON KEY RIÊNG
  @JsonKey(name: 'jobInfo')
  final JobModel? job;

  @JsonKey(name: 'applicantInfo')
  final UserModel? applicant;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.job,
    this.applicant,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) =>
      _$ApplicationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ApplicationModelToJson(this);

  // Helper method to parse job ID từ field "job"
  static String _parseJobId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      // Nếu job là object, trích xuất ID
      return value['_id']?.toString() ?? '';
    }
    return value.toString();
  }

  // Helper method to parse applicant ID từ field "applicant"
  static String _parseApplicantId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      // Nếu applicant là object, trích xuất ID
      return value['_id']?.toString() ?? '';
    }
    return value.toString();
  }

  // Get job title - SỬA LẠI
  String get jobTitle {
    return job?.title ?? 'Không có tiêu đề';
  }

  // Get company name - SỬA LẠI
  String get companyName {
    return job?.companyName ?? 'Công ty ẩn danh';
  }

  // Get applicant name - SỬA LẠI
  String get applicantName {
    return applicant?.fullname ?? 'Ứng viên ẩn danh';
  }
}