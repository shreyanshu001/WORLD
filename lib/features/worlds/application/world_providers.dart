import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/network/supabase_client_provider.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/worlds/data/supabase_world_repository.dart';
import 'package:worlds/features/worlds/domain/world_details.dart';
import 'package:worlds/features/worlds/domain/world_repository.dart';
import 'package:worlds/shared/models/geo_point.dart';

final worldRepositoryProvider = Provider<WorldRepository>(
  (ref) => SupabaseWorldRepository(ref.watch(supabaseClientProvider)),
);

final worldMediaRepositoryProvider = Provider<WorldMediaRepository>(
  (ref) => SupabaseWorldMediaRepository(ref.watch(supabaseClientProvider)),
);

/// Which World to show, and the user's position to measure from, if known.
typedef WorldDetailsRequest = ({String worldId, GeoPoint? from});

/// Details of one World. Loaded again when the user signs in or out, since
/// that changes what they may see.
final worldDetailsProvider = FutureProvider.autoDispose
    .family<WorldDetails, WorldDetailsRequest>((ref, request) {
      ref.watch(currentUserProvider);
      return ref
          .watch(worldRepositoryProvider)
          .details(request.worldId, from: request.from);
    });

/// A signed address for a stored image, reused until shortly before it
/// expires.
final worldImageUrlProvider = FutureProvider.autoDispose.family<Uri, String>((
  ref,
  storagePath,
) async {
  final url = await ref
      .watch(worldMediaRepositoryProvider)
      .imageUrl(storagePath);
  final link = ref.keepAlive();
  final timer = Timer(
    SupabaseWorldMediaRepository.urlLifetime - const Duration(minutes: 10),
    link.close,
  );
  ref.onDispose(timer.cancel);
  return url;
});
