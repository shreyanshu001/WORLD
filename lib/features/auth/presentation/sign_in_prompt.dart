import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';

/// Shown in place of content that needs an account.
class SignInPrompt extends StatelessWidget {
  const SignInPrompt({
    required this.icon,
    required this.title,
    required this.message,
    required this.returnTo,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Where to come back to after signing in.
  final String returnTo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push(AppRoutes.signInFrom(returnTo)),
                child: const Text('Sign in'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.registerFrom(returnTo)),
                child: const Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
