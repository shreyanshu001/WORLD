import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

/// A failure the user can be told about.
///
/// Data-layer code maps backend, network and platform errors to one of these
/// cases. Raw SQL, PostgREST or SDK error text must never reach the UI.
@freezed
sealed class AppFailure with _$AppFailure {
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
    UnexpectedFailure() => 'Something went wrong. Try again.',
  };
}
