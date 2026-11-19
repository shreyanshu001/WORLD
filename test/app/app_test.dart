import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/app/app.dart';

void main() {
  testWidgets('WorldsApp builds and shows the placeholder title', (
    tester,
  ) async {
    await tester.pumpWidget(const WorldsApp());

    expect(find.text('WORLDS'), findsOneWidget);
  });
}
