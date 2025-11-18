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

  // ✅ FIXED: Add custom parser for tags to handle nested lists
  @JsonKey(name: 'tags', fromJson: _parseTags)
  final List<String> tags;

  @JsonKey(name: 'category')
  final String category;

  @JsonKey(name: 'views')
  final int views;

  @JsonKey(name: 'created_by', fromJson: _parseCreatedBy)
  final String createdBy;

  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;
static String _parseCreatedBy(dynamic value) {
  if (value is Map) {
    return value['_id'] ?? '';
  }
  return value?.toString() ?? '';
}

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

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🛠️ Parsing BlogModel:');
      print('   - ID: ${json['_id']}');
      print('   - Title: ${json['title']}');
      print('   - Tags raw: ${json['tags']}');
      print('   - Tags type: ${json['tags'].runtimeType}');
      print('   - Image type: ${json['image'].runtimeType}');

      // Validate image
      if (json['image'] is! Map) {
        print(
            '   ❌ ERROR: image is not a Map! Type: ${json['image'].runtimeType}');
        throw Exception('Invalid image format');
      }

      return _$BlogModelFromJson(json);
    } catch (e) {
      print('   ❌ Error parsing BlogModel: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => _$BlogModelToJson(this);

  // ✅ FIXED: Custom parser for tags to handle nested arrays
  static List<String> _parseTags(dynamic value) {
  if (value == null) {
    print('   ⚠️ Tags is null, returning empty list');
    return [];
  }

  if (value is! List) {
    print('   ⚠️ Tags is not a List! Type: ${value.runtimeType}');
    return [];
  }

  final List<String> result = [];
  final List<dynamic> list = value;

  print('   🔍 Parsing ${list.length} tags');

  for (int i = 0; i < list.length; i++) {
    final tag = list[i];
    print('      Tag $i: $tag (type: ${tag.runtimeType})');

    // Case: tag is nested list (example: [[]] or [["tech", "ai"]])
    if (tag is List) {
      print('      - Nested list detected, flattening...');
      for (final item in tag) {
        if (item is String && item.trim().isNotEmpty) {
          result.add(item.trim());
          print('         Added: "$item"');
        }
      }
      continue;
    }

    // Case: tag is String
    if (tag is String && tag.trim().isNotEmpty) {
      result.add(tag.trim());
      print('      - Added: "$tag"');
      continue;
    }

    // Unknown type (map, object…)
    print('      ⚠️ Unsupported tag type: ${tag.runtimeType}, ignored.');
  }

  print('   ✅ Parsed ${result.length} valid tags');
  return result;
}


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

  factory BlogImage.fromJson(Map<String, dynamic> json) =>
      _$BlogImageFromJson(json);

  Map<String, dynamic> toJson() => _$BlogImageToJson(this);
}