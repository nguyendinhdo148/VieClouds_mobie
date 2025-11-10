// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompanyModel _$CompanyModelFromJson(Map<String, dynamic> json) => CompanyModel(
  id: json['_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  website: json['website'] as String?,
  location: json['location'] as String?,
  logo: json['logo'] as String?,
  businessLicense: json['businessLicense'] as String?,
  taxCode: json['taxCode'] as String?,
  userId: CompanyModel._parseUserId(json['userId']),
  user: json['user'] as Map<String, dynamic>?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CompanyModelToJson(CompanyModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'website': instance.website,
      'location': instance.location,
      'logo': instance.logo,
      'businessLicense': instance.businessLicense,
      'taxCode': instance.taxCode,
      'userId': instance.userId,
      'user': instance.user,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
