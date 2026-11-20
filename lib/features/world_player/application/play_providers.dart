import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/location/location_providers.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/core/network/supabase_client_provider.dart';
import 'package:worlds/features/world_player/data/supabase_world_play_repository.dart';
import 'package:worlds/features/world_player/domain/play_models.dart';
import 'package:worlds/features/world_player/domain/world_play_repository.dart';
import 'package:worlds/features/worlds/application/world_providers.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';

final worldPlayRepositoryProvider = Provider<WorldPlayRepository>(
  (ref) => SupabaseWorldPlayRepository(ref.watch(supabaseClientProvider)),
);

// ---------------------------------------------------------------------------
// Unlocking
// ---------------------------------------------------------------------------

/// Where an unlock attempt stands.
enum UnlockPhase {
  idle,
  locating,
  checking,
  unlocked,
  tooFar,
  inaccurate,
  denied,
  deniedForever,
  serviceDisabled,
  unavailable,
  failed,
}

@immutable
class UnlockState {
  const UnlockState({
    this.phase = UnlockPhase.idle,
    this.distanceMeters,
    this.radiusMeters,
    this.accuracyMeters,
    this.failure,
  });

  final UnlockPhase phase;
  final double? distanceMeters;
  final int? radiusMeters;
  final double? accuracyMeters;
  final AppFailure? failure;

  bool get busy =>
      phase == UnlockPhase.locating || phase == UnlockPhase.checking;
}

final unlockControllerProvider = NotifierProvider.autoDispose
    .family<UnlockController, UnlockState, String>(UnlockController.new);

/// Unlocks a World on site: one fresh reading, taken only when the user
/// taps, checked by the server against the World's place.
class UnlockController extends Notifier<UnlockState> {
  UnlockController(this.worldId);

  final String worldId;

  static const locationTimeout = Duration(seconds: 20);

  /// Readings vaguer than this cannot decide; the server refuses them too.
  static const maxAccuracyMeters = 100.0;

  @override
  UnlockState build() => const UnlockState();

  /// Whether Android's permission prompt will appear, so the app should
  /// explain first.
  Future<bool> shouldExplainLocation() async {
    final location = ref.read(locationServiceProvider);
    try {
      if (!await location.isServiceEnabled()) return false;
      return await location.checkPermission() ==
          LocationPermissionStatus.denied;
    } on Object {
      return false;
    }
  }

  Future<void> check() async {
    if (state.busy) return;
    final location = ref.read(locationServiceProvider);
    void set(UnlockState next) {
      if (ref.mounted) state = next;
    }

    set(const UnlockState(phase: UnlockPhase.locating));
    final LocationFix fix;
    try {
      if (!await location.isServiceEnabled()) {
        return set(const UnlockState(phase: UnlockPhase.serviceDisabled));
      }
      var permission = await location.checkPermission();
      if (permission == LocationPermissionStatus.denied) {
        permission = await location.requestPermission();
      }
      switch (permission) {
        case LocationPermissionStatus.denied:
          return set(const UnlockState(phase: UnlockPhase.denied));
        case LocationPermissionStatus.deniedForever:
          return set(const UnlockState(phase: UnlockPhase.deniedForever));
        case LocationPermissionStatus.granted:
          break;
      }
      fix = await location.currentFix(timeLimit: locationTimeout);
    } on Object {
      return set(const UnlockState(phase: UnlockPhase.unavailable));
    }

    if (fix.accuracyMeters > maxAccuracyMeters) {
      return set(
        UnlockState(
          phase: UnlockPhase.inaccurate,
          accuracyMeters: fix.accuracyMeters,
        ),
      );
    }

    set(const UnlockState(phase: UnlockPhase.checking));
    try {
      final result = await ref
          .read(worldPlayRepositoryProvider)
          .unlock(worldId, fix);
      switch (result) {
        case Unlocked():
          set(const UnlockState(phase: UnlockPhase.unlocked));
          ref.invalidate(worldDetailsProvider);
        case TooFar(:final distanceMeters, :final radiusMeters):
          set(
            UnlockState(
              phase: UnlockPhase.tooFar,
              distanceMeters: distanceMeters,
              radiusMeters: radiusMeters,
            ),
          );
        case Inaccurate(:final accuracyMeters):
          set(
            UnlockState(
              phase: UnlockPhase.inaccurate,
              accuracyMeters: accuracyMeters,
            ),
          );
      }
    } on Object catch (error) {
      set(
        UnlockState(
          phase: UnlockPhase.failed,
          failure: error is AppFailure ? error : const AppFailure.unexpected(),
        ),
      );
    }
  }

