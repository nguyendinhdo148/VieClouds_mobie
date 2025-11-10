import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'fullname')
  final String fullname;

  @JsonKey(name: 'email')
  final String email;

  // ✅ Convert tự động int -> String để tránh lỗi
  @JsonKey(name: 'phoneNumber', fromJson: _toString)
  final String phoneNumber;

  @JsonKey(name: 'role')
  final String role;

  @JsonKey(name: 'profile')
  final UserProfile? profile;

  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.fullname,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.profile,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  // 👉 Helper convert int -> String
  static String _toString(dynamic value) => value?.toString() ?? '';
}

@JsonSerializable()
class UserProfile {
  @JsonKey(name: 'bio')
  final String? bio;

  @JsonKey(name: 'skills')
  final List<String>? skills;

  @JsonKey(name: 'resume')
  final String? resume;

  @JsonKey(name: 'resumeOriginalName')
  final String? resumeOriginalName;

  @JsonKey(name: 'profilePhoto')
  final String? profilePhoto;

  UserProfile({
    this.bio,
    this.skills,
    this.resume,
    this.resumeOriginalName,
    this.profilePhoto,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}
