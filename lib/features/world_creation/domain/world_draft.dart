import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

part 'world_draft.freezed.dart';

/// An image registered to a World.
@freezed
abstract class WorldAsset with _$WorldAsset {
  const factory WorldAsset({
    required String id,
    required String storagePath,
    required String mimeType,
  }) = _WorldAsset;
}

/// The creator's editable copy of a World.
@freezed
abstract class WorldDraft with _$WorldDraft {
  const factory WorldDraft({
    required String id,
    required WorldCategory category,
    @Default('') String title,
    @Default('') String description,
    String? coverAssetId,
    GeoPoint? location,
    @Default(WorldDraft.defaultRadius) int unlockRadiusMeters,
    @Default(<ContentBlock>[]) List<ContentBlock> blocks,
    @Default(WorldStatus.draft) WorldStatus status,
    DateTime? publishedAt,
    @Default(<WorldAsset>[]) List<WorldAsset> assets,
  }) = _WorldDraft;

  const WorldDraft._();

  /// docs/PRODUCT_SPEC.md: 50 m by default, 25–150 m allowed.
  static const defaultRadius = 50;

  WorldLifecycle get lifecycle => WorldLifecycle.of(status, publishedAt);

  WorldAsset? assetById(String? id) {
    if (id == null) return null;
    for (final asset in assets) {
      if (asset.id == id) return asset;
    }
    return null;
  }

  /// Ids of assets the cover or a block uses.
  Set<String> get usedAssetIds => {
    ?coverAssetId,
    for (final block in blocks) ?block.imageAssetId,
  };

  ContentBlock? blockById(String id) {
    for (final block in blocks) {
      if (block.id == id) return block;
    }
    return null;
  }
}

/// A row in the creator's list of their own Worlds.
@freezed
abstract class WorldSummary with _$WorldSummary {
  const factory WorldSummary({
    required String id,
    required String title,
    required WorldCategory category,
    required WorldStatus status,
    DateTime? publishedAt,
    required DateTime updatedAt,
  }) = _WorldSummary;

  const WorldSummary._();

  WorldLifecycle get lifecycle => WorldLifecycle.of(status, publishedAt);
}
