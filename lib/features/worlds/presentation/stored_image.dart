import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/features/worlds/application/world_providers.dart';

/// An image from World storage. Shows [placeholder] while the signed address
/// loads and if the image cannot be shown.
class StoredImage extends ConsumerWidget {
  const StoredImage({
    required this.storagePath,
    required this.placeholder,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    super.key,
  });

  final String storagePath;
  final Widget placeholder;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(worldImageUrlProvider(storagePath));
    return switch (url) {
      AsyncData(:final value) => Image.network(
        value.toString(),
        fit: fit,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _Loading(placeholder: placeholder),
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
      AsyncError() => placeholder,
      _ => _Loading(placeholder: placeholder),
    };
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.placeholder});

  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        placeholder,
        const Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ],
    );
  }
}
