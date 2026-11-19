import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/app/app.dart';

void main() {
  const tabs = ['Explore', 'Saved', 'Create', 'Profile'];

  Future<void> selectTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens on Explore and shows four destinations', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorldsApp()));
    await tester.pumpAndSettle();

    expect(find.text('Explore is not built yet'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(tabs.length));
  });

  testWidgets('each tab shows its own placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorldsApp()));
    await tester.pumpAndSettle();

    for (final label in ['Saved', 'Create', 'Profile', 'Explore']) {
      await selectTab(tester, label);

      expect(find.text('$label is not built yet'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        tabs.indexOf(label),
      );
    }
  });
}
