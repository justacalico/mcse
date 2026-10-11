import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/backend/backend.dart';

import 'fake_backend.dart';
import 'helpers.dart';

void main() {
  testWidgets('populated grid shows cards with actions', (tester) async {
    final backend = FakeBackend()
      ..instancesResult = [
        testServer(),
        testServer(id: 'srv-2', name: 'Second', status: ServerStatus.running),
      ];
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();

    expect(find.text('Test Server'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('paper · 1.21.1'), findsNWidgets(2));
    expect(find.byTooltip('Start'), findsOneWidget);
    expect(find.byTooltip('Stop'), findsOneWidget);
    // Only the running server offers restart.
    expect(find.byTooltip('Restart'), findsOneWidget);

    await tester.tap(find.byTooltip('Start'));
    await tester.pump();
    expect(backend.calls, contains('start:srv-1'));

    await tester.tap(find.byTooltip('Stop'));
    await tester.pump();
    expect(backend.calls, contains('stop:srv-2'));

    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(backend.calls, contains('restart:srv-2'));
  });

  testWidgets('creating tile shows progress and failure states',
      (tester) async {
    final backend = FakeBackend();
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();

    backend.emit(const BackendEvent(EventKind.download,
        id: 'c1', received: 524288, total: 1048576));
    await tester.pumpAndSettle();
    expect(find.text('Creating server…'), findsOneWidget);
    expect(find.text('Downloading 0.5 / 1.0 MB'), findsOneWidget);

    backend.emit(const BackendEvent(EventKind.download,
        id: 'c1', received: 524288));
    // Indeterminate progress keeps animating; pumpAndSettle would hang.
    await tester.pump();
    await tester.pump();
    expect(find.text('Downloading 0.5 MB'), findsOneWidget);

    backend.emit(const BackendEvent(EventKind.install, id: 'c1', line: 'running installer'));
    await tester.pump();
    await tester.pump();
    expect(find.text('running installer'), findsOneWidget);

    backend.emit(const BackendEvent(EventKind.error,
        id: 'c1', message: 'disk full'));
    await tester.pumpAndSettle();
    expect(find.text('Server creation failed'), findsOneWidget);
    // Tile + global error snackbar both show the message.
    expect(find.text('disk full'), findsWidgets);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('Server creation failed'), findsNothing);
  });

  testWidgets('card opens detail page', (tester) async {
    final backend = FakeBackend()..instancesResult = [testServer()];
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Server'));
    await tester.pumpAndSettle();
    expect(find.text('Console'), findsOneWidget);
  });

  testWidgets('starting/stopping chips and disabled states', (tester) async {
    final backend = FakeBackend()
      ..instancesResult = [
        testServer(id: 'a', status: ServerStatus.starting),
        testServer(id: 'b', name: 'B', status: ServerStatus.stopping),
        testServer(id: 'c', name: 'C', status: ServerStatus.crashed),
      ];
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    expect(find.text('Starting'), findsOneWidget);
    expect(find.text('Stopping'), findsOneWidget);
    expect(find.text('Crashed'), findsOneWidget);
    // Busy servers can't be stopped or restarted.
    expect(backend.calls.contains('stop:a'), isFalse);
    // Stopping and crashed servers hide the restart action.
    expect(find.byTooltip('Restart'), findsOneWidget);
  });
}
