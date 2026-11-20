// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorldDetails _$WorldDetailsFromJson(Map<String, dynamic> json) =>
    _WorldDetails(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: $enumDecode(_$WorldCategoryEnumMap, json['category']),
      unlockRadiusMeters: (json['unlock_radius_meters'] as num).toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      creatorUsername: json['creator_username'] as String,
      creatorDisplayName: json['creator_display_name'] as String?,
      coverPath: json['cover_path'] as String?,
      blockCount: (json['block_count'] as num).toInt(),
      status: $enumDecode(_$WorldStatusEnumMap, json['status']),
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
      isCreator: json['is_creator'] as bool? ?? false,
      playStatus: $enumDecodeNullable(_$PlayStatusEnumMap, json['play_status']),
    );

Map<String, dynamic> _$WorldDetailsToJson(_WorldDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': _$WorldCategoryEnumMap[instance.category]!,
      'unlock_radius_meters': instance.unlockRadiusMeters,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'distance_meters': instance.distanceMeters,
      'creator_username': instance.creatorUsername,
      'creator_display_name': instance.creatorDisplayName,
      'cover_path': instance.coverPath,
      'block_count': instance.blockCount,
      'status': _$WorldStatusEnumMap[instance.status]!,
      'published_at': instance.publishedAt?.toIso8601String(),
      'is_creator': instance.isCreator,
      'play_status': _$PlayStatusEnumMap[instance.playStatus],
    };

const _$WorldCategoryEnumMap = {
  WorldCategory.story: 'story',
  WorldCategory.puzzle: 'puzzle',
  WorldCategory.art: 'art',
  WorldCategory.experience: 'experience',
};

const _$WorldStatusEnumMap = {
  WorldStatus.draft: 'draft',
  WorldStatus.published: 'published',
  WorldStatus.hidden: 'hidden',
  WorldStatus.deleted: 'deleted',
};

const _$PlayStatusEnumMap = {
  PlayStatus.locked: 'locked',
  PlayStatus.inProgress: 'in_progress',
  PlayStatus.completed: 'completed',
};
