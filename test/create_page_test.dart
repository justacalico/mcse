import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';
import 'helpers.dart';

void main() {
  Future<void> openCreate(WidgetTester tester, FakeBackend backend) async {
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(finder, 200,
          scrollable: find
              .descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable))
              .first);

  Future<void> acceptEula(WidgetTester tester) async {
    await scrollTo(tester, find.text('I accept the Minecraft EULA'));
    await tester.tap(find.text('I accept the Minecraft EULA'));
    await tester.pumpAndSettle();
  }

  Future<void> tapCreate(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Create server');
    await scrollTo(tester, button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> pickLoader(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> pickVersion(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1.21.1').last);
    await tester.pumpAndSettle();
  }

  testWidgets('full create flow', (tester) async {
    final backend = FakeBackend();
    await openCreate(tester, backend);

    expect(find.text('Select a loader'), findsOneWidget);

    await pickLoader(tester, 'Paper');
    expect(backend.calls, contains('gameVersions:paper'));

    await pickVersion(tester);
    await scrollTo(tester, find.widgetWithText(TextField, 'Server name'));
    await tester.enterText(
        find.widgetWithText(TextField, 'Server name'), 'My Server');
    await tester.drag(find.byType(Slider), const Offset(120, 0));
    await acceptEula(tester);
    await tapCreate(tester);
    expect(backend.calls, contains('createInstance'));
  });

  testWidgets('snapshot toggle hides unstable versions', (tester) async {
    final backend = FakeBackend();
    await openCreate(tester, backend);
    await pickLoader(tester, 'Vanilla');

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    expect(find.text('25w01a'), findsNothing);
    await tester.tap(find.text('1.21.1').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Releases only'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    expect(find.text('25w01a'), findsOneWidget);
  });

  testWidgets('toggling releases clears a selected snapshot', (tester) async {
    final backend = FakeBackend();
    await openCreate(tester, backend);
    await pickLoader(tester, 'Vanilla');

    await tester.tap(find.text('Releases only'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('25w01a').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Releases only'));
    await tester.pumpAndSettle();
    expect(find.text('Select a game version'), findsOneWidget);
  });

  testWidgets('empty name falls back to default', (tester) async {
    final backend = FakeBackend();
    await openCreate(tester, backend);
    await pickLoader(tester, 'Vanilla');
    await pickVersion(tester);
    await scrollTo(tester, find.widgetWithText(TextField, 'Server name'));
    await tester.enterText(
        find.widgetWithText(TextField, 'Server name'), '   ');
    await acceptEula(tester);
    await tapCreate(tester);
    expect(backend.calls, contains('createInstance'));
  });

  testWidgets('create failure shows error', (tester) async {
    final backend = FakeBackend();
    await openCreate(tester, backend);
    await pickLoader(tester, 'Paper');
    await pickVersion(tester);
    await acceptEula(tester);
    backend.error = Exception('disk full');
    await tapCreate(tester);
    expect(find.textContaining('disk full'), findsOneWidget);
  });

  testWidgets('versions loading shows spinner', (tester) async {
    final backend = FakeBackend()..delay = const Duration(seconds: 1);
    await openCreate(tester, backend);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paper').last);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('loaders and versions failures show error', (tester) async {
    final backend = FakeBackend()
      ..callErrors['gameVersions:paper'] = Exception('offline');
    await openCreate(tester, backend);
    await pickLoader(tester, 'Paper');
    await scrollTo(tester, find.textContaining('offline'));
    expect(find.textContaining('offline'), findsOneWidget);
  });

  testWidgets('loaders failure shows error', (tester) async {
    final backend = FakeBackend()
      ..callErrors['loaders'] = Exception('api down');
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.textContaining('api down'));
    expect(find.textContaining('api down'), findsOneWidget);
  });

  testWidgets('requires eula and version before create', (tester) async {
    final backend = FakeBackend();
    await openCreate(tester, backend);
    final button = find.widgetWithText(FilledButton, 'Create server');
    await scrollTo(tester, button);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
  });
}
