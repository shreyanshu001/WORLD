import 'package:worlds/features/worlds/domain/world_preview.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

/// A nearby search. The server clamps every value.
class NearbyQuery {
  const NearbyQuery({
    required this.center,
    this.radiusMeters = defaultRadiusMeters,
    this.category,
    this.searchText,
  });

  /// docs/PRODUCT_SPEC.md: default discovery radius is 5 km.
  static const defaultRadiusMeters = 5000;

  final GeoPoint center;
  final int radiusMeters;
  final WorldCategory? category;

  /// Title search; null or blank means no filter.
  final String? searchText;

  @override
  bool operator ==(Object other) =>
      other is NearbyQuery &&
      other.center == center &&
      other.radiusMeters == radiusMeters &&
      other.category == category &&
      other.searchText == searchText;

  @override
  int get hashCode => Object.hash(center, radiusMeters, category, searchText);
}

/// Reads Worlds. Creation and publishing arrive in Checkpoint 4.
///
/// Every method throws an `AppFailure` when it fails.
abstract interface class WorldRepository {
  /// Published public Worlds near [query]'s centre, nearest first.
  Future<List<WorldPreview>> nearby(NearbyQuery query);
}
