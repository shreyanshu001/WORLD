import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

part 'world_details.freezed.dart';
part 'world_details.g.dart';

/// Where a signed-in user stands with a World. Values match
/// `get_world_details.play_status`.
enum PlayStatus {
  @JsonValue('locked')
  locked,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
}

/// What anyone may know about a World before playing it, as returned by
/// `get_world_details`. It never includes content blocks or answers.
@freezed
abstract class WorldDetails with _$WorldDetails {
  const factory WorldDetails({
    required String id,
    required String title,
    String? description,
    required WorldCategory category,
    required int unlockRadiusMeters,

    /// Null only for the creator's own draft without a location yet.
    double? latitude,
    double? longitude,

    /// From the position the app passed, computed by the server.
    double? distanceMeters,
    required String creatorUsername,
    String? creatorDisplayName,

    /// Storage path of the cover image, if there is one.
    String? coverPath,
    required int blockCount,
    required WorldStatus status,
    DateTime? publishedAt,

    /// Whether the signed-in user created this World.
    @Default(false) bool isCreator,

    /// Where the signed-in user stands with it; null when signed out.
    PlayStatus? playStatus,

    /// Whether the signed-in user saved it; null when signed out.
    bool? isSaved,
  }) = _WorldDetails;

  const WorldDetails._();

  factory WorldDetails.fromJson(Map<String, dynamic> json) =>
      _$WorldDetailsFromJson(json);

  GeoPoint? get point => latitude == null || longitude == null
      ? null
      : GeoPoint(latitude: latitude!, longitude: longitude!);

  /// The name to credit: the display name if set, otherwise @username.
  String get creatorName => creatorDisplayName ?? '@$creatorUsername';

  WorldLifecycle get lifecycle => WorldLifecycle.of(status, publishedAt);
}
