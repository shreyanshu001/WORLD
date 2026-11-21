// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_world.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavedWorld _$SavedWorldFromJson(Map<String, dynamic> json) => _SavedWorld(
  id: json['id'] as String,
  title: json['title'] as String,
  category: $enumDecode(_$WorldCategoryEnumMap, json['category']),
  creatorUsername: json['creator_username'] as String,
  creatorDisplayName: json['creator_display_name'] as String?,
  coverPath: json['cover_path'] as String?,
  distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
  savedAt: DateTime.parse(json['saved_at'] as String),
);

Map<String, dynamic> _$SavedWorldToJson(_SavedWorld instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'category': _$WorldCategoryEnumMap[instance.category]!,
      'creator_username': instance.creatorUsername,
      'creator_display_name': instance.creatorDisplayName,
      'cover_path': instance.coverPath,
      'distance_meters': instance.distanceMeters,
      'saved_at': instance.savedAt.toIso8601String(),
    };

const _$WorldCategoryEnumMap = {
  WorldCategory.story: 'story',
  WorldCategory.puzzle: 'puzzle',
  WorldCategory.art: 'art',
  WorldCategory.experience: 'experience',
};
