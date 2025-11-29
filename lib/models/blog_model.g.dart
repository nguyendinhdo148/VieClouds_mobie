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

BlogAuthor _$BlogAuthorFromJson(Map<String, dynamic> json) => BlogAuthor(
  id: json['_id'] as String,
  fullname: json['fullname'] as String? ?? '',
  email: json['email'] as String? ?? '',
  profile: BlogAuthor._parseProfile(json['profile']),
);

Map<String, dynamic> _$BlogAuthorToJson(BlogAuthor instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'fullname': instance.fullname,
      'email': instance.email,
      'profile': instance.profile,
    };

BlogProfile _$BlogProfileFromJson(Map<String, dynamic> json) => BlogProfile(
  bio: json['bio'] as String? ?? '',
  profilePhoto: BlogProfile._parseProfilePhoto(json['profilePhoto']),
);

Map<String, dynamic> _$BlogProfileToJson(BlogProfile instance) =>
    <String, dynamic>{
      'bio': instance.bio,
      'profilePhoto': instance.profilePhoto,
    };

BlogProfilePhoto _$BlogProfilePhotoFromJson(Map<String, dynamic> json) =>
    BlogProfilePhoto(url: json['url'] as String? ?? '');

Map<String, dynamic> _$BlogProfilePhotoToJson(BlogProfilePhoto instance) =>
    <String, dynamic>{'url': instance.url};

BlogImage _$BlogImageFromJson(Map<String, dynamic> json) => BlogImage(
  url: json['url'] as String,
  publicId: json['public_id'] as String,
);

Map<String, dynamic> _$BlogImageToJson(BlogImage instance) => <String, dynamic>{
  'url': instance.url,
  'public_id': instance.publicId,
};
