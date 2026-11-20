import 'package:flutter/material.dart';

/// A centred progress indicator for content that is still loading.
class LoadingView extends StatelessWidget {
  const LoadingView({this.label = 'Loading', super.key});

  /// Announced by screen readers.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(label: label, child: const CircularProgressIndicator()),
    );
  }
}
