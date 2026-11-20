import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/app/router/app_router.dart';
import 'package:worlds/app/theme/app_theme.dart';

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
