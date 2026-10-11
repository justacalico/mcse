import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/app.dart';
import 'package:mcse/state/update_state.dart';

import 'fake_backend.dart';
import 'helpers.dart';

void main() {
  testWidgets('app shell navigates all destinations', (tester) async {
    final backend = FakeBackend();
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();

    expect(find.text('Servers'), findsWidgets);
    expect(find.text('No servers yet'), findsOneWidget);

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Loader'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('mcse'), findsNWidgets(2));
  });

  testWidgets('applies dark theme', (tester) async {
    final backend = FakeBackend();
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.darkTheme, isNotNull);
  });

  test('defaultUpdateState builds a checker-backed state', () {
    expect(defaultUpdateState(() async => '1.0.0'), isA<UpdateState>());
  });
}
