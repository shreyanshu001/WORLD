import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/network/supabase_client_provider.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/explore/application/explore_controller.dart';
import 'package:worlds/features/saved/data/supabase_saved_worlds_repository.dart';
import 'package:worlds/features/saved/domain/saved_world.dart';
import 'package:worlds/features/saved/domain/saved_worlds_repository.dart';

final savedWorldsRepositoryProvider = Provider<SavedWorldsRepository>(
  (ref) => SupabaseSavedWorldsRepository(ref.watch(supabaseClientProvider)),
);

AppFailure _failure(Object error) =>
    error is AppFailure ? error : const AppFailure.unexpected();

// ---------------------------------------------------------------------------
// Saved or not, per World
// ---------------------------------------------------------------------------

/// Whether the signed-in user saved a World, for Worlds they saved or removed
/// in this session. It answers at once, before the server has confirmed, and
/// overrides details that were loaded before the change.
///
/// Belongs to one account: it starts empty again when another user signs in.
final savedFlagsProvider = NotifierProvider<SavedFlags, Map<String, bool>>(
  SavedFlags.new,
);

class SavedFlags extends Notifier<Map<String, bool>> {
  final _pending = <String>{};

  @override
  Map<String, bool> build() {
    ref.watch(currentUserProvider.select((user) => user?.id));
    _pending.clear();
    return const {};
  }

  void _set(String worldId, bool saved) => state = {...state, worldId: saved};

  /// Records what the saved list did itself, so details agree with it.
  void note(String worldId, {required bool saved}) => _set(worldId, saved);

  /// Saves or removes a World: the change shows at once and is taken back if
  /// the server refuses. Returns the failure, or null when it worked.
  Future<AppFailure?> setSaved(
    String worldId, {
    required bool saved,
    required bool previous,
  }) async {
    if (!_pending.add(worldId)) return null;
    final userId = ref.read(currentUserProvider)?.id;
    bool sameUser() =>
        ref.mounted && ref.read(currentUserProvider)?.id == userId;

    _set(worldId, saved);
    try {
      await ref
          .read(savedWorldsRepositoryProvider)
          .setSaved(worldId, saved: saved);
      // The saved list is out of date now; it loads again when next shown.
      if (sameUser()) ref.invalidate(savedListControllerProvider);
      return null;
    } on Object catch (error) {
      if (sameUser()) _set(worldId, previous);
      return _failure(error);
    } finally {
      _pending.remove(worldId);
    }
  }
}

// ---------------------------------------------------------------------------
// The saved list
// ---------------------------------------------------------------------------

@immutable
class SavedListState {
  const SavedListState({
    this.items = const [],
    this.loading = false,
    this.failure,
    this.hasMore = false,
    this.loadingMore = false,
    this.moreFailure,
    this.unavailable = 0,
    this.removeFailure,
  });

  final List<SavedWorld> items;

  /// The first page is on its way.
  final bool loading;

  /// The first page could not be loaded.
  final AppFailure? failure;

  final bool hasMore;
  final bool loadingMore;
  final AppFailure? moreFailure;

  /// Saved Worlds that are not published at the moment.
  final int unavailable;

  /// A removal the server refused; the World is back in the list.
  final ({String title, AppFailure failure})? removeFailure;

  SavedListState copyWith({
    List<SavedWorld>? items,
    bool? loading,
    AppFailure? failure,
    bool clearFailure = false,
    bool? hasMore,
    bool? loadingMore,
    AppFailure? moreFailure,
    bool clearMoreFailure = false,
    int? unavailable,
    ({String title, AppFailure failure})? removeFailure,
    bool clearRemoveFailure = false,
  }) => SavedListState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    failure: clearFailure ? null : failure ?? this.failure,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    moreFailure: clearMoreFailure ? null : moreFailure ?? this.moreFailure,
    unavailable: unavailable ?? this.unavailable,
    removeFailure: clearRemoveFailure
        ? null
        : removeFailure ?? this.removeFailure,
  );
}

final savedListControllerProvider =
    NotifierProvider<SavedListController, SavedListState>(
      SavedListController.new,
    );

/// The signed-in user's saved Worlds. Loaded again whenever a different
/// user signs in, so one account never sees another's list.
class SavedListController extends Notifier<SavedListState> {
  /// Counts rebuilds, so an answer for an earlier user or an earlier load is
  /// dropped.
  int _generation = 0;

  @override
  SavedListState build() {
    final userId = ref.watch(currentUserProvider.select((user) => user?.id));
    _generation++;
    if (userId == null) return const SavedListState();
    scheduleMicrotask(load);
    return const SavedListState(loading: true);
  }

  SavedWorldsRepository get _repository =>
      ref.read(savedWorldsRepositoryProvider);

  /// Loads the first page again. Distances are measured from the location
  /// the user last shared on Explore, if any; no new reading is taken.
  Future<void> load() async {
    if (!ref.mounted || ref.read(currentUserProvider) == null) return;
    final generation = ++_generation;
    state = state.copyWith(
      loading: true,
      clearFailure: true,
      clearMoreFailure: true,
    );
    try {
      final page = await _repository.list(
        from: ref.read(exploreControllerProvider).userLocation,
      );
      if (!ref.mounted || generation != _generation) return;
      state = SavedListState(
        items: page.items,
        hasMore: page.hasMore,
        unavailable: page.unavailable,
        removeFailure: state.removeFailure,
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(loading: false, failure: _failure(error));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.loading) return;
    final generation = _generation;
    state = state.copyWith(loadingMore: true, clearMoreFailure: true);
    try {
      final page = await _repository.list(
        offset: state.items.length,
        from: ref.read(exploreControllerProvider).userLocation,
      );
      if (!ref.mounted || generation != _generation) return;
      final known = {for (final world in state.items) world.id};
      state = state.copyWith(
        items: [
          ...state.items,
          for (final world in page.items)
            if (!known.contains(world.id)) world,
        ],
        hasMore: page.hasMore,
        loadingMore: false,
        unavailable: page.unavailable,
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(loadingMore: false, moreFailure: _failure(error));
    }
  }

  /// Removes a World from the list at once, and puts it back where it was
  /// if the server refuses.
  Future<void> remove(SavedWorld world) async {
    final index = state.items.indexWhere((item) => item.id == world.id);
    if (index < 0) return;
    final generation = _generation;
    final flags = ref.read(savedFlagsProvider.notifier);
    state = state.copyWith(
      items: [...state.items]..removeAt(index),
      clearRemoveFailure: true,
    );
    flags.note(world.id, saved: false);
    try {
      await _repository.setSaved(world.id, saved: false);
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      final items = [...state.items];
      if (!items.any((item) => item.id == world.id)) {
        items.insert(index.clamp(0, items.length), world);
      }
      state = state.copyWith(
        items: items,
        removeFailure: (title: world.title, failure: _failure(error)),
      );
      flags.note(world.id, saved: true);
    }
  }

  void dismissRemoveFailure() =>
      state = state.copyWith(clearRemoveFailure: true);
}
