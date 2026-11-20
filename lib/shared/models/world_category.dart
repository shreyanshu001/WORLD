/// The four kinds of World. Values match the database's `category` column.
enum WorldCategory {
  story('Story'),
  puzzle('Puzzle'),
  art('Art'),
  experience('Experience');

  const WorldCategory(this.label);

  final String label;
}
