import 'package:flutter/material.dart';

/// Explains why the app wants the device's location before Android's own
/// prompt appears (docs/SECURITY_AND_PRIVACY.md). Returns true only if the
/// user chose to continue; "Not now" must not lead to any location request.
Future<bool> confirmLocationUse(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final agreed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.my_location),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  return agreed ?? false;
}
