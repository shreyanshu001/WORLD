import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/shared/components/category_style.dart';
import 'package:worlds/shared/models/world_category.dart';

/// Contrast as WCAG 2 defines it, from 1 (none) to 21.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  // WCAG 2.1 AA: 4.5:1 for ordinary text, 3:1 for icons and large text.
  const text = 4.5;
  const icon = 3.0;

  test('category names and icons can be read on dark surfaces', () {
    // Before this was fixed, Story's name was 2.3:1 on a dark card.
    const dark = AppColors.dark;
    for (final category in WorldCategory.values) {
      final colour = category.foregroundOn(Brightness.dark);
      for (final surface in [dark.canvas, dark.surface, dark.surfaceSubtle]) {
        expect(
          contrast(colour, surface),
          greaterThanOrEqualTo(text),
          reason: '${category.name} on $surface',
        );
      }
    }
  });

  test('on light surfaces the category colours are used as they are', () {
    const light = AppColors.light;
    for (final category in WorldCategory.values) {
      final colour = category.foregroundOn(Brightness.light);
      expect(colour, category.color);
      for (final surface in [light.canvas, light.surface]) {
        expect(
          contrast(colour, surface),
          greaterThanOrEqualTo(icon),
          reason: '${category.name} icon on $surface',
        );
      }
    }
  });

  test('on light surfaces three of the four names meet the text level', () {
    // Puzzle's amber is 4.2:1 on white and 3.9:1 on the canvas: enough for
    // its icon, short of 4.5:1 for its name. Its value is the owner's to
    // change (docs/DECISIONS.md, D-041), so it is measured here, not hidden.
    const light = AppColors.light;
    for (final category in WorldCategory.values) {
      final onCard = contrast(category.color, light.surface);
      if (category == WorldCategory.puzzle) {
        expect(onCard, inInclusiveRange(4.2, 4.3));
      } else {
        expect(onCard, greaterThanOrEqualTo(text), reason: category.name);
        expect(
          contrast(category.color, light.canvas),
          greaterThanOrEqualTo(text),
          reason: category.name,
        );
      }
    }
  });

  test('body text and actions meet the text level in both themes', () {
    for (final c in [AppColors.light, AppColors.dark]) {
      for (final surface in [c.canvas, c.surface, c.surfaceSubtle]) {
        expect(contrast(c.ink, surface), greaterThanOrEqualTo(text));
        expect(contrast(c.muted, surface), greaterThanOrEqualTo(text));
        expect(contrast(c.primary, surface), greaterThanOrEqualTo(text));
      }
      expect(contrast(c.danger, c.surface), greaterThanOrEqualTo(text));
      expect(contrast(c.danger, c.dangerSoft), greaterThanOrEqualTo(text));
      expect(contrast(c.ink, c.successSoft), greaterThanOrEqualTo(text));
      expect(contrast(c.ink, c.primarySoft), greaterThanOrEqualTo(text));
    }
  });
}
