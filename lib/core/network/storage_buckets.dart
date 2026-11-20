/// Supabase Storage bucket names, from the migrations.
abstract final class StorageBuckets {
  /// Private bucket for World images. Paths are
  /// `<owner id>/<world id>/<asset id>.<jpg|png|webp>`.
  static const worldMedia = 'world-media';
}
