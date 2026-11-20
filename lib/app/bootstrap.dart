import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/app/config/env.dart';

/// Connects the app to its Supabase project.
typedef SupabaseInitializer =
    Future<void> Function({
      required String url,
      required String publishableKey,
    });

/// The outcome of preparing the app to run.
sealed class StartupResult {
  const StartupResult();
}

/// Configuration is valid and Supabase is initialised.
final class StartupReady extends StartupResult {
  const StartupReady();
}

/// The build-time configuration is unusable. Retrying cannot fix this.
final class StartupMisconfigured extends StartupResult {
  const StartupMisconfigured(this.problems);

  final List<EnvProblem> problems;
}

/// Supabase could not be initialised. Retrying may succeed.
final class StartupFailed extends StartupResult {
  const StartupFailed();
}

/// Validates [env] and initialises Supabase.
///
/// Never throws. The key is never logged.
Future<StartupResult> bootstrap({
  required AppEnv env,
  required SupabaseInitializer initializeSupabase,
}) async {
  final problems = env.problems;
  if (problems.isNotEmpty) return StartupMisconfigured(problems);

  try {
    await initializeSupabase(
      url: env.supabaseUrl.trim(),
      publishableKey: env.supabasePublishableKey.trim(),
    );
    return const StartupReady();
  } on Object catch (error, stackTrace) {
    developer.log(
      'Supabase initialisation failed: ${error.runtimeType}',
      name: 'worlds.startup',
      stackTrace: kDebugMode ? stackTrace : null,
    );
    return const StartupFailed();
  }
}

/// The production [SupabaseInitializer].
///
/// Safe to call again after a failure: Supabase skips re-initialisation once
/// it has succeeded.
Future<void> initializeSupabase({
  required String url,
  required String publishableKey,
}) async {
  await Supabase.initialize(url: url, publishableKey: publishableKey);
}
