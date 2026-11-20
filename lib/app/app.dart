import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/app/router/app_router.dart';
import 'package:worlds/app/theme/app_theme.dart';

/// Turns off Riverpod's automatic retry of failed providers, so failures
/// reach the screen immediately and the user decides when to retry.
Duration? noAutomaticRetry(int retryCount, Object error) => null;

/// Root widget of the WORLDS application.
///
/// Must be placed under a `ProviderScope`.
class WorldsApp extends ConsumerWidget {
  const WorldsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'WORLDS',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
