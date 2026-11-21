import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/app/app.dart';
import 'package:worlds/core/location/location_providers.dart';
import 'package:worlds/core/maps/map_adapter.dart';
import 'package:worlds/core/maps/map_providers.dart';
import 'package:worlds/core/media/media_providers.dart';
import 'package:worlds/features/world_creation/application/authoring_providers.dart';
import 'package:worlds/features/world_player/application/play_providers.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/explore/application/explore_controller.dart';
import 'package:worlds/features/moderation/application/report_providers.dart';
import 'package:worlds/features/profile/application/profile_providers.dart';
import 'package:worlds/features/saved/application/saved_providers.dart';
import 'package:worlds/features/worlds/application/world_providers.dart';
import 'package:worlds/shared/models/geo_point.dart';

import 'community_fakes.dart';
import 'creation_fakes.dart';
import 'explore_fakes.dart';
import 'play_fakes.dart';
import 'fakes.dart';

/// Pumps the whole app with in-memory repositories, a fake map and a fake
/// location service.
Future<void> pumpWorldsApp(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  FakeProfileRepository? profiles,
  FakeWorldRepository? worlds,
  FakeLocationService? location,
  FakeMapAdapter? map,

  /// Replaces [map] as the drawn map, for screen renders.
  MapAdapter? mapAdapter,
  FakeWorldMediaRepository? media,
  FakeWorldAuthoringRepository? authoring,
  FakeImagePickerService? picker,
  FakeWorldPlayRepository? play,
  FakeSavedWorldsRepository? saved,
  FakeReportRepository? reports,
  GeoPoint? exploreDefaultCenter,
  List<Override> extraOverrides = const [],

  /// Set false when something keeps animating (such as a search held open).
  bool settle = true,
}) async {
  // The fakes answer for whoever is signed in, as the server does.
  final profileRepository = profiles ?? FakeProfileRepository();
  profileRepository.currentUserId ??= () => auth.currentUser?.id;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(profileRepository),
        savedWorldsRepositoryProvider.overrideWithValue(
          saved ??
              FakeSavedWorldsRepository(
                currentUserId: () => auth.currentUser?.id,
              ),
        ),
        reportRepositoryProvider.overrideWithValue(
          reports ?? FakeReportRepository(),
        ),
        worldRepositoryProvider.overrideWithValue(
          worlds ?? FakeWorldRepository(),
        ),
        worldMediaRepositoryProvider.overrideWithValue(
          media ?? FakeWorldMediaRepository(),
        ),
        worldAuthoringRepositoryProvider.overrideWithValue(
          authoring ?? FakeWorldAuthoringRepository(),
        ),
        imagePickerServiceProvider.overrideWithValue(
          picker ?? FakeImagePickerService(),
        ),
        worldPlayRepositoryProvider.overrideWithValue(
          play ?? FakeWorldPlayRepository(),
        ),
        ...extraOverrides,
        locationServiceProvider.overrideWithValue(
          location ?? FakeLocationService(),
        ),
        mapAdapterProvider.overrideWithValue(
          mapAdapter ?? map ?? FakeMapAdapter(),
        ),
        exploreDefaultCenterProvider.overrideWithValue(exploreDefaultCenter),
      ],
      retry: noAutomaticRetry,
      child: const WorldsApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
}

/// Sizes the test screen like a common Android phone (411 × 891 dp) instead
/// of the default 800 × 600.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

/// Moves the app through the real lifecycle sequence to the background and
/// back, as when the user visits system settings.
void leaveAndReturnToApp(WidgetTester tester) {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

/// Taps a bottom-navigation destination.
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Types [text] into the form field labelled [label].
Future<void> enterField(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), text);
  await tester.pump();
}

/// Taps the filled button labelled [label] and waits for the result.
Future<void> tapFilledButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}
