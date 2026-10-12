import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/backend/backend.dart';
import 'package:mcse/pages/server_detail_page.dart';
import 'package:mcse/state/app_state.dart';
import 'package:provider/provider.dart';

import 'fake_backend.dart';
import 'helpers.dart';

void main() {
  Future<void> openDetail(WidgetTester tester, FakeBackend backend,
      {ServerInstance? server}) async {
    backend.instancesResult = [server ?? testServer()];
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    await tester.tap(find.text(server?.name ?? 'Test Server'));
    await tester.pumpAndSettle();
  }

  testWidgets('console: lines, send command, controls', (tester) async {
    final backend = FakeBackend();
    await openDetail(tester, backend,
        server: testServer(status: ServerStatus.running));
    await tester.pumpAndSettle();

    expect(find.text('[12:00:00] server started'), findsOneWidget);
    backend.emit(const BackendEvent(EventKind.log,
        id: 'srv-1', line: '[12:00:01] player joined'));
    await tester.pumpAndSettle();
    expect(find.text('[12:00:01] player joined'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Enter a server command…'),
        'say hi');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(backend.calls, contains('cmd:srv-1:say hi'));

    await tester.tap(find.byTooltip('Stop'));
    await tester.pump();
    expect(backend.calls, contains('stop:srv-1'));
    await tester.tap(find.byTooltip('Kill'));
    await tester.pump();
    expect(backend.calls, contains('kill:srv-1'));
  });

  testWidgets('stopped server shows start, kill disabled', (tester) async {
    final backend = FakeBackend();
    await openDetail(tester, backend);
    await tester.tap(find.byTooltip('Start'));
    await tester.pump();
    expect(backend.calls, contains('start:srv-1'));
    final kill = tester.widget<IconButton>(
        find.ancestor(
            of: find.byIcon(Icons.power_settings_new),
            matching: find.byType(IconButton)));
    expect(kill.onPressed, isNull);
  });

  testWidgets('send button submits command, empty is ignored',
      (tester) async {
    final backend = FakeBackend();
    await openDetail(tester, backend);
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(backend.calls.where((c) => c.startsWith('cmd:')), isEmpty);
    await tester.enterText(
        find.widgetWithText(TextField, 'Enter a server command…'),
        'time set day');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(backend.calls, contains('cmd:srv-1:time set day'));
  });

  testWidgets('empty console placeholder', (tester) async {
    final backend = FakeBackend()..logResult = [];
    await openDetail(tester, backend);
    await tester.pumpAndSettle();
    expect(find.text('No console output yet.'), findsOneWidget);
  });

  testWidgets('missing server shows not found', (tester) async {
    final backend = FakeBackend();
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    final state = tester.element(find.byType(MaterialApp))
        .read<AppState>();
    await tester.pumpWidget(localized(ChangeNotifierProvider.value(
        value: state, child: const ServerDetailPage(serverId: 'ghost'))));
    await tester.pumpAndSettle();
    expect(find.text('Server not found'), findsOneWidget);
  });

  testWidgets('properties tab: load, edit, save', (tester) async {
    final backend = FakeBackend()
      ..propertiesResult = {
        'server-port': '25565',
        'motd': 'hello',
        'custom-key': 'x',
      };
    await openDetail(tester, backend);
    await tester.tap(find.text('Properties'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'server-port'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'motd'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'custom-key'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'server-port'), '25566');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(
        backend.calls, contains('setProps:srv-1:{server-port: 25566}'));
    expect(find.text('Properties saved'), findsOneWidget);
  });

  testWidgets('backups tab: create, delete, restore', (tester) async {
    final backend = FakeBackend();
    await openDetail(tester, backend);
    await tester.tap(find.text('Backups'));
    await tester.pumpAndSettle();

    expect(find.text('backup-1.zip'), findsOneWidget);
    expect(find.text('0.0 MB'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Create backup'));
    await tester.pumpAndSettle();
    expect(backend.calls, contains('createBackup:srv-1'));

    // Delete runs immediately (no dialog).
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(backend.calls, contains('delBackup:srv-1:backup-1.zip'));

    // Restore asks for confirmation.
    await tester.tap(find.byTooltip('Restore'));
    await tester.pumpAndSettle();
    expect(find.text('Restore backup?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
    await tester.pumpAndSettle();
    expect(backend.calls, contains('restoreBackup:srv-1:backup-1.zip'));
  });

  testWidgets('restore cancel does nothing', (tester) async {
    final backend = FakeBackend();
    await openDetail(tester, backend);
    await tester.tap(find.text('Backups'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Restore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
        backend.calls.where((c) => c.startsWith('restoreBackup:')),
        isEmpty);
  });

  testWidgets('properties load and save errors surface', (tester) async {
    final backend = FakeBackend()
      ..callErrors['props:srv-1'] = Exception('io error');
    await openDetail(tester, backend);
    await tester.tap(find.text('Properties'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Failed to load properties'), findsOneWidget);
  });

  testWidgets('properties save failure shows snackbar', (tester) async {
    final backend = FakeBackend();
    await openDetail(tester, backend);
    await tester.tap(find.text('Properties'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'server-port'), '1');
    backend.callErrors['setProps:srv-1:{server-port: 1}'] =
        Exception('write fail');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Save failed'), findsOneWidget);
  });

  testWidgets('backups empty state', (tester) async {
    final backend = FakeBackend()..backupsResult = [];
    await openDetail(tester, backend);
    await tester.tap(find.text('Backups'));
    await tester.pumpAndSettle();
    expect(find.text('No backups yet.'), findsOneWidget);
  });

  testWidgets('backups load error', (tester) async {
    final backend = FakeBackend()
      ..callErrors['backups:srv-1'] = Exception('zip read fail');
    await openDetail(tester, backend);
    await tester.tap(find.text('Backups'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Failed to load backups'), findsOneWidget);
  });

  testWidgets('backups action errors show snackbar', (tester) async {
    final backend = FakeBackend()
      ..callErrors['createBackup:srv-1'] = Exception('no space');
    await openDetail(tester, backend);
    await tester.tap(find.text('Backups'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create backup'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Backup failed'), findsOneWidget);

    backend.callErrors['delBackup:srv-1:backup-1.zip'] =
        Exception('locked');
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Backup failed'), findsWidgets);

    backend.callErrors['restoreBackup:srv-1:backup-1.zip'] =
        Exception('corrupt');
    await tester.tap(find.byTooltip('Restore'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Backup failed'), findsWidgets);
  });

  testWidgets('settings tab: fields + java dropdown + save',
      (tester) async {
    final backend = FakeBackend();
    await openDetail(tester, backend);
    await tester.tap(find.widgetWithText(Tab, 'Settings'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Min RAM (MB)'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Max RAM (MB)'), findsOneWidget);
    expect(
        find.widgetWithText(TextField, 'Extra JVM args'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Min RAM (MB)'), '2048');
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('/usr/bin/java').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(backend.calls, contains('update:srv-1'));
    expect(find.text('Settings saved'), findsOneWidget);
  });

  testWidgets('settings tab runtimes failure shows empty dropdown',
      (tester) async {
    final backend = FakeBackend()
      ..callErrors['runtimes'] = Exception('no jdk');
    await openDetail(tester, backend);
    await tester.tap(find.widgetWithText(Tab, 'Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Auto (best match)'), findsOneWidget);
  });

  testWidgets('console follows output only when scrolled to bottom',
      (tester) async {
    final backend = FakeBackend();
    await openDetail(tester, backend,
        server: testServer(status: ServerStatus.running));
    await tester.pumpAndSettle();
    for (var i = 0; i < 60; i++) {
      backend.emit(BackendEvent(EventKind.log,
          id: 'srv-1', line: 'line-$i'));
    }
    await tester.pumpAndSettle();
    // Scroll up: new lines must not yank the view back down.
    await tester.drag(
        find.byType(ListView).first, const Offset(0, 400));
    await tester.pump();
    backend.emit(const BackendEvent(EventKind.log,
        id: 'srv-1', line: 'newest'));
    await tester.pump();
    expect(find.text('line-59'), findsNothing);
  });

  testWidgets('settings tab reloads fields when server changes',
      (tester) async {
    final backend = FakeBackend();
    await openDetail(tester, backend);
    await tester.tap(find.widgetWithText(Tab, 'Settings'));
    await tester.pumpAndSettle();
    backend.instancesResult = [testServer(name: 'Renamed')];
    backend.emit(const BackendEvent(EventKind.created, id: 'srv-2'));
    await tester.pumpAndSettle();
    final name = tester
        .widget<TextField>(find.byType(TextField).first)
        .controller!
        .text;
    expect(name, 'Renamed');
  });

  testWidgets('settings tab keeps a custom java path selectable',
      (tester) async {
    final backend = FakeBackend();
    await openDetail(
        tester, backend,
        server: testServer(javaPath: '/opt/jdk19/bin/java'));
    await tester.tap(find.widgetWithText(Tab, 'Settings'));
    await tester.pumpAndSettle();
    expect(find.text('/opt/jdk19/bin/java'), findsOneWidget);
  });

  testWidgets('settings tab save failure shows snackbar', (tester) async {
    final backend = FakeBackend();
    await openDetail(tester, backend);
    await tester.tap(find.widgetWithText(Tab, 'Settings'));
    await tester.pumpAndSettle();
    backend.callErrors['update:srv-1'] = Exception('denied');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Save failed'), findsOneWidget);
  });

  testWidgets('delete server dialog', (tester) async {
    final backend = FakeBackend();
    await openDetail(tester, backend);
    await tester.tap(find.byTooltip('Delete server'));
    await tester.pumpAndSettle();
    expect(find.text('Delete server?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(backend.calls.contains('delete:srv-1'), isFalse);

    backend.instancesResult = [];
    await tester.tap(find.byTooltip('Delete server'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(backend.calls, contains('delete:srv-1'));
    expect(find.text('No servers yet'), findsOneWidget);
  });

  testWidgets('detail renders inside the main layout', (tester) async {
    final backend = FakeBackend();
    await openDetail(tester, backend);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Console'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Test Server'), findsOneWidget);
  });

  testWidgets('reselecting Servers pops the detail page', (tester) async {
    final backend = FakeBackend();
    await openDetail(tester, backend);
    await tester.tap(find.text('Servers'));
    await tester.pumpAndSettle();
    expect(find.text('Test Server'), findsOneWidget);
    expect(find.text('Console'), findsNothing);
  });

  testWidgets('status events rerender detail header', (tester) async {
    final backend = FakeBackend();
    await openDetail(tester, backend);
    backend.emit(const BackendEvent(EventKind.status,
        id: 'srv-1', status: 'running'));
    await tester.pumpAndSettle();
    expect(find.text('Running'), findsWidgets);
    expect(find.byTooltip('Stop'), findsOneWidget);
  });
}
