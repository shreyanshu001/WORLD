import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/widgets/empty_view.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/auth/presentation/sign_in_prompt.dart';

/// The Create tab. Creating needs an account; the editor arrives in a later
/// checkpoint.
class CreateScreen extends ConsumerWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(currentUserProvider) != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      body: signedIn
          ? const EmptyView(
              icon: Icons.add_circle_outline,
              title: 'Create is not built yet',
              message: 'You will be able to create a World here.',
            )
          : const SignInPrompt(
              icon: Icons.add_circle_outline,
              title: 'Create a World',
              message:
                  'Sign in to place a story, puzzle, artwork or '
                  'experience on the map.',
              returnTo: AppRoutes.create,
            ),
    );
  }
}
