// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationModel _$ApplicationModelFromJson(Map<String, dynamic> json) =>
    ApplicationModel(
      id: json['_id'] as String,
      jobId: ApplicationModel._parseJob(json['job']),
      applicantId: ApplicationModel._parseApplicant(json['applicant']),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      jobData: json['job'] as Map<String, dynamic>?,
      applicantData: json['applicant'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ApplicationModelToJson(ApplicationModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'job': instance.jobId,
      'applicant': instance.applicantId,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
