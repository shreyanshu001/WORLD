// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileWorld _$ProfileWorldFromJson(Map<String, dynamic> json) =>
    _ProfileWorld(
      id: json['id'] as String,
      title: json['title'] as String,
      category: $enumDecode(_$WorldCategoryEnumMap, json['category']),
      coverPath: json['cover_path'] as String?,
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
    );

Map<String, dynamic> _$ProfileWorldToJson(_ProfileWorld instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'category': _$WorldCategoryEnumMap[instance.category]!,
      'cover_path': instance.coverPath,
      'published_at': instance.publishedAt?.toIso8601String(),
    };

const _$WorldCategoryEnumMap = {
  WorldCategory.story: 'story',
  WorldCategory.puzzle: 'puzzle',
  WorldCategory.art: 'art',
  WorldCategory.experience: 'experience',
};

_ProfilePage _$ProfilePageFromJson(Map<String, dynamic> json) => _ProfilePage(
  username: json['username'] as String,
  displayName: json['display_name'] as String?,
  bio: json['bio'] as String?,
  isOwn: json['is_own'] as bool? ?? false,
  publishedCount: (json['published_count'] as num).toInt(),
  draftCount: (json['draft_count'] as num?)?.toInt(),
  discoveredCount: (json['discovered_count'] as num?)?.toInt(),
  completedCount: (json['completed_count'] as num?)?.toInt(),
  worlds:
      (json['worlds'] as List<dynamic>?)
          ?.map((e) => ProfileWorld.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ProfileWorld>[],
  hasMore: json['has_more'] as bool? ?? false,
);

Map<String, dynamic> _$ProfilePageToJson(_ProfilePage instance) =>
    <String, dynamic>{
      'username': instance.username,
      'display_name': instance.displayName,
      'bio': instance.bio,
      'is_own': instance.isOwn,
      'published_count': instance.publishedCount,
      'draft_count': instance.draftCount,
      'discovered_count': instance.discoveredCount,
      'completed_count': instance.completedCount,
      'worlds': instance.worlds.map((e) => e.toJson()).toList(),
      'has_more': instance.hasMore,
    };
