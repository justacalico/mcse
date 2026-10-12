import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/backend/backend.dart';

import 'fake_backend.dart';
import 'helpers.dart';

void main() {
  setUp(mockUrlLauncher);

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
    await tester.pump();
    await tester.pump();
  }

  Future<void> pickLoader(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Finder inDialog(Finder matching) => find.descendant(
      of: find.byType(AlertDialog), matching: matching);

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

  testWidgets('version dropdown lists all versions', (tester) async {
    final backend = FakeBackend();
    await openCreate(tester, backend);
    await pickLoader(tester, 'Vanilla');

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    expect(find.text('1.21.1'), findsOneWidget);
    expect(find.text('25w01a'), findsOneWidget);
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

  testWidgets('shows progress dialog and closes it when created',
      (tester) async {
    final backend = FakeBackend();
    await openCreate(tester, backend);
    await pickLoader(tester, 'Paper');
    await pickVersion(tester);
    await acceptEula(tester);
    await tapCreate(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(inDialog(find.text('Creating server…')), findsOneWidget);

    backend.emit(const BackendEvent(EventKind.download,
        id: 'new-id', received: 524288, total: 1048576));
    await tester.pump();
    expect(inDialog(find.textContaining('0.5 / 1.0 MB')),
        findsOneWidget);

    backend.emit(const BackendEvent(EventKind.created, id: 'new-id'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('creation failure shows error in dialog', (tester) async {
    final backend = FakeBackend();
    await openCreate(tester, backend);
    await pickLoader(tester, 'Paper');
    await pickVersion(tester);
    await acceptEula(tester);
    await tapCreate(tester);

    backend.emit(const BackendEvent(EventKind.error,
        id: 'new-id', message: 'disk full'));
    await tester.pump();
    expect(
        inDialog(find.text('Server creation failed')), findsOneWidget);
    expect(inDialog(find.text('disk full')), findsOneWidget);

    await tester.tap(inDialog(find.text('Dismiss')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    final button = find.widgetWithText(FilledButton, 'Create server');
    await scrollTo(tester, button);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('create button stays disabled while creation is in flight',
      (tester) async {
    final backend = FakeBackend();
    await openCreate(tester, backend);
    await pickLoader(tester, 'Paper');
    await pickVersion(tester);
    await acceptEula(tester);
    await tapCreate(tester);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tapAt(const Offset(400, 580));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AlertDialog), findsNothing);

    final disabled = find.widgetWithText(FilledButton, 'Creating…');
    await scrollTo(tester, disabled);
    expect(tester.widget<FilledButton>(disabled).onPressed, isNull);

    backend.emit(const BackendEvent(EventKind.created, id: 'new-id'));
    await tester.pumpAndSettle();
    final enabled = find.widgetWithText(FilledButton, 'Create server');
    await scrollTo(tester, enabled);
    expect(tester.widget<FilledButton>(enabled).onPressed, isNotNull);
  });

  testWidgets('refuses to create a server with a taken name',
      (tester) async {
    final backend = FakeBackend()
      ..instancesResult = [testServer(name: 'My Server')];
    await openCreate(tester, backend);
    await pickLoader(tester, 'Paper');
    await pickVersion(tester);
    await scrollTo(tester, find.widgetWithText(TextField, 'Server name'));
    await tester.enterText(
        find.widgetWithText(TextField, 'Server name'), 'my server');
    await acceptEula(tester);
    await tapCreate(tester);
    expect(backend.calls.where((c) => c == 'createInstance'), isEmpty);
    expect(find.text('A server with that name already exists'),
        findsOneWidget);
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

  testWidgets('eula link opens without toggling the checkbox',
      (tester) async {
    final backend = FakeBackend();
    await openCreate(tester, backend);
    await scrollTo(
        tester,
        find.textContaining('https://aka.ms/MinecraftEULA',
            findRichText: true));
    await tester.tapOnText(
        find.textRange.ofSubstring('https://aka.ms/MinecraftEULA'));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });

  testWidgets('requires eula and version before create', (tester) async {
    final backend = FakeBackend();
    await openCreate(tester, backend);
    final button = find.widgetWithText(FilledButton, 'Create server');
    await scrollTo(tester, button);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
  });
}
