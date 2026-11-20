/// A World's stored status. Values match the database's `status` column.
enum WorldStatus { draft, published, hidden, deleted }

/// What a creator sees. The database has no "unpublished" status: an
/// unpublished World is a draft that has a publish date.
enum WorldLifecycle {
  draft('Draft'),
  published('Published'),
  unpublished('Unpublished'),
  hidden('Hidden');

  const WorldLifecycle(this.label);

  final String label;

  static WorldLifecycle of(WorldStatus status, DateTime? publishedAt) =>
      switch (status) {
        WorldStatus.published => WorldLifecycle.published,
        WorldStatus.hidden => WorldLifecycle.hidden,
        WorldStatus.draft || WorldStatus.deleted =>
          publishedAt == null
              ? WorldLifecycle.draft
              : WorldLifecycle.unpublished,
      };
}
