import 'package:worlds/features/worlds/domain/world_details.dart';
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

/// Reads Worlds for discovery. Creating and editing live in
/// `features/world_creation`.
///
/// Every method throws an `AppFailure` when it fails.
abstract interface class WorldRepository {
  /// Published public Worlds near [query]'s centre, nearest first.
  Future<List<WorldPreview>> nearby(NearbyQuery query);

  /// Safe details of one World: published public Worlds for everyone, and
  /// the signed-in creator's own Worlds. Distance is measured from [from]
  /// when given. Throws `AppFailure.notFound` otherwise.
  Future<WorldDetails> details(String worldId, {GeoPoint? from});
}

/// Shows stored World images. Files are private; each one is shown through
/// a short-lived address the server signs only if the viewer may see it.
abstract interface class WorldMediaRepository {
  Future<Uri> imageUrl(String storagePath);
}
