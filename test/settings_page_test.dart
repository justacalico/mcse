import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/pages/settings_page.dart';
import 'package:mcse/state/app_state.dart';
import 'package:mcse/state/dirs_state.dart';
import 'package:mcse/state/locale_state.dart';
import 'package:mcse/state/theme_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';
import 'helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openSettings(WidgetTester tester, FakeBackend backend,
      {DirsState? dirs}) async {
    await tester.pumpWidget(testApp(backend, dirsState: dirs));
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
    await tester.scrollUntilVisible(find.text('Java runtimes'), 200);
    expect(find.text('1 detected'), findsOneWidget);
    await tester.tap(find.text('Java runtimes'));
    await tester.pumpAndSettle();
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Detected runtimes'), findsOneWidget);
  });

  testWidgets('no runtimes shows zero count', (tester) async {
    final backend = FakeBackend()..runtimesResult = [];
    await openSettings(tester, backend);
    await tester.scrollUntilVisible(find.text('Java runtimes'), 200);
    expect(find.text('0 detected'), findsOneWidget);
  });

  testWidgets('data dir shows path', (tester) async {
    final backend = FakeBackend();
    await openSettings(tester, backend);
    expect(find.text('/data/mcse'), findsOneWidget);
    expect(find.text('/data/mcse/runtimes'), findsOneWidget);
    expect(find.text('/data/mcse/backups'), findsOneWidget);
  });

  testWidgets('load failures fall back to empty states', (tester) async {
    final backend = FakeBackend()
      ..callErrors['runtimes'] = Exception('scan fail')
      ..callErrors['dataDir'] = Exception('no dir')
      ..callErrors['javaDir'] = Exception('no dir')
      ..callErrors['backupsDir'] = Exception('no dir');
    await openSettings(tester, backend);
    await tester.scrollUntilVisible(find.text('Java runtimes'), 200);
    expect(find.text('0 detected'), findsOneWidget);
    expect(find.text('?'), findsNWidgets(3));
  });

  testWidgets('pending override shows restart note', (tester) async {
    final backend = FakeBackend();
    await openSettings(tester, backend,
        dirs: DirsState(dataDir: '/new/data'));
    expect(find.text('/new/data (applies after restart)'), findsOneWidget);
  });

  testWidgets('override matching the active path stays plain',
      (tester) async {
    final backend = FakeBackend();
    await openSettings(tester, backend,
        dirs: DirsState(dataDir: '/data/mcse'));
    expect(find.text('/data/mcse'), findsOneWidget);
    expect(find.textContaining('applies after restart'), findsNothing);
  });

  testWidgets('editing a dir saves the override', (tester) async {
    final backend = FakeBackend();
    final dirs = DirsState();
    await openSettings(tester, backend, dirs: dirs);
    await tester.tap(find.text('Data directory'));
    await tester.pumpAndSettle();
    expect(find.text('Browse'), findsOneWidget);
    await tester.enterText(find.byType(TextField), ' /mnt/big ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(dirs.dataDir, '/mnt/big');
    expect(find.text('/mnt/big (applies after restart)'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('dir_data'), '/mnt/big');
  });

  testWidgets('use default clears the override', (tester) async {
    final backend = FakeBackend();
    final dirs = DirsState(backupsDir: '/mnt/zips');
    await openSettings(tester, backend, dirs: dirs);
    await tester.tap(find.text('Backups directory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use default'));
    await tester.pumpAndSettle();
    expect(dirs.backupsDir, isNull);
    expect(find.text('/data/mcse/backups'), findsOneWidget);
  });

  testWidgets('cancel leaves the override alone', (tester) async {
    final backend = FakeBackend();
    final dirs = DirsState();
    await openSettings(tester, backend, dirs: dirs);
    await tester.tap(find.text('Java install location'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '/ignored');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(dirs.javaDir, isNull);
  });

  testWidgets('submitting the field saves the override', (tester) async {
    final backend = FakeBackend();
    final dirs = DirsState();
    await openSettings(tester, backend, dirs: dirs);
    await tester.tap(find.text('Backups directory'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '/mnt/zips');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(dirs.backupsDir, '/mnt/zips');
  });

  Future<void> openSettingsWithPicker(
      WidgetTester tester, FakeBackend backend, DirsState dirs,
      Future<String?> Function() pick) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ThemeState()),
        ChangeNotifierProvider.value(value: LocaleState()),
        ChangeNotifierProvider.value(value: dirs),
        ChangeNotifierProvider(create: (_) => AppState(backend)),
      ],
      child: localized(SettingsPage(pickDirectory: pick)),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('browse fills the field from the picker', (tester) async {
    final backend = FakeBackend();
    final dirs = DirsState();
    await openSettingsWithPicker(
        tester, backend, dirs, () async => '/picked/dir');
    await tester.tap(find.text('Data directory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '/picked/dir'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(dirs.dataDir, '/picked/dir');
  });

  testWidgets('browse cancelled keeps the field empty', (tester) async {
    final backend = FakeBackend();
    final dirs = DirsState();
    await openSettingsWithPicker(tester, backend, dirs, () async => null);
    await tester.tap(find.text('Java install location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, ''), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(dirs.javaDir, isNull);
  });
}
