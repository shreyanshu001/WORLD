import 'package:flutter/material.dart';
import 'package:worlds/core/widgets/empty_view.dart';

/// Placeholder for the Explore tab. No functionality yet.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: const EmptyView(
        icon: Icons.map_outlined,
        title: 'Explore is not built yet',
        message: 'The map of nearby Worlds will appear here.',
      ),
    );
  }
}
