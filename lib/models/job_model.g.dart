// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JobModel _$JobModelFromJson(Map<String, dynamic> json) => JobModel(
  id: json['_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  requirements: (json['requirements'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  salary: (json['salary'] as num).toDouble(),
  experienceLevel: (json['experienceLevel'] as num).toInt(),
  benefits: (json['benefits'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  location: json['location'] as String,
  jobType: json['jobType'] as String,
  position: (json['position'] as num).toInt(),
  companyId: JobModel._parseCompanyId(json['company']),
  status: json['status'] as String,
  approval: json['approval'] as String,
  approvalNote: json['approvalNote'] as String,
  category: json['category'] as String,
  createdBy: JobModel._parseCreatedBy(json['created_by']),
  applications: (json['applications'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  interviewTest: json['interviewTest'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  companyInfo: json['companyInfo'] == null
      ? null
      : CompanyModel.fromJson(json['companyInfo'] as Map<String, dynamic>),
  createdByUser: json['createdByUser'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$JobModelToJson(JobModel instance) => <String, dynamic>{
  '_id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'requirements': instance.requirements,
  'salary': instance.salary,
  'experienceLevel': instance.experienceLevel,
  'benefits': instance.benefits,
  'location': instance.location,
  'jobType': instance.jobType,
  'position': instance.position,
  'company': instance.companyId,
  'status': instance.status,
  'approval': instance.approval,
  'approvalNote': instance.approvalNote,
  'category': instance.category,
  'created_by': instance.createdBy,
  'applications': instance.applications,
  'interviewTest': instance.interviewTest,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'companyInfo': instance.companyInfo,
  'createdByUser': instance.createdByUser,
};
