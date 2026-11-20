import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/app_shell.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/auth/presentation/register_screen.dart';
import 'package:worlds/features/auth/presentation/sign_in_screen.dart';
import 'package:worlds/features/explore/presentation/explore_screen.dart';
import 'package:worlds/features/profile/presentation/edit_profile_screen.dart';
import 'package:worlds/features/profile/presentation/profile_screen.dart';
import 'package:worlds/features/saved/presentation/saved_screen.dart';
import 'package:worlds/features/world_creation/presentation/create_screen.dart';
import 'package:worlds/features/world_creation/presentation/world_editor_screen.dart';
import 'package:worlds/features/worlds/presentation/world_details_screen.dart';
import 'package:worlds/shared/models/geo_point.dart';

/// The app's router: one shell with a tab for each top-level section, plus
/// full-screen sign-in and sign-up pages.
///
/// Each tab keeps its own navigation stack. Routing re-evaluates whenever
/// the user signs in or out.
final appRouterProvider = Provider<GoRouter>((ref) {
  final signedIn = ValueNotifier<bool>(
    ref.read(authRepositoryProvider).currentUser != null,
  );
  ref.listen(
    currentUserProvider,
    (_, user) => signedIn.value = user != null,
    fireImmediately: true,
  );

  final router = GoRouter(
    initialLocation: AppRoutes.explore,
    refreshListenable: signedIn,
    redirect: (context, state) =>
        authRedirect(signedIn: signedIn.value, uri: state.uri),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.explore,
                builder: (context, state) => const ExploreScreen(),
                routes: [
                  GoRoute(
                    path: 'worlds/:id',
                    builder: (context, state) => WorldDetailsScreen(
                      worldId: state.pathParameters['id']!,
                      from: state.extra is GeoPoint
                          ? state.extra! as GeoPoint
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.saved,
                builder: (context, state) => const SavedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.create,
                builder: (context, state) => const CreateScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    // The id is chosen before the editor opens, so a rebuild
                    // keeps editing the same new World.
                    redirect: (context, state) =>
                        state.uri.queryParameters['id'] == null
                        ? AppRoutes.create
                        : null,
                    builder: (context, state) {
                      final id = state.uri.queryParameters['id']!;
                      return WorldEditorScreen(
                        key: ValueKey('new-$id'),
                        worldId: id,
                        isNew: true,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'worlds/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return WorldEditorScreen(
                        key: ValueKey('edit-$id'),
                        worldId: id,
                        isNew: false,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) =>
            SignInScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) =>
            RegisterScreen(from: state.uri.queryParameters['from']),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    signedIn.dispose();
  });
  return router;
});
