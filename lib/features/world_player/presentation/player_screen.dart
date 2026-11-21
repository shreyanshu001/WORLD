import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/widgets/empty_view.dart';
import 'package:worlds/core/widgets/error_view.dart';
import 'package:worlds/core/widgets/loading_view.dart';
import 'package:worlds/features/world_player/application/play_providers.dart';
import 'package:worlds/features/world_player/domain/play_models.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/worlds/presentation/blocks/block_view.dart';
import 'package:worlds/shared/components/category_style.dart';
import 'package:worlds/shared/components/design.dart';
import 'package:worlds/shared/components/motion.dart';

/// Plays an unlocked World, full screen and reading first. Every step is
/// confirmed by the server, so leaving at any point keeps the place.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    required this.worldId,
    this.startOver = false,
    super.key,
  });

  final String worldId;

  /// Start a finished World again from its first part.
  final bool startOver;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _restartRequested = false;

  @override
  Widget build(BuildContext context) {
    final provider = playerControllerProvider(widget.worldId);
    final state = ref.watch(provider);
    final session = state.session;

    if (widget.startOver &&
        !_restartRequested &&
        session != null &&
        session.progress.completed) {
      _restartRequested = true;
      Future.microtask(() => ref.read(provider.notifier).restart());
    }

    // Opening, playing and finishing fade into one another.
    return StateSwitcher(child: _stage(state));
  }

  Widget _stage(PlayerState state) {
    final provider = playerControllerProvider(widget.worldId);
    final session = state.session;
    if (session == null) {
      final failure = state.loadFailure;
      return Scaffold(
        key: ValueKey(failure == null ? 'opening' : 'unavailable'),
        appBar: AppBar(leading: const _CloseButton()),
        body: switch (failure) {
          null => const LoadingView(label: 'Opening World'),
          LockedFailure() => const EmptyView(
            icon: Icons.lock_outline,
            title: 'Unlock this World first',
            message: 'Go to its place and check your location to unlock it.',
          ),
          NotFoundFailure() => const EmptyView(
            icon: Icons.travel_explore,
            title: "This World isn't available any more",
            message: 'Its creator may have unpublished it.',
          ),
          _ => ErrorView(
            message: failure.userMessage,
            onRetry: ref.read(provider.notifier).load,
          ),
        },
      );
    }

    if (session.progress.completed) {
      return _CompletionView(
        key: const ValueKey('complete'),
        worldId: widget.worldId,
        session: session,
      );
    }
    if (session.currentBlock == null) {
      // The server's place is a part this copy does not have. Loading again
      // gets the World as it is now.
      return Scaffold(
        key: const ValueKey('lost'),
        appBar: AppBar(leading: const _CloseButton()),
        body: ErrorView(
          message: "We lost your place in this World. Let's find it again.",
          onRetry: ref.read(provider.notifier).load,
        ),
      );
    }
    return _PartView(
      key: const ValueKey('playing'),
      worldId: widget.worldId,
      session: session,
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Close',
      icon: const Icon(Icons.close),
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.explore),
    );
  }
}

class _PartView extends ConsumerWidget {
  const _PartView({required this.worldId, required this.session, super.key});

  final String worldId;
  final PlaySession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(
      playerControllerProvider(worldId).select((s) => s.busy),
    );
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    // The screen shows this view only when the current part is known.
    final block = session.currentBlock!;
    final index = session.currentIndex;
    final total = session.blocks.length;

    return Scaffold(
      appBar: AppBar(
        leading: const _CloseButton(),
        titleSpacing: 0,
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(Space.md),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.sm),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              // The bar grows to the new part instead of jumping to it.
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: total == 0 ? 0 : (index + 1) / total),
                duration: Motion.of(context, Motion.standard),
                curve: Motion.enter,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  color: session.category.color,
                  backgroundColor: colors.outline,
                  semanticsLabel: 'Progress',
                  semanticsValue: 'Part ${index + 1} of $total',
                ),
              ),
            ),
          ),
        ),
      ),
      // The next part comes in from the right as the last one leaves to
      // the left: forward, like turning a page. Each part starts at its top.
      body: StateSwitcher(
        from: const Offset(0.06, 0),
        to: const Offset(-0.06, 0),
        child: SingleChildScrollView(
          key: ValueKey(block.id),
          padding: const EdgeInsets.fromLTRB(
            Space.xl,
            Space.lg,
            Space.xl,
            Space.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'PART ${index + 1} OF $total',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.muted,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Space.md),
              BlockView(
                block: block,
                assetPath: (id) => session.assetPaths[id],
              ),
              const SizedBox(height: Space.xl),
              if (block is StoryChoiceBlock)
                _Choices(worldId: worldId, block: block, busy: busy),
              if (block is QuestionBlock)
                _AnswerArea(
                  key: ValueKey('answer-${block.id}'),
                  worldId: worldId,
                  block: block,
                  answered: session.progress.answered.contains(block.id),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _StepBar(
        worldId: worldId,
        block: block,
        session: session,
      ),
    );
  }
}

/// Story options as large cards. Only options that lead somewhere are
/// shown as choosable; the server checks the choice again.
class _Choices extends ConsumerWidget {
  const _Choices({
    required this.worldId,
    required this.block,
    required this.busy,
  });

