// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world_preview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorldPreview _$WorldPreviewFromJson(Map<String, dynamic> json) =>
    _WorldPreview(
      id: json['id'] as String,
      title: json['title'] as String,
      category: $enumDecode(_$WorldCategoryEnumMap, json['category']),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceMeters: (json['distance_meters'] as num).toDouble(),
      creatorUsername: json['creator_username'] as String,
      creatorDisplayName: json['creator_display_name'] as String?,
    );

Map<String, dynamic> _$WorldPreviewToJson(_WorldPreview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'category': _$WorldCategoryEnumMap[instance.category]!,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'distance_meters': instance.distanceMeters,
      'creator_username': instance.creatorUsername,
      'creator_display_name': instance.creatorDisplayName,
    };

const _$WorldCategoryEnumMap = {
  WorldCategory.story: 'story',
  WorldCategory.puzzle: 'puzzle',
  WorldCategory.art: 'art',
  WorldCategory.experience: 'experience',
};
