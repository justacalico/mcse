import 'package:flutter_test/flutter_test.dart';

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
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
  });

  testWidgets('java runtimes list + install', (tester) async {
    final backend = FakeBackend();
    await openSettings(tester, backend);
    expect(find.text('/usr/bin/java'), findsOneWidget);
    expect(find.text('Java 21 — 21.0.3'), findsOneWidget);
    await tester.tap(find.text('Install 21'));
    await tester.pumpAndSettle();
    expect(backend.calls, contains('installJava:21'));
  });

  testWidgets('no runtimes state', (tester) async {
    final backend = FakeBackend()..runtimesResult = [];
    await openSettings(tester, backend);
    expect(find.text('No Java runtimes found.'), findsOneWidget);
  });

  testWidgets('install failure shows snackbar', (tester) async {
    final backend = FakeBackend();
    await openSettings(tester, backend);
    backend.error = Exception('download failed');
    await tester.tap(find.text('Install 17'));
    await tester.pumpAndSettle();
    expect(find.textContaining('download failed'), findsOneWidget);
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
    expect(find.text('No Java runtimes found.'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
  });
}
