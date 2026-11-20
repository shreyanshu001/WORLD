import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/worlds/domain/content_block_codec.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

/// Converts drafts to and from the JSON of `save_world` and
/// `get_world_draft`. Each block type writes exactly the keys the server
/// accepts; there is no way to send an answer inside a block.
abstract final class WorldDraftCodec {
  static Map<String, Object?> toSaveJson(WorldDraft draft) => {
    'id': draft.id,
    'category': draft.category.name,
    'title': draft.title.trim(),
    'description': _nullIfBlank(draft.description),
    'cover_asset_id': draft.coverAssetId,
    'latitude': draft.location?.latitude,
    'longitude': draft.location?.longitude,
    'unlock_radius_meters': draft.unlockRadiusMeters,
    'blocks': [for (final block in draft.blocks) blockToJson(block)],
  };

  static Map<String, Object?> blockToJson(ContentBlock block) =>
      ContentBlockCodec.toJson(block);

  static WorldDraft fromServer(Map<String, dynamic> json) {
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();
    return WorldDraft(
      id: json['id'] as String,
      category: WorldCategory.values.byName(json['category'] as String),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverAssetId: json['cover_asset_id'] as String?,
      location: latitude == null || longitude == null
          ? null
          : GeoPoint(latitude: latitude, longitude: longitude),
      unlockRadiusMeters:
          (json['unlock_radius_meters'] as num?)?.toInt() ??
          WorldDraft.defaultRadius,
      status: WorldStatus.values.byName(json['status'] as String),
      publishedAt: _date(json['published_at']),
      blocks: [
        for (final block in json['blocks'] as List<dynamic>? ?? const [])
          blockFromJson(block as Map<String, dynamic>),
      ],
      assets: [
        for (final asset in json['assets'] as List<dynamic>? ?? const [])
          WorldAsset(
            id: (asset as Map<String, dynamic>)['id'] as String,
            storagePath: asset['storage_path'] as String,
            mimeType: asset['mime_type'] as String,
          ),
      ],
    );
  }

  static ContentBlock blockFromJson(Map<String, dynamic> json) =>
      ContentBlockCodec.fromJson(json);

  static WorldSummary summaryFromRow(Map<String, dynamic> row) => WorldSummary(
    id: row['id'] as String,
    title: row['title'] as String,
    category: WorldCategory.values.byName(row['category'] as String),
    status: WorldStatus.values.byName(row['status'] as String),
    publishedAt: _date(row['published_at']),
    updatedAt: _date(row['updated_at'])!,
  );

  static String? _nullIfBlank(String value) =>
      value.trim().isEmpty ? null : value;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value) : null;
}