  final String worldId;
  final StoryChoiceBlock block;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in block.options)
          if (option.destinationBlockId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: Material(
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.lg),
                  side: BorderSide(color: colors.outline, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: busy
                      ? null
                      : () => ref
                            .read(playerControllerProvider(worldId).notifier)
                            .choose(option.id),
                  child: Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.label,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: colors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _AnswerArea extends ConsumerStatefulWidget {
  const _AnswerArea({
    required this.worldId,
    required this.block,
    required this.answered,
    super.key,
  });

  final String worldId;
  final QuestionBlock block;
  final bool answered;

  @override
  ConsumerState<_AnswerArea> createState() => _AnswerAreaState();
}

class _AnswerAreaState extends ConsumerState<_AnswerArea> {
  final _answer = TextEditingController();

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _submit() => ref
      .read(playerControllerProvider(widget.worldId).notifier)
      .submitAnswer(_answer.text);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerControllerProvider(widget.worldId));
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final feedback = state.answer;

    if (widget.answered) {
      final message = feedback is CorrectAnswer
          ? feedback.successMessage
          : null;
      return Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            color: colors.successSoft,
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          child: Row(
            children: [
              PopIn(
                child: Icon(
                  Icons.check_circle,
                  color: colors.success,
                  size: 28,
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  message == null || message.trim().isEmpty
                      ? 'Correct!'
                      : message,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final limited = feedback is AnswerRateLimited;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _answer,
          enabled: !state.busy && !limited,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Your answer'),
        ),
        if (feedback is WrongAnswer || limited) ...[
          const SizedBox(height: Space.md),
          Semantics(
            liveRegion: true,
            child: InfoChip(
              icon: limited ? Icons.hourglass_bottom : Icons.close,
              color: colors.danger,
              background: colors.dangerSoft,
              label: switch (feedback) {
                AnswerRateLimited(:final retryAfter) =>
                  'Too many tries. Try again in '
                      '${(retryAfter.inSeconds / 60).ceil()} min.',
                WrongAnswer(:final attemptsLeft) =>
                  attemptsLeft == 1
                      ? 'Not quite. 1 try left for now.'
                      : 'Not quite. $attemptsLeft tries left for now.',
                _ => '',
              },
            ),
          ),
        ],
        const SizedBox(height: Space.lg),
        FilledButton(
          onPressed: state.busy || limited || _answer.text.trim().isEmpty
              ? null
              : _submit,
          child: const Text('Check answer'),
        ),
      ],
    );
  }
}

/// Continue or Finish, plus any step error, at the bottom of the screen.
class _StepBar extends ConsumerWidget {
  const _StepBar({
    required this.worldId,
    required this.block,
    required this.session,
  });

  final String worldId;
  final ContentBlock block;
  final PlaySession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider(worldId));
    final controller = ref.read(playerControllerProvider(worldId).notifier);
    final colors = AppColors.of(context);
    final failure = state.stepFailure;

    final String? label = switch (block) {
      StoryChoiceBlock() => null,
      QuestionBlock() =>
        session.progress.answered.contains(block.id) ? 'Continue' : null,
      CompletionBlock() => 'Finish',
      _ => 'Continue',
    };
    if (label == null && failure == null) return const SizedBox.shrink();

    return BottomActionBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Text(
                "That didn't go through. ${failure.userMessage}",
                style: TextStyle(color: colors.danger),
              ),
            ),
          if (label != null)
            FilledButton(
              onPressed: state.busy ? null : controller.next,
              child: state.busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(label),
            ),
        ],
      ),
    );
  }
}

/// The end of a World: a calm, clear moment with somewhere to go next.
class _CompletionView extends ConsumerWidget {
  const _CompletionView({
    required this.worldId,
    required this.session,
    super.key,
  });

  final String worldId;
  final PlaySession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final state = ref.watch(playerControllerProvider(worldId));
    final times = session.progress.completionCount;

    return Scaffold(
      appBar: AppBar(leading: const _CloseButton()),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The one mark of success: it settles into place, once.
              PopIn(
                child: SizedBox(
                  width: 132,
                  height: 132,
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AtlasPanel(
                          category: session.category,
                          iconSize: 0,
                          seed: worldId.hashCode,
                        ),
                        const Icon(Icons.check, size: 64, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.xl),
              Text(
                'World complete',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.sm),
              Text(
                'You finished ${session.title}.',
                style: theme.textTheme.bodyLarge?.copyWith(color: colors.muted),
                textAlign: TextAlign.center,
              ),
              if (times > 1) ...[
                const SizedBox(height: Space.md),
                InfoChip(icon: Icons.replay, label: 'Finished $times times'),
              ],
              const SizedBox(height: Space.xxl),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go(AppRoutes.explore),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Find another World'),
                    ),
                    const SizedBox(height: Space.md),
                    OutlinedButton.icon(
                      onPressed: state.busy
                          ? null
                          : ref
                                .read(
                                  playerControllerProvider(worldId).notifier,
                                )
                                .restart,
                      icon: const Icon(Icons.replay),
                      label: const Text('Play again'),
                    ),
                    if (state.stepFailure case final failure?) ...[
                      const SizedBox(height: Space.md),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          "That didn't go through. ${failure.userMessage}",
                          style: TextStyle(color: colors.danger),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
