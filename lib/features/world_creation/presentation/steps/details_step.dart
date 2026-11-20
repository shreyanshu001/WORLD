import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/features/world_creation/application/world_editor_controller.dart';
import 'package:worlds/features/world_creation/application/world_editor_state.dart';
import 'package:worlds/features/world_creation/domain/world_rules.dart';
import 'package:worlds/features/world_creation/presentation/widgets/image_slot.dart';
import 'package:worlds/features/worlds/presentation/world_cover.dart';

/// Title, description and cover image.
class DetailsStep extends ConsumerStatefulWidget {
  const DetailsStep({required this.args, super.key});

  final WorldEditorArgs args;

  @override
  ConsumerState<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends ConsumerState<DetailsStep> {
  late final TextEditingController _title;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(worldEditorProvider(widget.args)).draft;
    _title = TextEditingController(text: draft?.title ?? '');
    _description = TextEditingController(text: draft?.description ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = worldEditorProvider(widget.args);
    final controller = ref.read(provider.notifier);
    final draft = ref.watch(provider.select((s) => s.draft));
    if (draft == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final titleValid = WorldRules.titleError(draft.title) == null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Tell people what it is', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextFormField(
          controller: _title,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          maxLength: WorldRules.titleMax,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => WorldRules.titleError(value ?? ''),
          onChanged: controller.updateTitle,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _description,
          decoration: const InputDecoration(
            labelText: 'Description',
            helperText: 'What will people find? Needed before publishing.',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          minLines: 3,
          maxLines: 8,
          maxLength: WorldRules.descriptionMax,
          textCapitalization: TextCapitalization.sentences,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => WorldRules.descriptionError(value ?? ''),
          onChanged: controller.updateDescription,
        ),
        const SizedBox(height: 16),
        Text('Cover image', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Optional. Without one, the World shows its category colour.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ImageSlot(
          args: widget.args,
          target: coverUploadTarget,
          assetId: draft.coverAssetId,
          aspectRatio: 16 / 9,
          placeholder: CategoryPanel(category: draft.category),
          addLabel: 'Add cover image',
          enabled: titleValid,
          disabledHint: 'Add a title first.',
          onPick: controller.pickCover,
          onRemove: controller.removeCover,
        ),
      ],
    );
  }
}
