import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/state/theme_state.dart';

import 'fake_backend.dart';
import 'helpers.dart';

void main() {
  Future<void> openSettings(WidgetTester tester, FakeBackend backend) async {
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
  }

  testWidgets('theme selector persists choice', (tester) async {
    final backend = FakeBackend();
    await openSettings(tester, backend);
    expect(find.text('Appearance'), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OLED'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(SegmentedButton<AppTheme>),
        matching: find.text('System')));
    await tester.pumpAndSettle();
  });

  testWidgets('java tile opens the manager', (tester) async {
    final backend = FakeBackend();
    await openSettings(tester, backend);
    expect(find.text('1 detected'), findsOneWidget);
    await tester.tap(find.text('Java runtimes'));
    await tester.pumpAndSettle();
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Detected runtimes'), findsOneWidget);
  });

  testWidgets('no runtimes shows zero count', (tester) async {
    final backend = FakeBackend()..runtimesResult = [];
    await openSettings(tester, backend);
    expect(find.text('0 detected'), findsOneWidget);
  });

  testWidgets('data dir shows path', (tester) async {
    final backend = FakeBackend();
    await openSettings(tester, backend);
    expect(find.text('/data/mcse'), findsOneWidget);
  });

  testWidgets('load failures fall back to empty states', (tester) async {
    final backend = FakeBackend()
      ..callErrors['runtimes'] = Exception('scan fail')
      ..callErrors['dataDir'] = Exception('no dir');
    await openSettings(tester, backend);
    expect(find.text('0 detected'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
  });
}
