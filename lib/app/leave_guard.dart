import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks whether the user may leave the current screen; resolves to true to
/// go ahead.
typedef LeaveCheck = Future<bool> Function();

/// A screen with unsaved work registers a check here. Navigation that does
/// not go through back navigation, such as tapping the active tab to return
/// to its first screen, asks it first.
final leaveGuardProvider = NotifierProvider<LeaveGuard, LeaveCheck?>(
  LeaveGuard.new,
);

class LeaveGuard extends Notifier<LeaveCheck?> {
  @override
  LeaveCheck? build() => null;

  void register(LeaveCheck check) {
    if (ref.mounted) state = check;
  }

  /// Removes [check] if it is still the registered one. Does nothing once
  /// the app's providers are gone, for example while the app shuts down.
  void unregister(LeaveCheck check) {
    if (ref.mounted && identical(state, check)) state = null;
  }

  /// True if nothing is registered or the registered check allows leaving.
  Future<bool> mayLeave() async => await state?.call() ?? true;
}
