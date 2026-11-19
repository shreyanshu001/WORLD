import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/app/app.dart';
import 'package:worlds/app/bootstrap.dart';
import 'package:worlds/app/config/env.dart';
import 'package:worlds/app/theme/app_theme.dart';
import 'package:worlds/core/widgets/error_view.dart';
import 'package:worlds/core/widgets/loading_view.dart';

/// Runs [bootstrap] and shows the app only once startup has succeeded.
///
/// While starting it shows a loading screen. If startup fails it shows an
/// error screen, with a retry when retrying can help.
class StartupGate extends StatefulWidget {
  const StartupGate({
    required this.env,
    required this.initializeSupabase,
    super.key,
  });

  final AppEnv env;
  final SupabaseInitializer initializeSupabase;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<StartupResult> _startup = _start();

  Future<StartupResult> _start() =>
      bootstrap(env: widget.env, initializeSupabase: widget.initializeSupabase);

  void _retry() {
    // A block body, because setState rejects a callback that returns a Future.
    setState(() {
      _startup = _start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StartupResult>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupScreen(child: LoadingView(label: 'Starting'));
        }
        return switch (snapshot.data) {
          StartupReady() => const ProviderScope(child: WorldsApp()),
          StartupMisconfigured(:final problems) => _StartupScreen(
            child: ErrorView(
              message: [
                'This build is not configured.',
                ...problems.map((problem) => problem.description),
              ].join('\n'),
            ),
          ),
          StartupFailed() || null => _StartupScreen(
            child: ErrorView(
              message: "WORLDS couldn't start. Try again.",
              onRetry: _retry,
            ),
          ),
        };
      },
    );
  }
}

/// A minimal themed screen used before the real app is available.
class _StartupScreen extends StatelessWidget {
  const _StartupScreen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WORLDS',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(body: SafeArea(child: child)),
    );
  }
}
