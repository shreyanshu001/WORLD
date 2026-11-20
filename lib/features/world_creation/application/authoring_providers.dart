import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/network/supabase_client_provider.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/world_creation/data/supabase_world_authoring_repository.dart';
import 'package:worlds/features/world_creation/domain/world_authoring_repository.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';

final worldAuthoringRepositoryProvider = Provider<WorldAuthoringRepository>(
  (ref) => SupabaseWorldAuthoringRepository(ref.watch(supabaseClientProvider)),
);

/// The signed-in user's own Worlds, newest change first.
final myWorldsProvider = FutureProvider.autoDispose<List<WorldSummary>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.watch(worldAuthoringRepositoryProvider).myWorlds();
});
