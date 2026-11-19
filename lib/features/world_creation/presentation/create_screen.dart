import 'package:flutter/material.dart';
import 'package:worlds/core/widgets/empty_view.dart';

/// Placeholder for the Create tab. No functionality yet.
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      body: const EmptyView(
        icon: Icons.add_circle_outline,
        title: 'Create is not built yet',
        message: 'You will be able to create a World here.',
      ),
    );
  }
}
