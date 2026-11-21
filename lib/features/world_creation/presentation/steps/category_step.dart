import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/features/world_creation/application/world_editor_controller.dart';
import 'package:worlds/shared/components/category_style.dart';
import 'package:worlds/shared/components/design.dart';
import 'package:worlds/shared/models/world_category.dart';

/// What each kind of World is, with an example, so a first-time creator can
/// choose without a tutorial.
const categoryExplanations = <WorldCategory, (String, String)>{
  WorldCategory.story: (
    'A story told in parts. Add choices to let readers decide where it goes.',
    'A ghost story at the old pier where readers choose which door to open.',
  ),
  WorldCategory.puzzle: (
    'Clues and questions. Explorers type answers, and WORLDS checks them.',
    'A riddle whose answer is carved on a statue in the square.',
  ),
  WorldCategory.art: (
    'An artwork with the story behind it.',
    'Photos of a mural before and after its restoration.',
  ),
  WorldCategory.experience: (
    'Any mix of writing, images, choices and questions.',
    'A guided walk round the market with a quiz at the end.',
  ),
};

class CategoryStep extends ConsumerWidget {
  const CategoryStep({required this.args, super.key});

  final WorldEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = worldEditorProvider(args);
    final selected = ref.watch(provider.select((s) => s.draft?.category));
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.sm,
        Space.lg,
        Space.xl,
      ),
      children: [
        const SectionHeader(
          title: 'What are you making?',
          subtitle:
              'You can change this later if your content fits the new type.',
        ),
        const SizedBox(height: Space.lg),
        for (final category in WorldCategory.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CategoryCard(
              category: category,
              selected: category == selected,
              onTap: () {
                final changed = ref
                    .read(provider.notifier)
                    .chooseCategory(category);
                if (!changed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Some of your content cannot be used in '
                        '${category.label}. Remove it first.',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final WorldCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final (summary, example) = categoryExplanations[category]!;
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.quick),
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(
                  category.color.withValues(alpha: 0.07),
                  colors.surface,
                )
              : colors.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(
            color: selected ? category.color : colors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.lg),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryBadge(category: category, size: 56),
                  const SizedBox(width: Space.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.label,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: selected
                                ? category.foregroundOn(theme.brightness)
                                : colors.ink,
                          ),
                        ),
                        const SizedBox(height: Space.xs),
                        Text(summary, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: Space.sm),
                        Text(
                          'For example: $example',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.muted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: Space.sm),
                    Icon(
                      Icons.check_circle,
                      color: category.foregroundOn(theme.brightness),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
