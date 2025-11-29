import 'package:json_annotation/json_annotation.dart';

part 'blog_model.g.dart';

@JsonSerializable()
class BlogModel {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'slug')
  final String slug;

  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'image')
  final BlogImage image;

  @JsonKey(name: 'approval')
  final String approval;

  @JsonKey(name: 'approvalNote')
  final String approvalNote;

  @JsonKey(name: 'tags', fromJson: _parseTags)
  final List<String> tags;

  @JsonKey(name: 'category')
  final String category;

  @JsonKey(name: 'views')
  final int views;

  @JsonKey(name: 'created_by', fromJson: _parseCreatedBy)
  final BlogAuthor createdBy;

  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  BlogModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.image,
    required this.approval,
    required this.approvalNote,
    required this.tags,
    required this.category,
    required this.views,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) => _$BlogModelFromJson(json);

  Map<String, dynamic> toJson() => _$BlogModelToJson(this);

  static BlogAuthor _parseCreatedBy(dynamic value) {
    print('   🔍 Parsing created_by: $value (type: ${value.runtimeType})');
    
    if (value == null) {
      return BlogAuthor(id: '');
    }

    if (value is String) {
      return BlogAuthor(id: value);
    }

    if (value is Map<String, dynamic>) {
      try {
        return BlogAuthor.fromJson(value);
      } catch (e) {
        print('   ❌ Error parsing BlogAuthor: $e');
        final id = value['_id']?.toString() ?? '';
        final fullname = value['fullname']?.toString() ?? '';
        final email = value['email']?.toString() ?? '';
        return BlogAuthor(id: id, fullname: fullname, email: email);
      }
    }

    return BlogAuthor(id: value?.toString() ?? '');
  }

  static List<String> _parseTags(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];

    final List<String> result = [];
    final List<dynamic> list = value;

    for (int i = 0; i < list.length; i++) {
      final tag = list[i];

      if (tag is List) {
        for (final item in tag) {
          if (item is String && item.trim().isNotEmpty) {
            result.add(item.trim());
          }
        }
        continue;
      }

      if (tag is String && tag.trim().isNotEmpty) {
        result.add(tag.trim());
        continue;
      }
    }

    return result;
  }
}

@JsonSerializable()
class BlogAuthor {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'fullname')
  final String fullname;

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'profile', fromJson: _parseProfile)
  final BlogProfile? profile;

  BlogAuthor({
    required this.id,
    this.fullname = '',
    this.email = '',
    this.profile,
  });

  factory BlogAuthor.fromJson(Map<String, dynamic> json) => _$BlogAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$BlogAuthorToJson(this);

  // Custom parser cho profile để xử lý cả String và Map
  static BlogProfile? _parseProfile(dynamic value) {
    if (value == null) return null;
    
    if (value is String) {
      // Nếu profile là String (URL), tạo BlogProfile với URL đó
      return BlogProfile(
        bio: '',
        profilePhoto: BlogProfilePhoto(url: value),
      );
    }
    
    if (value is Map<String, dynamic>) {
      try {
        return BlogProfile.fromJson(value);
      } catch (e) {
        print('   ❌ Error parsing BlogProfile: $e');
        return null;
      }
    }
    
    return null;
  }

  bool get hasDetailedInfo => fullname.isNotEmpty || email.isNotEmpty;
}

@JsonSerializable()
class BlogProfile {
  @JsonKey(name: 'bio', defaultValue: '')
  final String bio;

  @JsonKey(name: 'profilePhoto', fromJson: _parseProfilePhoto)
  final BlogProfilePhoto profilePhoto;

  BlogProfile({
    required this.bio,
    required this.profilePhoto,
  });

  factory BlogProfile.fromJson(Map<String, dynamic> json) => _$BlogProfileFromJson(json);

  Map<String, dynamic> toJson() => _$BlogProfileToJson(this);

  static BlogProfilePhoto _parseProfilePhoto(dynamic value) {
    if (value is String) {
      return BlogProfilePhoto(url: value);
    }
    
    if (value is Map<String, dynamic>) {
      try {
        return BlogProfilePhoto.fromJson(value);
      } catch (e) {
        return BlogProfilePhoto(url: '');
      }
    }
    
    return BlogProfilePhoto(url: '');
  }
}

@JsonSerializable()
class BlogProfilePhoto {
  @JsonKey(name: 'url', defaultValue: '')
  final String url;

  BlogProfilePhoto({required this.url});

  factory BlogProfilePhoto.fromJson(Map<String, dynamic> json) => _$BlogProfilePhotoFromJson(json);

  Map<String, dynamic> toJson() => _$BlogProfilePhotoToJson(this);
}

@JsonSerializable()
class BlogImage {
  @JsonKey(name: 'url')
  final String url;

  @JsonKey(name: 'public_id')
  final String publicId;

  BlogImage({
    required this.url,
    required this.publicId,
  });

  factory BlogImage.fromJson(Map<String, dynamic> json) => _$BlogImageFromJson(json);

  Map<String, dynamic> toJson() => _$BlogImageToJson(this);
}