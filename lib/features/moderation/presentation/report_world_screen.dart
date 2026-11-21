import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/features/moderation/application/report_providers.dart';
import 'package:worlds/features/moderation/domain/report.dart';
import 'package:worlds/shared/components/design.dart';

/// Reports a World to moderators: a reason, optional details, and a plain
/// confirmation. The creator is never told who reported.
class ReportWorldScreen extends ConsumerStatefulWidget {
  const ReportWorldScreen({required this.worldId, this.worldTitle, super.key});

  final String worldId;

  /// Shown for context when the screen was opened from the World.
  final String? worldTitle;

  @override
  ConsumerState<ReportWorldScreen> createState() => _ReportWorldScreenState();
}

class _ReportWorldScreenState extends ConsumerState<ReportWorldScreen> {
  final _details = TextEditingController();
  ReportReason? _reason;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  void _close() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.explore);

  void _send() {
    final reason = _reason;
    if (reason == null) return;
    ref
        .read(reportControllerProvider.notifier)
        .send(widget.worldId, reason: reason, details: _details.text);
  }

  /// Report failures need their own words: the general ones talk about
  /// trying again in a moment, which is wrong for a daily limit.
  static String _message(Object? error) => switch (error) {
    RateLimitedFailure() =>
      "You've sent as many reports as one account can in a day. "
          'Try again tomorrow.',
    NotFoundFailure() => "This World isn't available any more.",
    InvalidContentFailure() => "That report couldn't be sent as written.",
    _ => messageForError(error),
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportControllerProvider);
    final outcome = state.value;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: _close,
        ),
        title: const Text('Report this World'),
      ),
      body: outcome != null
          ? _Sent(outcome: outcome, onDone: _close)
          : _form(context, state),
      bottomNavigationBar: outcome != null
          ? null
          : BottomActionBar(
              // A failure shows beside the button, not at the end of a form
              // that may have scrolled out of sight.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _message(state.error),
                          style: TextStyle(color: AppColors.of(context).danger),
                        ),
                      ),
                    ),
                  FilledButton(
                    onPressed: _reason == null || state.isLoading
                        ? null
                        : _send,
                    child: state.isLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send report'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _form(BuildContext context, AsyncValue<ReportOutcome?> state) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final title = widget.worldTitle;

    // A short form, built whole: the details field keeps its place and its
    // text however the screen around it changes.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.sm,
        Space.lg,
        Space.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            child: Text(
              title == null
                  ? 'What is wrong with this World?'
                  : 'What is wrong with "$title"?',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: Space.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            child: Text(
              'A moderator reads every report. The creator is not told who '
              'sent it.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
          ),
          const SizedBox(height: Space.md),
          RadioGroup<ReportReason>(
            groupValue: _reason,
            onChanged: (reason) => setState(() => _reason = reason),
            child: Column(
              children: [
                for (final reason in ReportReason.values)
                  RadioListTile<ReportReason>(
                    value: reason,
                    enabled: !state.isLoading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(reason.label),
                    subtitle: Text(reason.explanation),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            child: TextField(
              controller: _details,
              enabled: !state.isLoading,
              maxLength: ReportRules.maxDetailsLength,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                hintText: 'Anything that helps a moderator understand',
                alignLabelWithHint: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the reporter sees once the server has the report.
class _Sent extends StatelessWidget {
  const _Sent({required this.outcome, required this.onDone});

  final ReportOutcome outcome;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final already = outcome == ReportOutcome.alreadyReported;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  already ? Icons.hourglass_top : Icons.check_circle_outline,
                  size: 56,
                  color: colors.success,
                ),
                const SizedBox(height: Space.lg),
                Text(
                  already ? 'You already reported this World' : 'Report sent',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  already
                      ? 'Your earlier report is waiting for a moderator. '
                            'There is no need to send another.'
                      : 'Thank you. A moderator will look at it. The creator '
                            'is not told who reported their World.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.muted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.xl),
                FilledButton(onPressed: onDone, child: const Text('Done')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
