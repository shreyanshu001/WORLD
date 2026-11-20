import 'package:flutter/material.dart';
import 'package:worlds/core/widgets/empty_view.dart';

/// Placeholder for the Saved tab. No functionality yet.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: const EmptyView(
        icon: Icons.bookmark_outline,
        title: 'Saved is not built yet',
        message: 'Worlds you save will appear here.',
      ),
    );
  }
}
