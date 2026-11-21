import 'package:flutter/material.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/worlds/presentation/stored_image.dart';

/// Finds the storage path of an image asset, or null if it is unknown.
typedef AssetPathLookup = String? Function(String assetId);

/// Shows one content block read-only, the way explorers see it. The creator's
/// preview and the player both use this, so the preview matches the real
/// thing. Interactive parts (continue, choices, answers) belong to the
/// screen around it.
class BlockView extends StatelessWidget {
  const BlockView({required this.block, required this.assetPath, super.key});

  final ContentBlock block;
  final AssetPathLookup assetPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (block) {
      TextBlock(:final body) => Text(body, style: theme.textTheme.bodyLarge),
      ImageBlock(:final assetId, :final caption) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BlockImage(path: _path(assetId), label: caption),
          if (caption.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      StoryChoiceBlock(:final prompt) => Text(
        prompt,
        style: theme.textTheme.titleLarge,
      ),
      QuestionBlock(:final prompt, :final hint) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prompt, style: theme.textTheme.titleLarge),
          if (hint.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _Hint(hint: hint),
          ],
        ],
      ),
      ArtworkBlock(:final assetId, :final title, :final description) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BlockImage(path: _path(assetId), label: title),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyLarge),
        ],
      ),
      CompletionBlock(:final title, :final message, :final assetId) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (assetId != null) ...[
            _BlockImage(path: _path(assetId), label: title),
            const SizedBox(height: 16),
          ],
          Icon(
            Icons.flag_circle_outlined,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(message, style: theme.textTheme.bodyLarge),
        ],
      ),
    };
  }

  String? _path(String? assetId) => assetId == null ? null : assetPath(assetId);
}

class _BlockImage extends StatelessWidget {
  const _BlockImage({required this.path, required this.label});

  final String? path;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: scheme.onSurfaceVariant,
      ),
    );
    final path = this.path;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: path == null
            ? placeholder
            : StoredImage(
                storagePath: path,
                placeholder: placeholder,
                fit: BoxFit.cover,
                semanticLabel: label.trim().isEmpty ? 'Image' : label,
              ),
      ),
    );
  }
}

class _Hint extends StatefulWidget {
  const _Hint({required this.hint});

  final String hint;

  @override
  State<_Hint> createState() => _HintState();
}

class _HintState extends State<_Hint> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    if (_shown) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.hint)),
        ],
      );
    }
    return TextButton.icon(
      onPressed: () => setState(() => _shown = true),
      icon: const Icon(Icons.lightbulb_outline),
      label: const Text('Show hint'),
    );
  }
}
