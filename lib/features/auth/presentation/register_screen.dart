import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/widgets/form_error_text.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/auth/domain/auth_repository.dart';
import 'package:worlds/features/auth/domain/credential_rules.dart';
import 'package:worlds/features/profile/domain/profile_rules.dart';

/// Account creation with username, email and password.
///
/// If the account is ready immediately, goes to [from]. If the email must be
/// confirmed first, this page says so.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({this.from, super.key});

  final String? from;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(registerControllerProvider.notifier)
        .submit(
          username: _username.text,
          email: _email.text,
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);
    final busy = state.isLoading;
    final returnTo = AppRoutes.safeReturnPath(widget.from);

    // This page is usually pushed, and go_router's redirect does not see
    // pushed pages, so leave explicitly once a user appears.
    ref.listen(currentUserProvider, (previous, next) {
      if (previous == null && next != null) context.go(returnTo);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: state.value == SignUpOutcome.confirmationRequired
                  ? _CheckYourEmail(
                      email: _email.text.trim(),
                      onSignIn: () => context.pushReplacement(
                        AppRoutes.signInFrom(returnTo),
                      ),
                    )
                  : _buildForm(context, state, busy, returnTo),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AsyncValue<SignUpOutcome?> state,
    bool busy,
    String returnTo,
  ) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _username,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Username',
                helperText:
                    '3–20 characters: letters, numbers and underscores.',
                helperMaxLines: 2,
              ),
              autofillHints: const [AutofillHints.newUsername],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: (value) => ProfileRules.validateUsername(value ?? ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              enabled: !busy,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: (value) => CredentialRules.validateEmail(value ?? ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Password',
                helperText:
                    'At least ${CredentialRules.minPasswordLength} characters.',
              ),
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) =>
                  CredentialRules.validateNewPassword(value ?? ''),
            ),
            if (state.hasError && !busy) ...[
              const SizedBox(height: 16),
              FormErrorText(messageForError(state.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: busy ? null : _submit,
              child: busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Creating account',
                      ),
                    )
                  : const Text('Create account'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: busy
                  ? null
                  : () =>
                        context.pushReplacement(AppRoutes.signInFrom(returnTo)),
              child: const Text('Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckYourEmail extends StatelessWidget {
  const _CheckYourEmail({required this.email, required this.onSignIn});

  final String email;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_unread_outlined,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Check your email',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Supabase answers the same way when the email already has an
        // account, so this must not claim that an account was created.
        Text(
          'If a new account can be created for $email, we have sent a '
          'confirmation link to it. Open the link, then sign in.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: onSignIn, child: const Text('Go to sign in')),
      ],
    );
  }
}
