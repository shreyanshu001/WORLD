import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/utils/uuid.dart';
import 'package:worlds/features/world_creation/application/world_editor_controller.dart';
import 'package:worlds/features/world_creation/domain/world_rules.dart';
import 'package:worlds/features/world_creation/presentation/widgets/block_type_style.dart';
import 'package:worlds/features/world_creation/presentation/widgets/image_slot.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';

/// Edits one block. Each card owns the text controllers for its fields, so
/// moving a block keeps what was typed. Every change goes straight to the
/// editor's draft.
class BlockEditorCard extends ConsumerStatefulWidget {
  const BlockEditorCard({
    required this.args,
    required this.blockId,
    required this.index,
    required this.count,
    super.key,
  });

  final WorldEditorArgs args;
  final String blockId;
  final int index;
  final int count;

  @override
  ConsumerState<BlockEditorCard> createState() => _BlockEditorCardState();
}

class _BlockEditorCardState extends ConsumerState<BlockEditorCard> {
  final _controllers = <String, TextEditingController>{};

  TextEditingController _field(String key, String initial) =>
      _controllers.putIfAbsent(key, () => TextEditingController(text: initial));

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = worldEditorProvider(widget.args);
    final block = ref.watch(
      provider.select((s) => s.draft?.blockById(widget.blockId)),
    );
    if (block == null) return const SizedBox.shrink();
    final incomplete = ref.watch(
      provider.select(
        (s) => s.publishProblems.any((p) => p.blockId == widget.blockId),
      ),
    );
    final controller = ref.read(provider.notifier);
    final theme = Theme.of(context);

    // A saved answer leaves the device: clear the field once the server has
    // it, so it is not kept on screen.
    ref.listen(provider.select((s) => s.pendingAnswerIds.contains(block.id)), (
      wasPending,
      isPending,
    ) {
      if ((wasPending ?? false) && !isPending) {
        _controllers['answer']?.clear();
      }
    });

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: widget.index,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.drag_indicator,
                      semanticLabel: 'Drag to reorder',
                    ),
                  ),
                ),
                Icon(block.type.icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Part ${widget.index + 1} · ${block.type.label}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (incomplete)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      label: const Text('Incomplete'),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: theme.colorScheme.error),
                      labelStyle: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                PopupMenuButton<_BlockAction>(
                  tooltip: 'Part ${widget.index + 1} options',
                  onSelected: (action) => switch (action) {
                    _BlockAction.up => controller.moveBlock(
                      widget.index,
                      widget.index - 1,
                    ),
                    _BlockAction.down => controller.moveBlock(
                      widget.index,
                      widget.index + 1,
                    ),
                    _BlockAction.remove => _confirmRemove(block),
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _BlockAction.up,
                      enabled: widget.index > 0,
                      child: const Text('Move up'),
                    ),
                    PopupMenuItem(
                      value: _BlockAction.down,
                      enabled: widget.index < widget.count - 1,
                      child: const Text('Move down'),
                    ),
                    const PopupMenuItem(
                      value: _BlockAction.remove,
                      child: Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _fields(block, controller),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(ContentBlock block) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove part ${widget.index + 1}?'),
        content: const Text(
          'Its content is removed from the World when you next save. Choices '
          'that led to it will need a new destination.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) {
      ref.read(worldEditorProvider(widget.args).notifier).removeBlock(block.id);
    }
  }

  Widget _text(
    String key,
    String initial, {
    required String label,
    required int maxLength,
    required ValueChanged<String> onChanged,
    String? helper,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: _field(key, initial),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
          alignLabelWithHint: maxLines > 1,
          border: const OutlineInputBorder(),
        ),
        minLines: minLines,
        maxLines: maxLines,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.sentences,
        onChanged: onChanged,
      ),
    );
  }

  Widget _fields(ContentBlock block, WorldEditorController controller) {
    final update = controller.updateBlock;
    return switch (block) {
      TextBlock() => _text(
        'body',
        block.body,
        label: 'Text',
        maxLength: WorldRules.textMax,
        minLines: 3,
        maxLines: 10,
        onChanged: (v) => update(block.copyWith(body: v)),
      ),
      ImageBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _image(block, controller, required: true),
          _text(
            'caption',
            block.caption,
            label: 'Caption (optional)',
            maxLength: WorldRules.captionMax,
            onChanged: (v) => update(block.copyWith(caption: v)),
          ),
        ],
      ),
      StoryChoiceBlock() => _ChoiceFields(
        args: widget.args,
        block: block,
        field: _field,
      ),
      QuestionBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _text(
            'prompt',
            block.prompt,
            label: 'Question',
            maxLength: WorldRules.questionPromptMax,
            maxLines: 4,
            onChanged: (v) => update(block.copyWith(prompt: v)),
          ),
          _text(
            'hint',
            block.hint,
            label: 'Hint (optional)',
            maxLength: WorldRules.hintMax,
            onChanged: (v) => update(block.copyWith(hint: v)),
          ),
          _text(
            'success',
            block.successMessage,
            label: 'Message for a correct answer (optional)',
            maxLength: WorldRules.successMessageMax,
            onChanged: (v) => update(block.copyWith(successMessage: v)),
          ),
          _AnswerField(
            args: widget.args,
            block: block,
            controller: _field('answer', ''),
          ),
        ],
      ),
      ArtworkBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _image(block, controller, required: true),
          _text(
            'title',
            block.title,
            label: 'Artwork title',
            maxLength: WorldRules.artworkTitleMax,
            onChanged: (v) => update(block.copyWith(title: v)),
          ),
          _text(
            'description',
            block.description,
            label: 'About the artwork',
            helper: 'What it is, who made it and why it belongs here.',
            maxLength: WorldRules.artworkDescriptionMax,
            minLines: 3,
            maxLines: 10,
            onChanged: (v) => update(block.copyWith(description: v)),
          ),
        ],
      ),
      CompletionBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _text(
            'title',
            block.title,
            label: 'Ending title',
            maxLength: WorldRules.completionTitleMax,
            onChanged: (v) => update(block.copyWith(title: v)),
          ),
          _text(
            'message',
            block.message,
            label: 'Closing message',
            maxLength: WorldRules.completionMessageMax,
            minLines: 2,
            maxLines: 6,
            onChanged: (v) => update(block.copyWith(message: v)),
          ),
          const SizedBox(height: 4),
          _image(block, controller, required: false),
        ],
      ),
    };
  }

  Widget _image(
    ContentBlock block,
    WorldEditorController controller, {
    required bool required,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ImageSlot(
      args: widget.args,
      target: block.id,
      assetId: block.imageAssetId,
      placeholder: ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: scheme.onSurfaceVariant,
        ),
      ),
      addLabel: required ? 'Choose image' : 'Add an image (optional)',
      onPick: () => controller.pickBlockImage(block.id),
      onRemove: required ? null : () => controller.removeBlockImage(block.id),
    );
  }
}

