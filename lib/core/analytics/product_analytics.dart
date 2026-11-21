import 'dart:async';

/// How an unlock attempt ended. No distance and no accuracy: only which of
/// these it was.
enum UnlockOutcome {
  unlocked('unlocked'),
  tooFar('too_far'),
  inaccurate('inaccurate'),

  /// No reading: permission refused, location off, or no fix in time.
  noLocation('no_location'),

  /// The server could not be asked.
  failed('failed');

  const UnlockOutcome(this.wire);

  final String wire;
}

/// Where events are sent. An implementation may fail in any way it likes;
/// [ProductAnalytics] never lets a failure reach the app.
abstract interface class ProductEventSink {
  Future<void> send({
    required String sessionId,
    required String name,
    String? worldId,
    String? outcome,
  });
}

/// The few things the pilot needs to know that the server cannot see for
/// itself (docs/DECISIONS.md, D-039): that Explore was opened, a World
/// selected on it, details opened and an unlock attempted.
///
/// Its methods take no position, so none can be sent. Events carry a random
/// id made when the app starts, not the account, and that id is never stored
/// on the device. (The server can still work out the account for a launch
/// that unlocked a World, by time: see D-039.) Nothing here waits or throws:
/// analytics must never slow down or break what the user is doing.
class ProductAnalytics {
  ProductAnalytics({required ProductEventSink sink, required this.sessionId})
    : _sink = sink;

  final ProductEventSink _sink;

  /// Random, per launch, in memory only.
  final String sessionId;

  bool _exploreOpened = false;
  final _detailsOpened = <String>{};

  /// Once per launch.
  void exploreOpened() {
    if (_exploreOpened) return;
    _exploreOpened = true;
    _send('explore_opened');
  }

  void worldSelected() => _send('world_marker_selected');

  /// Once per World per launch, however often its details reload. The World
  /// is counted in a daily total on the server; the event row does not
  /// name it.
  void detailsOpened(String worldId) {
    if (!_detailsOpened.add(worldId)) return;
    _send('world_details_opened', worldId: worldId);
  }

  void unlockAttempted(String worldId, UnlockOutcome outcome) =>
      _send('world_unlock_attempted', worldId: worldId, outcome: outcome.wire);

  void _send(String name, {String? worldId, String? outcome}) {
    unawaited(
      Future<void>.sync(
        () => _sink.send(
          sessionId: sessionId,
          name: name,
          worldId: worldId,
          outcome: outcome,
        ),
      ).catchError((Object _) {}),
    );
  }
}
