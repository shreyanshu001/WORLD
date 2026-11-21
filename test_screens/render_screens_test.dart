import 'dart:async';
// Renders the app's main screens to PNG images with sample data, for design
// review. Not part of `flutter test`. Run:
//
//   flutter test test_screens --update-goldens
//
// Images are written to test_screens/screens/ (gitignored). Fonts come from
// the Flutter SDK (Roboto, Android's system font, and Material Icons), so
// text renders as it does on a phone; the map is a stand-in drawing.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/core/maps/map_adapter.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/profile/domain/profile_page.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/worlds/domain/world_details.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../test/support/community_fakes.dart';
import '../test/support/creation_fakes.dart';
import '../test/support/explore_fakes.dart';
import '../test/support/fakes.dart';
import '../test/support/play_fakes.dart';
import '../test/support/pump_app.dart';

Future<void> _loadFonts() async {
  var dir = File(Platform.resolvedExecutable).parent;
  while (!Directory(
    '${dir.path}/bin/cache/artifacts/material_fonts',
  ).existsSync()) {
    dir = dir.parent;
  }
  final fonts = '${dir.path}/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('$fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Roboto', [
    'roboto-light.ttf',
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ]);
  await load('MaterialIcons', ['materialicons-regular.otf']);
}

/// A drawn stand-in for the map: soft land, a few roads and water, and the
/// markers where MapLibre would put them.
class _SketchMapAdapter implements MapAdapter {
  _SketchMapAdapter(this.inner);

  final FakeMapAdapter inner;

  @override
  Widget buildMap(MapViewConfig config) {
    inner.buildMap(config);
    return _SketchMap(config: config);
  }
}

class _SketchMap extends StatelessWidget {
  const _SketchMap({required this.config});

  final MapViewConfig config;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        Offset at(GeoPoint p) => Offset(
          size.width / 2 + (p.longitude + 0.12) * 9000,
          size.height / 2 - (p.latitude - 51.5) * 9000,
        );
        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _MapPainter())),
            for (final area in config.areas)
              Positioned(
                left: size.width / 2 - 60,
                top: size.height / 2 - 60,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(
                      int.parse('33${area.colorHex.substring(1)}', radix: 16),
                    ),
                    border: Border.all(
                      color: Color(
                        int.parse('FF${area.colorHex.substring(1)}', radix: 16),
                      ),
                      width: 2,
                    ),
                  ),
                ),
              ),
            for (final marker in config.markers)
              Positioned(
                left: at(marker.point).dx - 12,
                top: at(marker.point).dy - 12,
                child: GestureDetector(
                  key: ValueKey('marker-${marker.id}'),
                  onTap: () => config.onMarkerTapped(marker.id),
                  child: Container(
                    width: marker.id == config.selectedMarkerId ? 28 : 20,
                    height: marker.id == config.selectedMarkerId ? 28 : 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(
                        int.parse(
                          'FF${marker.colorHex.substring(1)}',
                          radix: 16,
                        ),
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF2EFE9),
    );
    final water = Path()
      ..moveTo(0, size.height * 0.62)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.55,
        size.width * 0.6,
        size.height * 0.75,
        size.width,
        size.height * 0.66,
      )
      ..lineTo(size.width, size.height * 0.78)
      ..cubicTo(
        size.width * 0.6,
        size.height * 0.86,
        size.width * 0.3,
        size.height * 0.68,
        0,
        size.height * 0.74,
      )
      ..close();
    canvas.drawPath(water, Paint()..color = const Color(0xFFAAD3DF));
    final park = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.12,
        size.width * 0.3,
        size.height * 0.18,
      ),
      const Radius.circular(24),
    );
    canvas.drawRRect(park, Paint()..color = const Color(0xFFCDEBB0));
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(
        Offset(0, size.height * 0.4),
        Offset(size.width, size.height * 0.35),
        road,
      )
      ..drawLine(
        Offset(size.width * 0.55, 0),
        Offset(size.width * 0.45, size.height),
        road,
      )
      ..drawLine(
        Offset(size.width * 0.15, size.height),
        Offset(size.width * 0.9, size.height * 0.1),
        road..strokeWidth = 4,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A screen render with real shadows (tests draw them as outlines by default).
void renderTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    debugDisableShadows = false;
    try {
      await body(tester);
    } finally {
      debugDisableShadows = true;
    }
  });
}

