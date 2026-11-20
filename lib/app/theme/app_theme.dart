import 'package:flutter/material.dart';
import 'package:worlds/app/theme/app_tokens.dart';

/// Material 3 themes built from [AppColors] (D-031). The platform's own sans
/// font is kept; hierarchy comes from weight, size and spacing.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppColors.light);

  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.light.primary,
          brightness: brightness,
        ).copyWith(
          primary: c.primary,
          onPrimary: brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF0B2A20),
          primaryContainer: c.primarySoft,
          onPrimaryContainer: c.ink,
          secondaryContainer: c.primarySoft,
          onSecondaryContainer: c.ink,
          surface: c.canvas,
          onSurface: c.ink,
          onSurfaceVariant: c.muted,
          surfaceContainerLowest: c.surface,
          surfaceContainerLow: c.surface,
          surfaceContainer: c.surface,
          surfaceContainerHigh: c.surfaceSubtle,
          surfaceContainerHighest: c.surfaceSubtle,
          outline: c.muted,
          outlineVariant: c.outline,
          error: c.danger,
          errorContainer: c.dangerSoft,
          onErrorContainer: c.danger,
        );

    final base = ThemeData(colorScheme: scheme, brightness: brightness);
    // Sizes are set explicitly: component themes below use these styles
    // directly, before Material adds its default sizes.
    final text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: c.ink,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: c.ink,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.45,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.md),
    );
    const buttonSize = Size(64, 52);
    final buttonText = text.labelLarge?.copyWith(fontSize: 16);

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: c.canvas,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge?.copyWith(color: c.ink),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: c.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: rounded,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: rounded,
          textStyle: buttonText,
          side: BorderSide(color: c.outline, width: 1.5),
          foregroundColor: c.ink,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: text.labelLarge),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        extendedTextStyle: buttonText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: c.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: c.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: c.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: c.danger, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: c.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.primarySoft,
        side: BorderSide(color: c.outline),
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge?.copyWith(color: c.ink),
        padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 6),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.primarySoft,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? c.ink : c.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? c.primary : c.muted,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.canvas),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.outline, space: 1),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
        iconColor: c.muted,
        titleTextStyle: text.titleMedium?.copyWith(color: c.ink),
        subtitleTextStyle: text.bodyMedium?.copyWith(color: c.muted),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        thumbColor: c.primary,
        inactiveTrackColor: c.primarySoft,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.primarySoft,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
