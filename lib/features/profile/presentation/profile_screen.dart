import 'package:flutter/material.dart';
import 'package:worlds/core/widgets/empty_view.dart';

/// Placeholder for the Profile tab. No functionality yet.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const EmptyView(
        icon: Icons.person_outline,
        title: 'Profile is not built yet',
        message: 'Your profile and your Worlds will appear here.',
      ),
    );
  }
}