void main() {
  const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');
  const center = GeoPoint(latitude: 51.5, longitude: -0.12);
  const place = GeoPoint(latitude: 51.5007, longitude: -0.1246);

  setUpAll(_loadFonts);

  late FakeWorldRepository worlds;
  late FakeWorldAuthoringRepository authoring;
  late FakeMapAdapter map;
  late FakeWorldPlayRepository play;
  late FakeLocationService location;
  late FakeProfileRepository profiles;
  late FakeSavedWorldsRepository saved;

  setUp(() {
    profiles = FakeProfileRepository()
      ..add(
        testProfile(
          alice.id,
          'alice',
          displayName: 'Alice',
          bio: 'Collects harbour stories.',
        ),
      )
      ..add(
        testProfile(
          'mira-id',
          'mira',
          displayName: 'Mira Chen',
          bio: 'Writes short walks along the water.',
        ),
      )
      ..publishedByUsername['mira'] = [
        ProfileWorld(
          id: 'w1',
          title: 'The Lighthouse Keeper',
          category: WorldCategory.story,
          publishedAt: DateTime.utc(2025, 3, 9),
        ),
        ProfileWorld(
          id: 'w5',
          title: 'Tide Clock',
          category: WorldCategory.puzzle,
          publishedAt: DateTime.utc(2025, 2, 2),
        ),
        ProfileWorld(
          id: 'w6',
          title: 'Quay Voices',
          category: WorldCategory.experience,
          publishedAt: DateTime.utc(2024, 11, 18),
        ),
      ]
      ..publishedByUsername['alice'] = [
        ProfileWorld(
          id: 'w4',
          title: 'Market Walk',
          category: WorldCategory.experience,
          publishedAt: DateTime.utc(2025, 4, 1),
        ),
      ]
      ..draftCounts['alice'] = 2
      ..discoveredCounts['alice'] = 7
      ..completedCounts['alice'] = 4;
    saved = FakeSavedWorldsRepository(currentUserId: () => alice.id)
      ..seed(alice.id, [
        testSaved(
          'w1',
          'The Lighthouse Keeper',
          creator: 'mira',
          creatorDisplayName: 'Mira Chen',
          distanceMeters: 240,
        ),
        testSaved(
          'w2',
          'Riddle of the Old Mill',
          category: WorldCategory.puzzle,
          creator: 'jonas',
          creatorDisplayName: null,
          distanceMeters: 650,
        ),
        testSaved(
          'w3',
          'Harbour Mural',
          category: WorldCategory.art,
          creator: 'jonas',
          creatorDisplayName: 'Jonas',
          distanceMeters: 1200,
        ),
      ]);
    worlds = FakeWorldRepository([
      testWorld(
        'w1',
        'The Lighthouse Keeper',
        WorldCategory.story,
        distanceMeters: 240,
        creatorDisplayName: 'Mira Chen',
        latitude: 51.503,
        longitude: -0.125,
      ),
      testWorld(
        'w2',
        'Riddle of the Old Mill',
        WorldCategory.puzzle,
        distanceMeters: 650,
        latitude: 51.497,
        longitude: -0.114,
      ),
      testWorld(
        'w3',
        'Harbour Mural',
        WorldCategory.art,
        distanceMeters: 1200,
        creatorDisplayName: 'Jonas',
        latitude: 51.505,
        longitude: -0.11,
      ),
      testWorld(
        'w4',
        'Market Walk',
        WorldCategory.experience,
        distanceMeters: 2100,
        latitude: 51.494,
        longitude: -0.13,
      ),
    ]);
    worlds.detailsById['w1'] = testDetails(
      'w1',
      'The Lighthouse Keeper',
      WorldCategory.story,
      description:
          'Every night for forty years, someone kept this light burning. '
          'Follow the keeper\'s last log through the harbour and decide how '
          'their story ends.',
      distanceMeters: 240,
      blockCount: 7,
      unlockRadiusMeters: 50,
    );
    authoring = FakeWorldAuthoringRepository();
    map = FakeMapAdapter();
    location = FakeLocationService()
      ..permission = LocationPermissionStatus.granted;
    play = FakeWorldPlayRepository()
      ..addWorld(
        'w1',
        testStoryBlocks(),
        title: 'The Lighthouse Keeper',
        unlocked: true,
      )
      ..addWorld(
        'w2',
        testPuzzleBlocks(),
        title: 'Riddle of the Old Mill',
        unlocked: true,
      )
      ..answers['p-q'] = 'keeper'
      ..successMessages['p-q'] = 'Right, the keeper! The light never went out.';
  });

  Future<void> pump(WidgetTester tester, {bool signedIn = true}) async {
    usePhoneScreen(tester);
    await pumpWorldsApp(
      tester,
      auth: FakeAuthRepository(signedInAs: signedIn ? alice : null),
      profiles: profiles,
      saved: saved,
      worlds: worlds,
      authoring: authoring,
      map: map,
      mapAdapter: _SketchMapAdapter(map),
      play: play,
      location: location,
      exploreDefaultCenter: center,
    );
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screens/$name.png'),
    );
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  renderTest('explore', (tester) async {
    await pump(tester);
    await shot(tester, '01_explore');
    await tester.tap(find.byKey(const ValueKey('marker-w1')));
    await shot(tester, '02_explore_selected');
    await tester.tap(find.byTooltip('Show as list'));
    await shot(tester, '03_explore_list');
  });

  renderTest('details', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('marker-w1')));
    await tester.pumpAndSettle();
    await tapText(tester, 'View details');
    await shot(tester, '04_details');
  });

  renderTest('create empty and list', (tester) async {
    await pump(tester);
    await tapTab(tester, 'Create');
    await shot(tester, '05_create_empty');
  });

  renderTest('create with worlds', (tester) async {
    authoring.worlds['d1'] = const WorldDraft(
      id: 'd1',
      category: WorldCategory.story,
      title: 'Pier Ghost',
    );
    authoring.worlds['p1'] = WorldDraft(
      id: 'p1',
      category: WorldCategory.art,
      title: 'Harbour Mural',
      status: WorldStatus.published,
      publishedAt: DateTime.utc(2026, 11, 18),
    );
    authoring.worlds['p2'] = WorldDraft(
      id: 'p2',
      category: WorldCategory.puzzle,
      title: 'Riddle of the Old Mill',
      status: WorldStatus.published,
      publishedAt: DateTime.utc(2026, 11, 12),
    );
    await pump(tester);
    await tapTab(tester, 'Create');
    await shot(tester, '06_create_list');
  });

  renderTest('editor steps', (tester) async {
    await pump(tester);
    await tapTab(tester, 'Create');
    await tapText(tester, 'Start a World');
    await shot(tester, '07_editor_category');
    await tapText(tester, 'Story');
    await tester.enterText(
      find.widgetWithText(TextField, 'Title'),
      'The Lighthouse Keeper',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Description'),
      'Follow the keeper\'s last log through the harbour.',
    );
    await shot(tester, '08_editor_details');
    await tapText(tester, 'Save and continue');
    map.userMovesMapTo(place, zoom: 17);
    await shot(tester, '09_editor_place');
    await tapText(tester, 'Save and continue');
    await tapText(tester, 'Add a part');
    await shot(tester, '10_editor_add_part');
    await tapText(tester, 'Text');
    await tester.enterText(
      find.widgetWithText(TextField, 'Text'),
      'The light was still warm when I found the log book.',
    );
    await tapText(tester, 'Add a part');
    await tapText(tester, 'Choice');
    await shot(tester, '11_editor_content');
    await tapText(tester, '5. Publish');
    await shot(tester, '12_editor_review');
  });

  renderTest('preview', (tester) async {
    authoring.worlds['s1'] = const WorldDraft(
      id: 's1',
      category: WorldCategory.story,
      title: 'The Lighthouse Keeper',
      description: 'Choose.',
      location: place,
      blocks: [
        ContentBlock.text(
          id: 'intro',
          body:
              'The light was still warm when I found the log book. The last entry was dated tonight.',
        ),
        ContentBlock.storyChoice(
          id: 'choice',
          prompt: 'Do you read the last page?',
          options: [
            StoryOption(
              id: 'o1',
              label: 'Read it now',
              destinationBlockId: 'left',
            ),
            StoryOption(
              id: 'o2',
              label: 'Climb the stairs first',
              destinationBlockId: 'right',
            ),
          ],
        ),
        ContentBlock.completion(
          id: 'left',
          title: 'The keeper\'s secret',
          message: 'L',
        ),
        ContentBlock.completion(
          id: 'right',
          title: 'Up the stairs',
          message: 'R',
        ),
      ],
    );
    await pump(tester);
    await tapTab(tester, 'Create');
    await tapText(tester, 'The Lighthouse Keeper');
    await tapText(tester, '5. Publish');
    await shot(tester, '13_review_ready');
    await tapText(tester, 'Preview as an explorer');
    await tapText(tester, 'Continue');
    await shot(tester, '14_preview_choice');
  });

  Future<void> openPlayer(WidgetTester tester, String worldId) async {
    await pump(tester);
    unawaited(
      GoRouter.of(
        tester.element(find.byType(NavigationBar)),
      ).push<void>(AppRoutes.play(worldId)),
    );
    await tester.pumpAndSettle();
  }

  renderTest('unlock', (tester) async {
    worlds.detailsById['w1'] = worlds.detailsById['w1']!.copyWith(
      playStatus: PlayStatus.locked,
    );
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('marker-w1')));
    await tester.pumpAndSettle();
    await tapText(tester, 'View details');
    await shot(tester, '15_details_locked');
    await tapText(tester, 'Check my location');
    await shot(tester, '16_details_too_far');
  });

  renderTest('player story', (tester) async {
    await openPlayer(tester, 'w1');
    await shot(tester, '17_player_text');
    await tapText(tester, 'Continue');
    await shot(tester, '18_player_choice');
  });

  renderTest('player puzzle', (tester) async {
    await openPlayer(tester, 'w2');
    await tapText(tester, 'Continue');
    await tester.enterText(
      find.widgetWithText(TextField, 'Your answer'),
      'the cook',
    );
    await tester.pump();
    await tapText(tester, 'Check answer');
    await shot(tester, '19_player_wrong');
    await tester.enterText(
      find.widgetWithText(TextField, 'Your answer'),
      'keeper',
    );
    await tester.pump();
    await tapText(tester, 'Check answer');
    await shot(tester, '20_player_correct');
    await tapText(tester, 'Continue');
    await tapText(tester, 'Finish');
    await shot(tester, '21_player_complete');
  });

  renderTest('saved and reporting', (tester) async {
    worlds.detailsById['w1'] = worlds.detailsById['w1']!.copyWith(
      creatorUsername: 'mira',
      creatorDisplayName: 'Mira Chen',
      playStatus: PlayStatus.locked,
      isSaved: true,
    );
    await pump(tester);
    await tapTab(tester, 'Saved');
    await shot(tester, '22_saved');
    await tapText(tester, 'The Lighthouse Keeper');
    await shot(tester, '23_details_saved');
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Report this World');
    await tapText(tester, 'Unsafe or private place');
    await shot(tester, '24_report');
    await tapText(tester, 'Send report');
    await shot(tester, '25_report_sent');
  });

  renderTest('saved, empty', (tester) async {
    saved.savedByUser[alice.id]!.clear();
    await pump(tester);
    await tapTab(tester, 'Saved');
    await shot(tester, '26_saved_empty');
  });

  renderTest('profiles', (tester) async {
    await pump(tester);
    await tapTab(tester, 'Profile');
    await shot(tester, '27_profile');
    unawaited(
      GoRouter.of(
        tester.element(find.byType(NavigationBar)),
      ).push<void>(AppRoutes.creatorPage('mira')),
    );
    await tester.pumpAndSettle();
    await shot(tester, '28_creator');
  });
}
