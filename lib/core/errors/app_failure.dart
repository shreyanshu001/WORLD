import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

/// A failure the user can be told about.
///
/// Data-layer code maps backend, network and platform errors to one of these
/// cases and throws it. Raw SQL, PostgREST or SDK error text must never reach
/// the UI.
@freezed
sealed class AppFailure with _$AppFailure implements Exception {
  /// The action needs a signed-in user.
  const factory AppFailure.unauthenticated() = UnauthenticatedFailure;

  /// The signed-in user is not allowed to do this.
  const factory AppFailure.permissionDenied() = PermissionDeniedFailure;

  /// The device could not provide a location.
  const factory AppFailure.locationUnavailable() = LocationUnavailableFailure;

  /// A location was available but too old or too imprecise to use.
  const factory AppFailure.locationInaccurate() = LocationInaccurateFailure;

  /// The requested item does not exist or is not visible to this user.
  const factory AppFailure.notFound() = NotFoundFailure;

  /// The World exists but is not published.
  const factory AppFailure.unpublished() = UnpublishedFailure;

  /// The World is outside its unlock radius.
  const factory AppFailure.locked() = LockedFailure;

  /// The server rejected the submitted content.
  const factory AppFailure.invalidContent() = InvalidContentFailure;

  /// A media upload did not complete.
  const factory AppFailure.uploadFailed() = UploadFailedFailure;

  /// Too many attempts in a short time.
  const factory AppFailure.rateLimited() = RateLimitedFailure;

  /// The device has no usable network connection.
  const factory AppFailure.offline() = OfflineFailure;

  /// The email and password do not match an account.
  const factory AppFailure.invalidCredentials() = InvalidCredentialsFailure;

  /// An account already exists for this email address.
  const factory AppFailure.accountExists() = AccountExistsFailure;

  /// The password does not meet the server's strength rules.
  const factory AppFailure.weakPassword() = WeakPasswordFailure;

  /// The email address must be confirmed before signing in.
  const factory AppFailure.emailNotConfirmed() = EmailNotConfirmedFailure;

  /// This email address cannot be used to sign up at the moment.
  const factory AppFailure.emailNotAllowed() = EmailNotAllowedFailure;

  /// New accounts cannot be created at the moment.
  const factory AppFailure.signUpDisabled() = SignUpDisabledFailure;

  /// The username belongs to someone else.
  const factory AppFailure.usernameTaken() = UsernameTakenFailure;

  /// Anything that does not fit another case.
  const factory AppFailure.unexpected() = UnexpectedFailure;
}

/// Plain-language text for each [AppFailure].
extension AppFailureMessage on AppFailure {
  String get userMessage => switch (this) {
    UnauthenticatedFailure() => 'Please sign in to continue.',
    PermissionDeniedFailure() => "You don't have permission to do that.",
    LocationUnavailableFailure() =>
      "We couldn't get your location. Check that location is turned on.",
    LocationInaccurateFailure() =>
      "Your location isn't precise enough yet. Move to open sky and try again.",
    NotFoundFailure() => "We couldn't find that.",
    UnpublishedFailure() => "This World isn't published.",
    LockedFailure() => "You're not close enough to unlock this World yet.",
    InvalidContentFailure() =>
      "Some of the content isn't valid. Review it and try again.",
    UploadFailedFailure() => 'The upload failed. Try again.',
    RateLimitedFailure() => 'Too many attempts. Wait a moment and try again.',
    OfflineFailure() => "You're offline. Check your connection and try again.",
    InvalidCredentialsFailure() => 'Incorrect email or password.',
    AccountExistsFailure() =>
      'An account with this email already exists. Try signing in.',
    WeakPasswordFailure() => 'Choose a stronger password.',
    EmailNotConfirmedFailure() =>
      'Confirm your email address first. Check your inbox for the link.',
    EmailNotAllowedFailure() =>
      "This email address can't be used to sign up right now. "
          'Try a different one.',
    SignUpDisabledFailure() => "New accounts can't be created right now.",
    UsernameTakenFailure() => 'That username is taken. Try another.',
    UnexpectedFailure() => 'Something went wrong. Try again.',
  };
}

/// The user-facing message for any error caught in the UI layer.
String messageForError(Object? error) => switch (error) {
  final AppFailure failure => failure.userMessage,
  _ => const AppFailure.unexpected().userMessage,
};
