import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  const tabs = ['Explore', 'Saved', 'Create', 'Profile'];
  const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');

  int selectedIndex(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  testWidgets('opens on Explore and shows four destinations', (tester) async {
    await pumpWorldsApp(tester, auth: FakeAuthRepository());

    expect(find.text('Explore is not built yet'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(tabs.length));
    expect(selectedIndex(tester), 0);
  });

  testWidgets('signed out, account-only tabs offer sign-in', (tester) async {
    await pumpWorldsApp(tester, auth: FakeAuthRepository());

    const expected = {
      'Saved': 'Save Worlds for later',
      'Create': 'Create a World',
      'Profile': 'Your profile',
    };
    for (final MapEntry(key: tab, value: title) in expected.entries) {
      await tapTab(tester, tab);

      expect(find.text(title), findsOneWidget, reason: tab);
      expect(selectedIndex(tester), tabs.indexOf(tab));
    }

    await tapTab(tester, 'Explore');
    expect(find.text('Explore is not built yet'), findsOneWidget);
  });

  testWidgets('signed in, each tab shows its own content', (tester) async {
    await pumpWorldsApp(
      tester,
      auth: FakeAuthRepository(signedInAs: alice),
      profiles: FakeProfileRepository()..add(testProfile(alice.id, 'alice')),
    );

    await tapTab(tester, 'Saved');
    expect(find.text('Saved is not built yet'), findsOneWidget);

    await tapTab(tester, 'Create');
    expect(find.text('Create is not built yet'), findsOneWidget);

    await tapTab(tester, 'Profile');
    expect(find.text('@alice'), findsOneWidget);
    expect(selectedIndex(tester), 3);
  });
}
