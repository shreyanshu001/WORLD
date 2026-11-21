import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/network/backend_failure.dart';
import 'package:worlds/features/profile/domain/profile.dart';
import 'package:worlds/features/profile/domain/profile_page.dart';
import 'package:worlds/features/profile/domain/profile_repository.dart';

/// [ProfileRepository] backed by the `public.profiles` table.
///
/// Row-level security decides what each user may read and change; this class
/// only translates requests and errors.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'profiles';
  static const _columns =
      'id, username, display_name, bio, avatar_path, created_at, updated_at';

  @override
  Future<Profile> fetchProfile(String userId) async {
    try {
      final row = await _client
          .from(_table)
          .select(_columns)
          .eq('id', userId)
          .single();
      return Profile.fromJson(row);
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }

  @override
  Future<Profile> updateProfile({
    required String userId,
    required String username,
    String? displayName,
    String? bio,
  }) async {
    try {
      final row = await _client
          .from(_table)
          .update({
            'username': username,
            'display_name': displayName,
            'bio': bio,
          })
          .eq('id', userId)
          .select(_columns)
          .single();
      return Profile.fromJson(row);
    } on PostgrestException catch (error) {
      // 23505: unique_violation. The only unique column clients can write is
      // the username.
      if (error.code == '23505') throw const AppFailure.usernameTaken();
      throw failureFromError(error);
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }

  @override
  Future<ProfilePage> page(String username, {int offset = 0}) async {
    try {
      final json = await _client.rpc<Map<String, dynamic>>(
        'get_profile_page',
        params: {
          'profile_username': username,
          'page_size': ProfileRepository.worldsPageSize,
          'page_offset': offset,
        },
      );
      return ProfilePage.fromJson(json);
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final row = await _client
          .from(_table)
          .select('id')
          .eq('username', username)
          .maybeSingle();
      return row == null;
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }
}
