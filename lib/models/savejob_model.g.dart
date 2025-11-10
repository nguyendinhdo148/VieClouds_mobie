// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savejob_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveJobModel _$SaveJobModelFromJson(Map<String, dynamic> json) => SaveJobModel(
  id: json['_id'] as String,
  userId: SaveJobModel._parseUserId(json['user']),
  jobId: SaveJobModel._parseJobId(json['job']),
  savedAt: DateTime.parse(json['savedAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  userInfo: json['userInfo'] == null
      ? null
      : UserModel.fromJson(json['userInfo'] as Map<String, dynamic>),
  jobInfo: json['jobInfo'] == null
      ? null
      : JobModel.fromJson(json['jobInfo'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SaveJobModelToJson(SaveJobModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'user': instance.userId,
      'job': instance.jobId,
      'savedAt': instance.savedAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'userInfo': instance.userInfo,
      'jobInfo': instance.jobInfo,
    };