enum _BlockAction { up, down, remove }

/// The accepted answer. It is sent once with the next save and never shown
/// again, so the field is empty whenever the server already has an answer.
class _AnswerField extends ConsumerWidget {
  const _AnswerField({
    required this.args,
    required this.block,
    required this.controller,
  });

  final WorldEditorArgs args;
  final QuestionBlock block;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = worldEditorProvider(args);
    final pending = ref.watch(
      provider.select((s) => s.pendingAnswerIds.contains(block.id)),
    );
    final helper = pending
        ? 'Will be stored when you save.'
        : block.hasAnswer
        ? 'An answer is saved. Type a new one to replace it.'
        : 'Explorers must type this. Capitals and extra spaces are ignored. '
              'Only WORLDS can see it.';

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: block.hasAnswer ? 'New answer' : 'Accepted answer',
          helperText: helper,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(
            block.hasAnswer && !pending ? Icons.lock : Icons.key_outlined,
          ),
        ),
        maxLength: WorldRules.answerMax,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: (value) =>
            ref.read(provider.notifier).setAnswer(block.id, value),
      ),
    );
  }
}

/// A choice's prompt and its 2–4 options, each leading to a later part.
class _ChoiceFields extends ConsumerWidget {
  const _ChoiceFields({
    required this.args,
    required this.block,
    required this.field,
  });

  final WorldEditorArgs args;
  final StoryChoiceBlock block;
  final TextEditingController Function(String key, String initial) field;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = worldEditorProvider(args);
    final controller = ref.read(provider.notifier);
    final later = ref.watch(
      provider.select((s) {
        final blocks = s.draft?.blocks ?? const <ContentBlock>[];
        final index = blocks.indexWhere((b) => b.id == block.id);
        return [
          for (var i = index + 1; i < blocks.length; i++)
            (
              id: blocks[i].id,
              label: 'Part ${i + 1} · ${blockSummary(blocks[i])}',
            ),
        ].map((e) => '${e.id}\u0000${e.label}').join('\u0001');
      }),
    );
    final destinations = [
      for (final entry in later.isEmpty ? <String>[] : later.split('\u0001'))
        (id: entry.split('\u0000').first, label: entry.split('\u0000').last),
    ];
    final theme = Theme.of(context);

    void updateOption(StoryOption option) => controller.updateBlock(
      block.copyWith(
        options: [
          for (final o in block.options) o.id == option.id ? option : o,
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextField(
            controller: field('prompt', block.prompt),
            decoration: const InputDecoration(
              labelText: 'What does the reader decide?',
              border: OutlineInputBorder(),
            ),
            maxLength: WorldRules.choicePromptMax,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (v) => controller.updateBlock(block.copyWith(prompt: v)),
          ),
        ),
        if (destinations.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              'Choices lead forward. Add the parts this choice leads to '
              'below it, then pick them here.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final (i, option) in block.options.indexed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Option ${i + 1}',
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      if (block.options.length > WorldRules.minOptions)
                        IconButton(
                          tooltip: 'Remove option ${i + 1}',
                          icon: const Icon(Icons.close),
                          onPressed: () => controller.updateBlock(
                            block.copyWith(
                              options: [
                                for (final o in block.options)
                                  if (o.id != option.id) o,
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  TextField(
                    controller: field('option:${option.id}', option.label),
                    decoration: const InputDecoration(
                      labelText: 'Option text',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: WorldRules.choiceLabelMax,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (v) => updateOption(option.copyWith(label: v)),
                  ),
                  DropdownButtonFormField<String>(
                    // Rebuilt with a new key so a removed destination clears.
                    key: ValueKey('${option.id}:${option.destinationBlockId}'),
                    initialValue:
                        destinations.any(
                          (d) => d.id == option.destinationBlockId,
                        )
                        ? option.destinationBlockId
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Leads to',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final destination in destinations)
                        DropdownMenuItem(
                          value: destination.id,
                          child: Text(
                            destination.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: destinations.isEmpty
                        ? null
                        : (id) => updateOption(
                            option.copyWith(destinationBlockId: id),
                          ),
                  ),
                ],
              ),
            ),
          ),
        if (block.options.length < WorldRules.maxOptions)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => controller.updateBlock(
                block.copyWith(
                  options: [
                    ...block.options,
                    StoryOption(id: newUuid()),
                  ],
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add an option'),
            ),
          ),
      ],
    );
  }
}
