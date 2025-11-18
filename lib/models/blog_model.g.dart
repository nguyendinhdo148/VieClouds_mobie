// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blog_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlogModel _$BlogModelFromJson(Map<String, dynamic> json) => BlogModel(
  id: json['_id'] as String,
  title: json['title'] as String,
  slug: json['slug'] as String,
  content: json['content'] as String,
  image: BlogImage.fromJson(json['image'] as Map<String, dynamic>),
  approval: json['approval'] as String,
  approvalNote: json['approvalNote'] as String,
  tags: BlogModel._parseTags(json['tags']),
  category: json['category'] as String,
  views: (json['views'] as num).toInt(),
  createdBy: BlogModel._parseCreatedBy(json['created_by']),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$BlogModelToJson(BlogModel instance) => <String, dynamic>{
  '_id': instance.id,
  'title': instance.title,
  'slug': instance.slug,
  'content': instance.content,
  'image': instance.image,
  'approval': instance.approval,
  'approvalNote': instance.approvalNote,
  'tags': instance.tags,
  'category': instance.category,
  'views': instance.views,
  'created_by': instance.createdBy,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

BlogImage _$BlogImageFromJson(Map<String, dynamic> json) => BlogImage(
  url: json['url'] as String,
  publicId: json['public_id'] as String,
);

Map<String, dynamic> _$BlogImageToJson(BlogImage instance) => <String, dynamic>{
  'url': instance.url,
  'public_id': instance.publicId,
};
