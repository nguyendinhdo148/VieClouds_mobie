// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['_id'] as String? ?? '',
  fullname: json['fullname'] as String? ?? '',
  email: json['email'] as String? ?? '',
  phoneNumber: UserModel._toString(json['phoneNumber']),
  role: json['role'] as String? ?? '',
  profile: json['profile'] == null
      ? null
      : UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  '_id': instance.id,
  'fullname': instance.fullname,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'role': instance.role,
  'profile': instance.profile,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  bio: json['bio'] as String?,
  skills: (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList(),
  resume: json['resume'] as String?,
  resumeOriginalName: json['resumeOriginalName'] as String?,
  profilePhoto: json['profilePhoto'] as String?,
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'bio': instance.bio,
      'skills': instance.skills,
      'resume': instance.resume,
      'resumeOriginalName': instance.resumeOriginalName,
      'profilePhoto': instance.profilePhoto,
    };
