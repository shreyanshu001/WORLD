import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

/// The signed-in account, as far as the app needs to know it.
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({required String id, String? email}) = _AuthUser;
}