  Future<void> openSettings() async {
    final location = ref.read(locationServiceProvider);
    if (state.phase == UnlockPhase.serviceDisabled) {
      await location.openLocationSettings();
    } else {
      await location.openAppSettings();
    }
  }
}

// ---------------------------------------------------------------------------
// Playing
// ---------------------------------------------------------------------------

@immutable
class PlayerState {
  const PlayerState({
    this.session,
    this.loading = false,
    this.loadFailure,
    this.busy = false,
    this.stepFailure,
    this.answer,
  });

  final PlaySession? session;
  final bool loading;
  final AppFailure? loadFailure;

  /// A step or answer is with the server.
  final bool busy;

  /// The last step or answer failed; the player can try it again.
  final AppFailure? stepFailure;

  /// Feedback for the current question, if one was answered.
  final AnswerResult? answer;

  PlayerState copyWith({
    PlaySession? session,
    bool? loading,
    AppFailure? loadFailure,
    bool clearLoadFailure = false,
    bool? busy,
    AppFailure? stepFailure,
    bool clearStepFailure = false,
    AnswerResult? answer,
    bool clearAnswer = false,
  }) => PlayerState(
    session: session ?? this.session,
    loading: loading ?? this.loading,
    loadFailure: clearLoadFailure ? null : loadFailure ?? this.loadFailure,
    busy: busy ?? this.busy,
    stepFailure: clearStepFailure ? null : stepFailure ?? this.stepFailure,
    answer: clearAnswer ? null : answer ?? this.answer,
  );
}

final playerControllerProvider = NotifierProvider.autoDispose
    .family<PlayerController, PlayerState, String>(PlayerController.new);

/// Plays an unlocked World one part at a time. The server decides every
/// step; the app shows what it confirmed and never moves on by itself.
class PlayerController extends Notifier<PlayerState> {
  PlayerController(this.worldId);

  final String worldId;

  @override
  PlayerState build() {
    scheduleMicrotask(load);
    return const PlayerState(loading: true);
  }

  WorldPlayRepository get _repository => ref.read(worldPlayRepositoryProvider);

  Future<void> load() async {
    if (!ref.mounted) return;
    state = state.copyWith(loading: true, clearLoadFailure: true);
    try {
      final session = await _repository.load(worldId);
      if (!ref.mounted) return;
      state = PlayerState(session: session);
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, loadFailure: _failure(error));
    }
  }

  /// Continues past the current part (not a choice).
  Future<void> next() => _advance(null);

  /// Picks a story option.
  Future<void> choose(String optionId) => _advance(optionId);

  Future<void> _advance(String? optionId) async {
    final session = state.session;
    final current = session?.currentBlock;
    if (session == null || current == null || state.busy) return;
    state = state.copyWith(busy: true, clearStepFailure: true);
    try {
      final result = await _repository.advance(
        worldId,
        fromBlockId: current.id,
        optionId: optionId,
      );
      if (!ref.mounted) return;
      if (result.stale) {
        // The server had already moved on: show where it really is.
        await load();
        return;
      }
      state = PlayerState(session: session.copyWith(progress: result.progress));
      _refreshDetails();
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(busy: false, stepFailure: _failure(error));
      }
    }
  }

  Future<void> submitAnswer(String answer) async {
    final session = state.session;
    final current = session?.currentBlock;
    if (session == null || current is! QuestionBlock || state.busy) return;
    if (answer.trim().isEmpty) return;
    state = state.copyWith(busy: true, clearStepFailure: true);
    try {
      final result = await _repository.answer(
        worldId,
        blockId: current.id,
        answer: answer,
      );
      if (!ref.mounted) return;
      final progress = session.progress;
      state = PlayerState(
        session: result is CorrectAnswer
            ? session.copyWith(
                progress: progress.copyWith(
                  answered: {...progress.answered, current.id}.toList(),
                ),
              )
            : session,
        answer: result,
      );
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(busy: false, stepFailure: _failure(error));
      }
    }
  }

  Future<void> restart() async {
    final session = state.session;
    if (session == null || state.busy) return;
    state = state.copyWith(busy: true, clearStepFailure: true);
    try {
      final progress = await _repository.restart(worldId);
      if (!ref.mounted) return;
      state = PlayerState(session: session.copyWith(progress: progress));
      _refreshDetails();
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(busy: false, stepFailure: _failure(error));
      }
    }
  }

  void _refreshDetails() => ref.invalidate(worldDetailsProvider);

  static AppFailure _failure(Object error) =>
      error is AppFailure ? error : const AppFailure.unexpected();
}
