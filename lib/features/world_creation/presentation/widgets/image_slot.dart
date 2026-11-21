import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/features/world_creation/application/world_editor_controller.dart';
import 'package:worlds/features/worlds/presentation/stored_image.dart';

/// An image the creator can add, change, retry or remove: a cover, or the
/// picture in a block. Shows upload progress and failures for [target].
class ImageSlot extends ConsumerWidget {
  const ImageSlot({
    required this.args,
    required this.target,
    required this.assetId,
    required this.placeholder,
    required this.addLabel,
    required this.onPick,
    this.onRemove,
    this.aspectRatio = 4 / 3,
    this.enabled = true,
    this.disabledHint,
    super.key,
  });

  final WorldEditorArgs args;

  /// The upload target: a block id, or the cover.
  final String target;
  final String? assetId;
  final Widget placeholder;
  final String addLabel;
  final VoidCallback onPick;
  final VoidCallback? onRemove;
  final double aspectRatio;
  final bool enabled;
  final String? disabledHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = worldEditorProvider(args);
    final uploading = ref.watch(
      provider.select((s) => s.uploading.contains(target)),
    );
    final failed = ref.watch(
      provider.select((s) => s.failedUploads.contains(target)),
    );
    final path = ref.watch(
      provider.select((s) => s.draft?.assetById(assetId)?.storagePath),
    );
    final busy = ref.watch(provider.select((s) => s.busy));
    final theme = Theme.of(context);

    Widget image;
    if (uploading) {
      image = Stack(
        fit: StackFit.expand,
        children: [
          placeholder,
          const Center(
            child: CircularProgressIndicator(semanticsLabel: 'Uploading image'),
          ),
        ],
      );
    } else if (path != null) {
      image = StoredImage(
        storagePath: path,
        placeholder: placeholder,
        semanticLabel: 'Chosen image',
      );
    } else {
      image = placeholder;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(aspectRatio: aspectRatio, child: image),
        ),
        const SizedBox(height: 8),
        if (failed && !uploading)
          Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              const Expanded(child: Text("The image didn't upload.")),
              TextButton(
                onPressed: busy
                    ? null
                    : () => ref.read(provider.notifier).retryUpload(target),
                child: const Text('Retry'),
              ),
            ],
          ),
        Wrap(
          spacing: 8,
          children: [
            if (path == null)
              FilledButton.tonalIcon(
                onPressed: enabled && !busy ? onPick : null,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(addLabel),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: enabled && !busy ? onPick : null,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Change'),
              ),
              if (onRemove case final remove?)
                TextButton.icon(
                  onPressed: busy ? null : remove,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                ),
            ],
          ],
        ),
        if (!enabled && disabledHint != null)
          Text(
            disabledHint!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
