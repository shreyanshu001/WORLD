import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

part 'world_preview.freezed.dart';
part 'world_preview.g.dart';

/// The public summary of a published World, as returned by nearby search.
@freezed
abstract class WorldPreview with _$WorldPreview {
  const factory WorldPreview({
    required String id,
    required String title,
    required WorldCategory category,
    required double latitude,
    required double longitude,

    /// Computed by the server from the search centre.
    required double distanceMeters,
    required String creatorUsername,
    String? creatorDisplayName,
  }) = _WorldPreview;

  const WorldPreview._();

  factory WorldPreview.fromJson(Map<String, dynamic> json) =>
      _$WorldPreviewFromJson(json);

  GeoPoint get point => GeoPoint(latitude: latitude, longitude: longitude);

  /// The name to credit: the display name if set, otherwise @username.
  String get creatorName => creatorDisplayName ?? '@$creatorUsername';
}
