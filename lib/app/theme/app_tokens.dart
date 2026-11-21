import 'package:flutter/material.dart';

/// Named colours for the "living atlas / field journal" direction in
/// docs/UI_UX_SPECIFICATION.md section 3, adopted at the owner's request on
/// 2026-11-20 (docs/DECISIONS.md, D-031). Widgets use these roles, never raw
/// hex values.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.surface,
    required this.surfaceSubtle,
    required this.ink,
    required this.muted,
    required this.primary,
    required this.primarySoft,
    required this.accent,
    required this.accentText,
    required this.outline,
    required this.danger,
    required this.dangerSoft,
    required this.success,
    required this.successSoft,
  });

  /// Warm paper behind non-map screens.
  final Color canvas;

  /// Clean raised surface: cards, sheets, fields.
  final Color surface;

  /// Secondary panels.
  final Color surfaceSubtle;

  /// High-contrast text.
  final Color ink;

  /// Supporting text and metadata.
  final Color muted;

  /// Deep botanical green.
  final Color primary;
  final Color primarySoft;

  /// Ochre, for small highlights such as distance.
  final Color accent;

  /// [accent] deep enough to read as small text on its own tint. In the
  /// light theme the ochre itself is 4.2:1 there; this is 5.1:1
  /// (docs/DECISIONS.md, D-041). In the dark theme the two are the same.
  final Color accentText;
  final Color outline;
  final Color danger;
  final Color dangerSoft;
  final Color success;
  final Color successSoft;

  static const light = AppColors(
    canvas: Color(0xFFF7F4EE),
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF0ECE4),
    ink: Color(0xFF1B2420),
    muted: Color(0xFF5D6963),
    primary: Color(0xFF1F5E4B),
    primarySoft: Color(0xFFDCEBE3),
    accent: Color(0xFF9A5B12),
    accentText: Color(0xFF885010),
    outline: Color(0xFFE2DBCF),
    danger: Color(0xFFB3261E),
    dangerSoft: Color(0xFFFBE4E1),
    success: Color(0xFF2E7D4F),
    successSoft: Color(0xFFDDF0E3),
  );

  static const dark = AppColors(
    canvas: Color(0xFF111614),
    surface: Color(0xFF1A211E),
    surfaceSubtle: Color(0xFF232B27),
    ink: Color(0xFFECEFEA),
    muted: Color(0xFFA7B2AC),
    primary: Color(0xFF8ED0B4),
    primarySoft: Color(0xFF1F3B31),
    accent: Color(0xFFE2A85C),
    accentText: Color(0xFFE2A85C),
    outline: Color(0xFF333C38),
    danger: Color(0xFFF2B8B5),
    dangerSoft: Color(0xFF3C1F1D),
    success: Color(0xFF8FD3A8),
    successSoft: Color(0xFF1D3426),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      surfaceSubtle: mix(surfaceSubtle, other.surfaceSubtle),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      primary: mix(primary, other.primary),
      primarySoft: mix(primarySoft, other.primarySoft),
      accent: mix(accent, other.accent),
      accentText: mix(accentText, other.accentText),
      outline: mix(outline, other.outline),
      danger: mix(danger, other.danger),
      dangerSoft: mix(dangerSoft, other.dangerSoft),
      success: mix(success, other.success),
      successSoft: mix(successSoft, other.successSoft),
    );
  }
}

/// The 4 dp spacing scale.
abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// How long things move and how they ease (docs/UI_UX_SPECIFICATION.md,
/// Motion). Motion says what changed: it is short, and nothing loops.
abstract final class Motion {
  /// A small change in place: an icon, a colour, something leaving.
  static const quick = Duration(milliseconds: 150);

  /// Something arriving: a card, a message, the next part of a World.
  static const standard = Duration(milliseconds: 260);

  /// A single mark of success, once.
  static const emphasis = Duration(milliseconds: 420);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;

  /// [duration], or no time at all when the device is set to remove
  /// animations. Every animation in the app takes its duration from here.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

/// One corner-radius family.
abstract final class Radii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}
