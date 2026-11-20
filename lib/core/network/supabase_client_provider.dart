import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Supabase client, available once startup has succeeded.
///
/// Only data-layer code should read this. Override it in tests.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);
