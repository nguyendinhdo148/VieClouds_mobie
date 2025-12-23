import 'package:json_annotation/json_annotation.dart';

part 'company_model.g.dart';

@JsonSerializable()
class CompanyModel {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'slug')
  final String? slug;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'website')
  final String? website;

  @JsonKey(name: 'location')
  final String? location;

  @JsonKey(name: 'address')
  final String? address;

  @JsonKey(name: 'logo')
  final String? logo;

  @JsonKey(name: 'noe')
  final String? noe; // number of employees

  @JsonKey(name: 'yoe')
  final String? yoe; // years of experience

  @JsonKey(name: 'field')
  final String? field; // field of work

  @JsonKey(name: 'businessLicense')
  final String? businessLicense;

  @JsonKey(name: 'taxCode')
  final String? taxCode;

  @JsonKey(name: 'userId', fromJson: _parseUserId)
  final String userId;

  // Thêm field cho populated user data
  final Map<String, dynamic>? user;

  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  CompanyModel({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.website,
    this.location,
    this.address,
    this.logo,
    this.noe,
    this.yoe,
    this.field,
    this.businessLicense,
    this.taxCode,
    required this.userId,
    this.user,
    this.createdAt,
    this.updatedAt, required String status, required String approval, String? approvalNote, required String createdBy,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) =>
      _$CompanyModelFromJson(json);

  Map<String, dynamic> toJson() => _$CompanyModelToJson(this);

  // Helper method to parse userId from various formats
  static String _parseUserId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      // Handle populated user: { _id: "...", name: "...", ... }
      return value['_id']?.toString() ?? '';
    }
    return value.toString();
  }

  // Get user name if populated
  String? get userName {
    if (user is Map) {
      return user?['fullname'] ?? user?['name'] ?? user?['email'];
    }
    return null;
  }

  // Helper method to check if company has logo
  bool get hasLogo => logo != null && logo!.isNotEmpty;

  // Helper method to check if company has business license
  bool get hasBusinessLicense =>
      businessLicense != null && businessLicense!.isNotEmpty;

  // Helper method to get display name (alias for name to match JobModel)
  String get companyName => name;

  // Helper method to get short description
  String get shortDescription {
    if (description == null || description!.isEmpty) {
      return 'Chưa có mô tả công ty';
    }
    if (description!.length <= 100) {
      return description!;
    }
    return '${description!.substring(0, 100)}...';
  }

  // Helper method to validate website URL
  String? get formattedWebsite {
    if (website == null || website!.isEmpty) return null;
    if (website!.startsWith('http://') || website!.startsWith('https://')) {
      return website;
    }
    return 'https://$website';
  }

  // Helper method to get display location (prefer address over location)
  String? get displayLocation {
    return address ?? location;
  }

  // Helper method to get number of employees with formatting
  String? get formattedNoe {
    if (noe == null || noe!.isEmpty) return null;
    return '$noe nhân viên';
  }

  // Helper method to get years of experience with formatting
  String? get formattedYoe {
    if (yoe == null || yoe!.isEmpty) return null;
    return 'Thành lập $yoe';
  }

  // Helper method to check if company has complete profile
  bool get hasCompleteProfile {
    return description != null &&
        description!.isNotEmpty &&
        location != null &&
        location!.isNotEmpty &&
        logo != null &&
        logo!.isNotEmpty;
  }

  // Helper method to get company stats for display
  List<String> get companyStats {
    final stats = <String>[];
    if (noe != null && noe!.isNotEmpty) stats.add('$noe nhân viên');
    if (yoe != null && yoe!.isNotEmpty) stats.add('Thành lập $yoe');
    if (field != null && field!.isNotEmpty) stats.add(field!);
    return stats;
  }
}