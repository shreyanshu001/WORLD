import 'package:flutter/material.dart';
import 'package:worlds/app/theme/app_tokens.dart';

/// Changes one piece of a screen for another without a jump: the old child
/// fades out as the new one fades in, optionally moving a little.
///
/// Children are told apart by their keys. A child with the same key as the
/// one before is the same thing, updated, and does not animate.
///
/// Nothing here loops, and with animations removed in the device's settings
/// the change is immediate (see [Motion.of]).
class StateSwitcher extends StatelessWidget {
  const StateSwitcher({
    required this.child,
    this.fill = true,
    this.alignment = Alignment.topCenter,
    this.from = Offset.zero,
    this.to,
    super.key,
  });

  /// The current child. It must have a key.
  final Widget child;

  /// Whether each child fills the space, like the body of a screen. When
  /// false the switcher is as large as its largest child.
  final bool fill;
  final AlignmentGeometry alignment;

  /// Where the new child comes from, as a fraction of its own size.
  final Offset from;

  /// Where the old child leaves to. Defaults to back where it came from.
  final Offset? to;

  @override
  Widget build(BuildContext context) {
    assert(child.key != null, 'StateSwitcher children need keys.');
    final current = child.key;
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.standard),
      reverseDuration: Motion.of(context, Motion.quick),
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      layoutBuilder: (current, previous) => Stack(
        fit: fill ? StackFit.expand : StackFit.passthrough,
        alignment: alignment,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        final fade = FadeTransition(opacity: animation, child: child);
        final offset = child.key == current ? from : (to ?? from);
        if (offset == Offset.zero) return fade;
        return SlideTransition(
          position: Tween(begin: offset, end: Offset.zero).animate(animation),
          child: fade,
        );
      },
      child: child,
    );
  }
}

/// Plays once, when first shown: [child] settles into place from slightly
/// smaller. For a single mark of success, such as a finished World.
class PopIn extends StatelessWidget {
  const PopIn({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, Motion.emphasis),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
      ),
      child: child,
    );
  }
}
