import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/widgets/form_error_text.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/auth/domain/credential_rules.dart';

/// Email-and-password sign-in. Once signed in, goes to [from].
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({this.from, super.key});

  final String? from;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(signInControllerProvider.notifier)
        .submit(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInControllerProvider);
    final busy = state.isLoading;
    final returnTo = AppRoutes.safeReturnPath(widget.from);

    // This page is usually pushed, and go_router's redirect does not see
    // pushed pages, so leave explicitly once a user appears.
    ref.listen(currentUserProvider, (previous, next) {
      if (previous == null && next != null) context.go(returnTo);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _email,
                        enabled: !busy,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            CredentialRules.validateEmail(value ?? ''),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        enabled: !busy,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) =>
                            CredentialRules.validateExistingPassword(
                              value ?? '',
                            ),
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
                                  semanticsLabel: 'Signing in',
                                ),
                              )
                            : const Text('Sign in'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => context.pushReplacement(
                                AppRoutes.registerFrom(returnTo),
                              ),
                        child: const Text('No account? Create one'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
