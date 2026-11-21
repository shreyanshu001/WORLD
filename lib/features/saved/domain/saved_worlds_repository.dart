import 'package:worlds/features/saved/domain/saved_world.dart';
import 'package:worlds/shared/models/geo_point.dart';

/// The signed-in user's saved Worlds. Saved lists are private: the server
/// returns and changes only the list of whoever is asking.
///
/// Every method throws an `AppFailure` when it fails.
abstract interface class SavedWorldsRepository {
  /// How many Worlds one request returns.
  static const pageSize = 20;

  /// Saved Worlds from [offset], newest save first. Distance is measured
  /// from [from] when given.
  Future<SavedPage> list({int offset = 0, GeoPoint? from});

  /// Saves or removes a World. Repeating a request changes nothing, so a
  /// retry is safe.
  Future<void> setSaved(String worldId, {required bool saved});
}
