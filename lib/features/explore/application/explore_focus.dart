import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/shared/models/geo_point.dart';

/// A request from another screen to show one World on the Explore map.
@immutable
class ExploreFocusRequest {
  const ExploreFocusRequest({
    required this.id,
    required this.worldId,
    required this.point,
  });

  /// A new id means a new request.
  final int id;
  final String worldId;
  final GeoPoint point;
}

final exploreFocusProvider =
    NotifierProvider<ExploreFocusNotifier, ExploreFocusRequest?>(
      ExploreFocusNotifier.new,
    );

/// Holds the latest focus request until Explore has handled it.
class ExploreFocusNotifier extends Notifier<ExploreFocusRequest?> {
  int _sequence = 0;

  @override
  ExploreFocusRequest? build() => null;

  void focus({required String worldId, required GeoPoint point}) {
    state = ExploreFocusRequest(
      id: ++_sequence,
      worldId: worldId,
      point: point,
    );
  }

  /// Called by Explore once it has moved to the World.
  void handled(int requestId) {
    if (state?.id == requestId) state = null;
  }
}
