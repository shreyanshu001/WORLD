import 'package:flutter/material.dart';

/// Root widget of the WORLDS application.
///
/// Scaffold only: routing, theme and the app shell arrive in Checkpoint 1.
class WorldsApp extends StatelessWidget {
  const WorldsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'WORLDS',
      home: Scaffold(body: Center(child: Text('WORLDS'))),
    );
  }
}
