import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/features/world_creation/application/world_editor_controller.dart';
import 'package:worlds/features/world_creation/domain/world_rules.dart';
import 'package:worlds/features/world_creation/presentation/widgets/block_editor_card.dart';
import 'package:worlds/features/world_creation/presentation/widgets/block_type_style.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/shared/models/world_category.dart';

const _categoryGuidance = <WorldCategory, String>{
  WorldCategory.story:
      'Tell your story in parts. A Choice lets readers pick what happens '
      'next; an Ending finishes that branch.',
  WorldCategory.puzzle:
      'Give clues, then ask a Question. Explorers type the answer and WORLDS '
      'checks it; nobody else can see it.',
  WorldCategory.art:
      'Add your Artwork with its title and the story behind it. Text and '
      'images can add context.',
  WorldCategory.experience:
      'Combine any parts in the order explorers should meet them.',
};

/// The World's content as an ordered list of typed parts.
class ContentStep extends ConsumerWidget {
  const ContentStep({required this.args, super.key});

  final WorldEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = worldEditorProvider(args);
    final category = ref.watch(provider.select((s) => s.draft?.category));
    // Joined into one string so the list rebuilds only when the order or set
    // of blocks changes, not on every keystroke.
    final joinedIds = ref.watch(
      provider.select(
        (s) => [
          for (final b in s.draft?.blocks ?? const <ContentBlock>[]) b.id,
        ].join(','),
      ),
    );
    final blockIds = joinedIds.isEmpty
        ? const <String>[]
        : joinedIds.split(',');
    if (category == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      header: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Content', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              _categoryGuidance[category]!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${blockIds.length} of ${WorldRules.maxBlocks} parts',
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (blockIds.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No content yet. Add the first part below.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            FilledButton.tonalIcon(
              onPressed: blockIds.length >= WorldRules.maxBlocks
                  ? null
                  : () => _addBlock(context, ref, category),
              icon: const Icon(Icons.add),
              label: Text(
                blockIds.length >= WorldRules.maxBlocks
                    ? 'Part limit reached'
                    : 'Add a part',
              ),
            ),
          ],
        ),
      ),
      itemCount: blockIds.length,
      onReorder: (from, to) =>
          ref.read(provider.notifier).moveBlock(from, to > from ? to - 1 : to),
      itemBuilder: (context, index) => Padding(
        key: ValueKey(blockIds[index]),
        padding: const EdgeInsets.only(bottom: 12),
        child: BlockEditorCard(
          args: args,
          blockId: blockIds[index],
          index: index,
          count: blockIds.length,
        ),
      ),
    );
  }

  Future<void> _addBlock(
    BuildContext context,
    WidgetRef ref,
    WorldCategory category,
  ) async {
    final type = await showModalBottomSheet<BlockType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Add a part',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final type in WorldRules.allowedBlocks(category))
              ListTile(
                leading: Icon(type.icon),
                title: Text(type.label),
                subtitle: Text(type.description),
                onTap: () => Navigator.of(context).pop(type),
              ),
          ],
        ),
      ),
    );
    if (type != null) {
      ref.read(worldEditorProvider(args).notifier).addBlock(type);
    }
  }
}
