import 'package:json_annotation/json_annotation.dart';

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

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.jobData,
    this.applicantData,
  });

  /// Parse từ JSON - VERSION DEBUG
  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    final jobField = json['job'];
    final applicantField = json['applicant'];

    print('🛠️ ApplicationModel.fromJson:');
    print('   - Application ID: ${json['_id']}');
    print('   - Raw job field type: ${jobField.runtimeType}');
    
    if (jobField is Map) {
      print('   - Raw job field keys: ${jobField.keys}');
      print('   - Raw job _id: ${jobField['_id']}');
      print('   - Raw job title: ${jobField['title']}');
    } else {
      print('   - Raw job field value: $jobField');
    }

    final parsedJobId = _parseJob(jobField);
    final parsedApplicantId = _parseApplicant(applicantField);

    print('   - Parsed jobId: $parsedJobId');
    print('   - Parsed applicantId: $parsedApplicantId');
    print('   - Status: ${json['status']}');
    print('---');

    return ApplicationModel(
      id: json['_id']?.toString() ?? '',
      jobId: parsedJobId,
      applicantId: parsedApplicantId,
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      jobData: jobField is Map<String, dynamic> ? jobField : null,
      applicantData: applicantField is Map<String, dynamic> ? applicantField : null,
    );
  }

  Map<String, dynamic> toJson() => _$ApplicationModelToJson(this);

  // Helper parse methods - VERSION DEBUG + FIXED
static String _parseJob(dynamic job) {
  print('      🔍 _parseJob called');
  
  if (job == null) return '';
  
  if (job is String) {
    print('      ✅ Job is String: "$job"');
    return job.isEmpty ? '' : job;
  }
  
  if (job is Map) {
    print('      🔍 Job is Map - keys: ${job.keys}');
    
    // THỬ TÌM ID TRONG CÁC TRƯỜNG CÓ THỂ (bao gồm cả nested)
    final possibleIdFields = ['_id', 'id', 'jobId', 'jobID', 'job_id'];
    
    for (final field in possibleIdFields) {
      if (job[field] != null) {
        final id = job[field].toString();
        print('      ✅ Found $field: "$id"');
        return id;
      }
    }
    
    // DEBUG: In toàn bộ cấu trúc để tìm jobId
    print('      🔍 DEBUG - Full job structure:');
    _printMap(job, 2);
    
    // TẠM THỜI: Thử tìm jobId từ các field khác hoặc từ context
    // Có thể jobId được lưu ở field khác hoặc cần query riêng
    
    print('      ❌ CRITICAL: Job map has no ID field!');
    return '';
  }
  
  return '';
}

// Helper để in nested map
static void _printMap(Map<dynamic, dynamic> map, int indent) {
  final spaces = ' ' * indent;
  map.forEach((key, value) {
    if (value is Map) {
      print('$spaces$key: {');
      _printMap(value as Map<dynamic, dynamic>, indent + 2);
      print('$spaces}');
    } else {
      print('$spaces$key: $value (${value.runtimeType})');
    }
  });
}
  static String _parseApplicant(dynamic applicant) {
    if (applicant == null) return '';
    
    if (applicant is String) return applicant;
    
    if (applicant is Map) {
      final applicantMap = applicant as Map<String, dynamic>;
      
      if (applicantMap.containsKey('_id') && applicantMap['_id'] != null) {
        return applicantMap['_id'].toString();
      }
      
      if (applicantMap.containsKey('id') && applicantMap['id'] != null) {
        return applicantMap['id'].toString();
      }
      
      return '';
    }
    
    return applicant.toString();
  }

  // === UI GETTERS ===

  String get jobTitle {
    if (jobData != null && jobData!['title'] != null) {
      return jobData!['title'].toString();
    }
    return 'Không có tiêu đề';
  }

  String get companyName {
    if (jobData != null && jobData!['company'] != null) {
      final company = jobData!['company'];
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

  String get jobLocation {
    if (jobData != null && jobData!['location'] != null) {
      return jobData!['location'].toString();
    }
    return 'Không xác định';
  }

  String get jobSalary {
    if (jobData != null && jobData!['salary'] != null) {
      final salary = jobData!['salary'];
      if (salary is num) {
        if (salary == 0) return 'Thương lượng';
        if (salary >= 1000000) {
          return '${(salary / 1000000).toStringAsFixed(0)} triệu';
        }
        return '${salary.toStringAsFixed(0)} VNĐ';
      }
    }
    return 'Thương lượng';
  }

  String get applicantName {
    if (applicantData != null && applicantData!['fullname'] != null) {
      return applicantData!['fullname'].toString();
    }
    if (applicantData != null && applicantData!['name'] != null) {
      return applicantData!['name'].toString();
    }
    return 'Ứng viên ẩn danh';
  }

  String? get applicantEmail {
    if (applicantData != null && applicantData!['email'] != null) {
      return applicantData!['email'].toString();
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
        return 'Chưa ứng tuyển';
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
    print('   - Job Data: ${jobData?.keys}');
    if (jobData != null && jobData!['company'] != null) {
      print('   - Company Data: ${jobData!['company']}');
    }
    print('   - Applicant Data: ${applicantData?.keys}');
  }

  // Thêm method để debug jobId comparison
  void debugJobIdComparison(String targetJobId) {
    print('🔍 JobId Comparison Debug:');
    print('   - Target JobId: $targetJobId');
    print('   - This JobId: $jobId');
    print('   - Match: ${targetJobId == jobId}');
    
    if (jobData is Map) {
      final jobDataMap = jobData as Map;
      print('   - JobData _id: ${jobDataMap['_id']}');
      print('   - JobData id: ${jobDataMap['id']}');
      print('   - Match with _id: ${targetJobId == jobDataMap['_id']?.toString()}');
      print('   - Match with id: ${targetJobId == jobDataMap['id']?.toString()}');
    }
  }
}