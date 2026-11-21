import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worlds/shared/models/world_category.dart';

part 'profile_page.freezed.dart';
part 'profile_page.g.dart';

/// A published World on the page of its creator.
@freezed
abstract class ProfileWorld with _$ProfileWorld {
  const factory ProfileWorld({
    required String id,
    required String title,
    required WorldCategory category,
    String? coverPath,
    DateTime? publishedAt,
  }) = _ProfileWorld;

  factory ProfileWorld.fromJson(Map<String, dynamic> json) =>
      _$ProfileWorldFromJson(json);
}

/// A profile as `get_profile_page` returns it: the public fields and
/// published Worlds for everyone, and the private counts only for the
/// owner. Every number is counted by the server from real rows.
@freezed
abstract class ProfilePage with _$ProfilePage {
  const factory ProfilePage({
    required String username,
    String? displayName,
    String? bio,
    @Default(false) bool isOwn,
    required int publishedCount,

    /// Null unless this is the page of the signed-in user.
    int? draftCount,
    int? discoveredCount,
    int? completedCount,
    @Default(<ProfileWorld>[]) List<ProfileWorld> worlds,
    @Default(false) bool hasMore,
  }) = _ProfilePage;

  const ProfilePage._();

  factory ProfilePage.fromJson(Map<String, dynamic> json) =>
      _$ProfilePageFromJson(json);

  /// The name to show: the display name if set, otherwise @username.
  String get name => displayName ?? '@$username';
}
