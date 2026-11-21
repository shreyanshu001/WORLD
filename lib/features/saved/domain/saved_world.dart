import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worlds/shared/models/world_category.dart';

part 'saved_world.freezed.dart';
part 'saved_world.g.dart';

/// A World the signed-in user saved, as returned by `get_saved_worlds`.
/// Only Worlds that are published right now are listed.
@freezed
abstract class SavedWorld with _$SavedWorld {
  const factory SavedWorld({
    required String id,
    required String title,
    required WorldCategory category,
    required String creatorUsername,
    String? creatorDisplayName,

    /// Storage path of the cover image, if there is one.
    String? coverPath,

    /// From the position the app passed, computed by the server.
    double? distanceMeters,
    required DateTime savedAt,
  }) = _SavedWorld;

  const SavedWorld._();

  factory SavedWorld.fromJson(Map<String, dynamic> json) =>
      _$SavedWorldFromJson(json);

  /// The name to credit: the display name if set, otherwise @username.
  String get creatorName => creatorDisplayName ?? '@$creatorUsername';
}

/// One page of the saved list.
class SavedPage {
  const SavedPage({
    required this.items,
    required this.hasMore,
    this.unavailable = 0,
  });

  factory SavedPage.fromJson(Map<String, dynamic> json) => SavedPage(
    items: [
      for (final item in json['items'] as List<dynamic>? ?? const [])
        SavedWorld.fromJson(item as Map<String, dynamic>),
    ],
    hasMore: json['has_more'] as bool? ?? false,
    unavailable: (json['unavailable'] as num?)?.toInt() ?? 0,
  );

  final List<SavedWorld> items;
  final bool hasMore;

  /// Saved Worlds that are unpublished, hidden or deleted at the moment.
  /// They stay saved and come back if they are published again.
  final int unavailable;
}
