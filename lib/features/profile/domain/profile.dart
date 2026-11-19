import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// A user's public profile. Every field is visible to everyone.
@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String username,
    String? displayName,
    String? bio,
    String? avatarPath,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
