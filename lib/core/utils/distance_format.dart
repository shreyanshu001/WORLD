/// A short, rounded distance for display: "90 m", "1.4 km", "12 km".
String formatDistance(double meters) {
  if (meters < 1000) {
    final rounded = ((meters / 10).round() * 10).clamp(10, 990);
    return '$rounded m';
  }
  if (meters < 10000) {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
  return '${(meters / 1000).round()} km';
}
