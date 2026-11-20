import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/network/supabase_client_provider.dart';
import 'package:worlds/features/worlds/data/supabase_world_repository.dart';
import 'package:worlds/features/worlds/domain/world_repository.dart';

final worldRepositoryProvider = Provider<WorldRepository>(
  (ref) => SupabaseWorldRepository(ref.watch(supabaseClientProvider)),
);
