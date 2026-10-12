import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/backend/backend.dart';
import 'package:mcse/models/app_update.dart';

import 'fake_backend.dart';
import 'helpers.dart';

void main() {
  setUpAll(loadTestFonts);
  setUp(mockUrlLauncher);

  Future<void> snap(WidgetTester tester, String name, Widget app) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  testWidgets('servers page', (tester) async {
    final backend = FakeBackend()
      ..instancesResult = [
        testServer(),
        testServer(
            id: 'srv-2', name: 'Creative', status: ServerStatus.running),
      ];
    await snap(tester, 'servers', testApp(backend));
  });

  testWidgets('servers empty', (tester) async {
    await snap(tester, 'servers_empty', testApp(FakeBackend()));
  });

  testWidgets('create page', (tester) async {
    final backend = FakeBackend();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paper').last);
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/create.png'));
  });

  testWidgets('server detail console', (tester) async {
    final backend = FakeBackend()
      ..instancesResult = [testServer(status: ServerStatus.running)];
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Server'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/detail_console.png'));
  });

  testWidgets('server detail backups', (tester) async {
    final backend = FakeBackend()..instancesResult = [testServer()];
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Server'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backups'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/detail_backups.png'));
  });

  testWidgets('settings page', (tester) async {
    final backend = FakeBackend();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/settings.png'));
  });

  testWidgets('java manager page', (tester) async {
    final backend = FakeBackend()
      ..runtimesResult = const [
        JavaRuntimeInfo(
            '/data/mcse/runtimes/temurin-21/bin/java', '21.0.5', 21,
            managed: true),
        JavaRuntimeInfo('/usr/bin/java', '25.0.1', 25),
      ];
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Java runtimes'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/java.png'));
  });

  testWidgets('about page', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(FakeBackend(),
        updateState: stubUpdateState(
            result: const AppUpdate(
                currentVersion: '1.0.0',
                latestVersion: '1.0.0',
                updateAvailable: false))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/about.png'));
  });
}
