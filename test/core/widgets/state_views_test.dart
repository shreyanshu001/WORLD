import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/core/widgets/empty_view.dart';
import 'package:worlds/core/widgets/error_view.dart';
import 'package:worlds/core/widgets/loading_view.dart';

Widget host(Widget child, {double textScale = 1}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('LoadingView shows progress with a screen-reader label', (
    tester,
  ) async {
    await tester.pumpWidget(host(const LoadingView(label: 'Loading Worlds')));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Loading Worlds'), findsOneWidget);
  });

  testWidgets('EmptyView shows its title and optional message', (tester) async {
    await tester.pumpWidget(
      host(const EmptyView(icon: Icons.map, title: 'Nothing nearby')),
    );
    expect(find.text('Nothing nearby'), findsOneWidget);

    await tester.pumpWidget(
      host(
        const EmptyView(
          icon: Icons.map,
          title: 'Nothing nearby',
          message: 'Try a wider area.',
        ),
      ),
    );
    expect(find.text('Try a wider area.'), findsOneWidget);
  });

  testWidgets('ErrorView has no button without a retry action', (tester) async {
    await tester.pumpWidget(host(const ErrorView(message: 'It broke.')));

    expect(find.text('It broke.'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('ErrorView calls the retry action', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      host(ErrorView(message: 'It broke.', onRetry: () => retries++)),
    );

    await tester.tap(find.text('Try again'));

    expect(retries, 1);
  });

  testWidgets('state views do not overflow at a large text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final view in [
      const EmptyView(
        icon: Icons.map,
        title: 'Nothing nearby',
        message: 'There are no published Worlds within five kilometres.',
      ),
      ErrorView(
        message: "You're offline. Check your connection and try again.",
        onRetry: () {},
      ),
    ]) {
      await tester.pumpWidget(host(view, textScale: 3));

      expect(tester.takeException(), isNull);
    }
  });
}
