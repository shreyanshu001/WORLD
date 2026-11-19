import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/widgets/empty_view.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/auth/presentation/sign_in_prompt.dart';

/// The Saved tab. Saving Worlds needs an account; the list itself arrives in
/// a later checkpoint.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(currentUserProvider) != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: signedIn
          ? const EmptyView(
              icon: Icons.bookmark_outline,
              title: 'Saved is not built yet',
              message: 'Worlds you save will appear here.',
            )
          : const SignInPrompt(
              icon: Icons.bookmark_outline,
              title: 'Save Worlds for later',
              message: 'Sign in to keep a list of Worlds you want to visit.',
              returnTo: AppRoutes.saved,
            ),
    );
  }
}
