/// Route paths used across the app.
abstract final class AppRoutes {
  static const explore = '/explore';
  static const saved = '/saved';
  static const create = '/create';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const signIn = '/sign-in';
  static const register = '/register';

  /// A World's details, opened from Explore.
  static String worldDetails(String worldId) => '$explore/worlds/$worldId';

  /// The creator's editor for a new World with a fresh client-chosen id.
  static String newWorld(String worldId) =>
      Uri(path: '$create/new', queryParameters: {'id': worldId}).toString();

  /// The creator's editor for an existing World.
  static String editWorld(String worldId) => '$create/worlds/$worldId';

  /// The sign-in page, returning to [from] once signed in.
  static String signInFrom(String from) =>
      Uri(path: signIn, queryParameters: {'from': from}).toString();

  /// The sign-up page, returning to [from] once signed in.
  static String registerFrom(String from) =>
      Uri(path: register, queryParameters: {'from': from}).toString();

  /// [from] if it is a safe in-app destination after signing in, otherwise
  /// the profile tab.
  static String safeReturnPath(String? from) {
    if (from == null || !from.startsWith('/') || from.startsWith('//')) {
      return profile;
    }
    final path = Uri.tryParse(from)?.path;
    if (path == null || path == signIn || path == register) return profile;
    return from;
  }
}

/// Where the router should send the user instead of [uri], or null to stay.
///
/// - Signed-in users never see the sign-in or sign-up pages.
/// - Signed-out users cannot open pages that edit their own data.
///
/// go_router applies this to the current location only. Pages opened with
/// `push` keep the location of the page below, so the sign-in and sign-up
/// pages also leave on their own after success.
String? authRedirect({required bool signedIn, required Uri uri}) {
  final path = uri.path;
  if (signedIn && (path == AppRoutes.signIn || path == AppRoutes.register)) {
    return AppRoutes.safeReturnPath(uri.queryParameters['from']);
  }
  if (!signedIn && path == AppRoutes.editProfile) {
    return AppRoutes.signInFrom(AppRoutes.editProfile);
  }
  // The creator's pages below the Create tab need an account; the tab itself
  // explains why and offers sign-in.
  if (!signedIn && path.startsWith('${AppRoutes.create}/')) {
    return AppRoutes.signInFrom(AppRoutes.create);
  }
  return null;
}
