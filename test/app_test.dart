import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/app.dart';
import 'package:mcse/state/locale_state.dart';
import 'package:mcse/state/theme_state.dart';
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

  testWidgets('narrow width uses bottom navigation bar', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final backend = FakeBackend();
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('mcse'), findsNWidgets(2));
  });

  testWidgets('wide width uses navigation rail', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final backend = FakeBackend();
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('applies dark theme', (tester) async {
    final backend = FakeBackend();
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.darkTheme, isNotNull);
  });

  testWidgets('oled mode forces dark with black surfaces', (tester) async {
    final backend = FakeBackend();
    await tester.pumpWidget(buildApp(
      backend: backend,
      themeState: ThemeState(AppTheme.oled),
      localeState: LocaleState(),
      updateState: stubUpdateState(),
    ));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme!.scaffoldBackgroundColor, Colors.black);
    expect(app.darkTheme!.colorScheme.surface, Colors.black);
  });

  test('defaultUpdateState builds a checker-backed state', () {
    expect(defaultUpdateState(() async => '1.0.0'), isA<UpdateState>());
  });
}
