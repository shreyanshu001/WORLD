import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/widgets/empty_view.dart';
import 'package:worlds/features/world_creation/application/world_editor_controller.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/worlds/presentation/blocks/block_view.dart';
import 'package:worlds/shared/components/motion.dart';

/// Walks through the draft one part at a time, the way an explorer will,
/// following choices to their destinations. Answers are not checked here:
/// only the server knows them.
class WorldPreviewScreen extends ConsumerStatefulWidget {
  const WorldPreviewScreen({required this.args, super.key});

  final WorldEditorArgs args;

  @override
  ConsumerState<WorldPreviewScreen> createState() => _WorldPreviewScreenState();
}

class _WorldPreviewScreenState extends ConsumerState<WorldPreviewScreen> {
  /// Indices visited, so Back retraces choices.
  final _path = <int>[0];

  void _goTo(int index) => setState(() => _path.add(index));

  void _back() {
    if (_path.length > 1) setState(_path.removeLast);
  }

  void _restart() => setState(() {
    _path
      ..clear()
      ..add(0);
  });

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(
      worldEditorProvider(widget.args).select((s) => s.draft),
    );
    final blocks = draft?.blocks ?? const <ContentBlock>[];
    final index = _path.last;
    final finished = index >= blocks.length;
    final block = finished ? null : blocks[index];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close preview',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Preview'),
            if (draft != null)
              Text(
                draft.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: blocks.isEmpty
          ? const EmptyView(
              icon: Icons.visibility_outlined,
              title: 'Nothing to preview yet',
              message: 'Add some content first.',
            )
          // Each part fills the screen from the top, like a page, and
          // turns the way it does for an explorer.
          : StateSwitcher(
              from: const Offset(0.06, 0),
              to: const Offset(-0.06, 0),
              child: SingleChildScrollView(
                key: ValueKey(_path.length),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: block == null
                    ? _End(onRestart: _restart)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Part ${index + 1} of ${blocks.length}',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 12),
                          BlockView(
                            block: block,
                            assetPath: (id) =>
                                draft?.assetById(id)?.storagePath,
                          ),
                          const SizedBox(height: 24),
                          _Interaction(
                            block: block,
                            blocks: blocks,
                            onNext: () => _goTo(index + 1),
                            onJump: _goTo,
                            onFinish: () => _goTo(blocks.length),
                          ),
                        ],
                      ),
              ),
            ),
      bottomNavigationBar: _path.length > 1
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                // A Row, not an Align: a bottom bar must not take the
                // body's height.
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _Interaction extends StatelessWidget {
  const _Interaction({
    required this.block,
    required this.blocks,
    required this.onNext,
    required this.onJump,
    required this.onFinish,
  });

  final ContentBlock block;
  final List<ContentBlock> blocks;
  final VoidCallback onNext;
  final ValueChanged<int> onJump;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (block) {
      StoryChoiceBlock(:final options) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Builder(
                builder: (context) {
                  final target = blocks.indexWhere(
                    (b) => b.id == option.destinationBlockId,
                  );
                  return FilledButton.tonal(
                    onPressed: target < 0 ? null : () => onJump(target),
                    child: Text(
                      option.label.trim().isEmpty ? 'Option' : option.label,
                    ),
                  );
                },
              ),
            ),
          if (options.any((o) => o.destinationBlockId == null))
            Text(
              'Options without a destination cannot be chosen yet.',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
      QuestionBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Explorers type their answer here',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'In the live World, WORLDS checks the answer. The preview skips '
            'the check.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onNext, child: const Text('Continue')),
        ],
      ),
      CompletionBlock() => FilledButton(
        onPressed: onFinish,
        child: const Text('Finish'),
      ),
      _ => FilledButton(onPressed: onNext, child: const Text('Continue')),
    };
  }
}

class _End extends StatelessWidget {
  const _End({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 48),
        Icon(
          Icons.check_circle_outline,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text('End of the preview', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'This is where the experience finishes for explorers.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onRestart,
          icon: const Icon(Icons.replay),
          label: const Text('Start again'),
        ),
      ],
    );
  }
}
