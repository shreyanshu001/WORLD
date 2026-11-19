import 'package:flutter/material.dart';

/// Material 3 themes for the app.
///
/// The seed colour is a starting point, not a brand decision: no design
/// system exists yet.
abstract final class AppTheme {
  static const _seed = Color(0xFF1F6F5B);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
  );
}
