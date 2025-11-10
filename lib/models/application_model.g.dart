// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationModel _$ApplicationModelFromJson(Map<String, dynamic> json) =>
    ApplicationModel(
      id: json['_id'] as String,
      jobId: ApplicationModel._parseJobId(json['job']),
      applicantId: ApplicationModel._parseApplicantId(json['applicant']),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      job: json['jobInfo'] == null
          ? null
          : JobModel.fromJson(json['jobInfo'] as Map<String, dynamic>),
      applicant: json['applicantInfo'] == null
          ? null
          : UserModel.fromJson(json['applicantInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ApplicationModelToJson(ApplicationModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'job': instance.jobId,
      'applicant': instance.applicantId,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'jobInfo': instance.job,
      'applicantInfo': instance.applicant,
    };
