import 'package:json_annotation/json_annotation.dart';
import 'job_model.dart';
import 'user_model.dart';

part 'application_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ApplicationModel {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'job', fromJson: _parseJob)
  final String jobId;

  @JsonKey(name: 'applicant', fromJson: _parseApplicant)
  final String applicantId;

  @JsonKey(name: 'status')
  final String status;

  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;

  /// Thông tin job đã được populate (nếu có)
  @JsonKey(name: 'job', includeToJson: false)
  final Map<String, dynamic>? jobData;

  /// Thông tin applicant đã được populate (nếu có)
  @JsonKey(name: 'applicant', includeToJson: false)
  final Map<String, dynamic>? applicantData;

  final JobModel? job;
  final UserModel? applicant;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.jobData,
    this.applicantData,
    this.job,
    this.applicant,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    print('🛠️ ApplicationModel.fromJson:');
    print('   - Application ID: ${json['_id']}');

    try {
      final jobField = json['job'];
      final applicantField = json['applicant'];

      print('   - Raw job field type: ${jobField.runtimeType}');

      // Parse với null safety
      final parsedJobId = _parseJob(jobField);
      final parsedApplicantId = _parseApplicant(applicantField);

      print('   - Parsed jobId: $parsedJobId');
      print('   - Parsed applicantId: $parsedApplicantId');
      print('   - Status: ${json['status']}');

      // Parse JobModel và UserModel với try-catch
      JobModel? jobModel;
      try {
        if (jobField is Map<String, dynamic>) {
          jobModel = JobModel.fromJson(jobField);
        }
      } catch (e) {
        print('   - Error parsing JobModel: $e');
      }

      UserModel? userModel;
      try {
        if (applicantField is Map<String, dynamic>) {
          userModel = UserModel.fromJson(applicantField);
        }
      } catch (e) {
        print('   - Error parsing UserModel: $e');
      }

      return ApplicationModel(
        id: json['_id']?.toString() ?? '',
        jobId: parsedJobId,
        applicantId: parsedApplicantId,
        status: json['status']?.toString() ?? 'pending',
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
        jobData: jobField is Map<String, dynamic> ? jobField : null,
        applicantData: applicantField is Map<String, dynamic> ? applicantField : null,
        job: jobModel,
        applicant: userModel,
      );
    } catch (e) {
      print('❌ Error in ApplicationModel.fromJson: $e');
      print('❌ JSON data: $json');
      // Trả về application model empty để tránh crash
      return ApplicationModel(
        id: json['_id']?.toString() ?? '',
        jobId: '',
        applicantId: '',
        status: 'error',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  static DateTime _parseDate(dynamic date) {
    try {
      if (date == null) return DateTime.now();
      if (date is DateTime) return date;
      if (date is String) return DateTime.parse(date);
      return DateTime.now();
    } catch (e) {
      print('⚠️ Error parsing date: $e, value: $date');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() => _$ApplicationModelToJson(this);

  static String _parseJob(dynamic job) {
    if (job == null) return '';

    if (job is String) {
      return job;
    }

    if (job is Map) {
      final possibleIdFields = ['_id', 'id', 'jobId', 'jobID', 'job_id'];
      for (final field in possibleIdFields) {
        final value = job[field];
        if (value != null) {
          return value.toString();
        }
      }
      return '';
    }

    return '';
  }

  static String _parseApplicant(dynamic applicant) {
    if (applicant == null) return '';

    if (applicant is String) {
      return applicant;
    }

    if (applicant is Map) {
      final possibleIdFields = ['_id', 'id', 'applicantId'];
      for (final field in possibleIdFields) {
        final value = applicant[field];
        if (value != null) {
          return value.toString();
        }
      }
      return '';
    }

    return '';
  }

  // === UI GETTERS ===

  String get jobTitle {
    if (job != null && job!.title != null) {
      return job!.title!;
    }
    if (jobData != null && jobData!['title'] != null) {
      return jobData!['title'].toString();
    }
    return 'Không có tiêu đề';
  }

  String get companyName {
    if (job != null && job!.companyId != null) {
      return job!.companyId!;
    }
    if (jobData != null && jobData!['company'] != null) {
      final company = jobData!['company'];
      if (company is String) return company;
      if (company is Map) {
        return company['name']?.toString() ?? 'Công ty ẩn danh';
      }
    }
    return 'Công ty ẩn danh';
  }

  String? get companyLogo {
    if (jobData != null && jobData!['company'] != null) {
      final company = jobData!['company'];
      if (company is Map) {
        return company['logo']?.toString();
      }
    }
    return null;
  }

  String get applicantName {
    if (applicant != null && applicant!.fullname != null) {
      return applicant!.fullname;
    }
    if (applicantData != null) {
      if (applicantData!['fullname'] != null) {
        return applicantData!['fullname'].toString();
      }
      if (applicantData!['name'] != null) {
        return applicantData!['name'].toString();
      }
    }
    return 'Ứng viên ẩn danh';
  }

  String? get applicantEmail {
    if (applicant != null) {
      return applicant!.email;
    }
    if (applicantData != null && applicantData!['email'] != null) {
      return applicantData!['email'].toString();
    }
    return null;
  }

  String? get applicantPhone {
    if (applicant != null && applicant!.phoneNumber != null) {
      return '0${applicant!.phoneNumber}';
    }
    if (applicantData != null && applicantData!['phoneNumber'] != null) {
      return '0${applicantData!['phoneNumber'].toString()}';
    }
    return null;
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Đang chờ xử lý';
      case 'accepted':
        return 'Đã được chấp nhận';
      case 'rejected':
        return 'Đã bị từ chối';
      default:
        return status;
    }
  }

  String get statusColor {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'accepted':
        return 'green';
      case 'rejected':
        return 'red';
      default:
        return 'grey';
    }
  }

  bool get hasApplied => id.isNotEmpty;
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  void printDebugInfo() {
    print('🔍 Application Debug Info:');
    print('   - ID: $id');
    print('   - Status: $status');
    print('   - Job ID: $jobId');
    print('   - Applicant ID: $applicantId');
    print('   - Job Title: $jobTitle');
    print('   - Company Name: $companyName');
    print('   - Applicant Name: $applicantName');
    print('   - Applicant Email: $applicantEmail');
  }
}