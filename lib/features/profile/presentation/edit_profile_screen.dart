import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/widgets/error_view.dart';
import 'package:worlds/core/widgets/form_error_text.dart';
import 'package:worlds/core/widgets/loading_view.dart';
import 'package:worlds/features/profile/application/profile_providers.dart';
import 'package:worlds/features/profile/domain/profile.dart';
import 'package:worlds/features/profile/domain/profile_rules.dart';

/// Edits the signed-in user's username, display name and bio.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(ownProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: switch (profile) {
        AsyncData(value: final profile?) => _EditProfileForm(profile: profile),
        AsyncError(:final error) => ErrorView(
          message: messageForError(error),
          onRetry: () => ref.invalidate(ownProfileProvider),
        ),
        _ => const LoadingView(label: 'Loading profile'),
      },
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _username = TextEditingController(text: widget.profile.username);
  late final _displayName = TextEditingController(
    text: widget.profile.displayName ?? '',
  );
  late final _bio = TextEditingController(text: widget.profile.bio ?? '');

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final saved = await ref
        .read(editProfileControllerProvider.notifier)
        .save(
          username: _username.text,
          displayName: _displayName.text,
          bio: _bio.text,
        );
    if (!saved || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileControllerProvider);
    final busy = state.isLoading;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                  prefixText: '@',
                  helperText:
                      '3–20 characters: letters, numbers and underscores.',
                  helperMaxLines: 2,
                ),
                autocorrect: false,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    ProfileRules.validateUsername(value ?? ''),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayName,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Display name (optional)',
                ),
                maxLength: ProfileRules.maxDisplayNameLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    ProfileRules.validateDisplayName(value ?? ''),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bio,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Bio (optional)',
                  alignLabelWithHint: true,
                ),
                maxLength: ProfileRules.maxBioLength,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => ProfileRules.validateBio(value ?? ''),
              ),
              if (state.hasError && !busy) ...[
                const SizedBox(height: 8),
                FormErrorText(messageForError(state.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: busy ? null : _save,
                child: busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Saving',
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
