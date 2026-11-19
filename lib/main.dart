import 'package:flutter/widgets.dart';
import 'package:worlds/app/bootstrap.dart';
import 'package:worlds/app/config/env.dart';
import 'package:worlds/app/startup_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    StartupGate(
      env: AppEnv.fromEnvironment(),
      initializeSupabase: initializeSupabase,
    ),
  );
}
