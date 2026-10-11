import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/backend/backend.dart';
import 'package:mcse/state/app_state.dart';

import 'fake_backend.dart';

void main() {
  late FakeBackend backend;
  late AppState state;

  setUp(() {
    backend = FakeBackend();
    state = AppState(backend);
  });

  tearDown(() => state.dispose());

  test('refresh loads instances', () async {
    backend.instancesResult = [testServer()];
    await state.refresh();
    expect(state.instances, hasLength(1));
    expect(state.instanceById('srv-1')!.name, 'Test Server');
    expect(state.instanceById('missing'), isNull);
  });

  test('status event updates the instance', () async {
    backend.instancesResult = [testServer()];
    await state.refresh();
    backend.emit(const BackendEvent(EventKind.status,
        id: 'srv-1', status: 'running'));
    await pumpEventQueue();
    expect(state.instances.first.status, ServerStatus.running);
    // Unknown ids are ignored.
    backend.emit(const BackendEvent(EventKind.status,
        id: 'ghost', status: 'running'));
    backend.emit(const BackendEvent(EventKind.status, id: 'srv-1'));
    await pumpEventQueue();
    expect(state.instances.first.status, ServerStatus.running);
  });

  test('log events append and cap', () async {
    backend.emit(const BackendEvent(EventKind.log, id: 'a', line: 'one'));
    await pumpEventQueue();
    expect(state.logOf('a'), ['one']);
    for (var i = 0; i < 2100; i++) {
      backend.emit(BackendEvent(EventKind.log, id: 'a', line: 'line$i'));
    }
    backend.emit(const BackendEvent(EventKind.log, id: null, line: 'x'));
    backend.emit(const BackendEvent(EventKind.log, id: 'a'));
    await pumpEventQueue();
    expect(state.logOf('a').length, 2000);
    expect(state.logOf('a').last, 'line2099');
    expect(state.logOf('nope'), isEmpty);
  });

  test('download and install events drive progress', () async {
    backend.emit(const BackendEvent(EventKind.download,
        id: 'p1', received: 50, total: 100));
    await pumpEventQueue();
    expect(state.creating['p1']!.fraction, 0.5);
    backend.emit(const BackendEvent(EventKind.download, id: 'p1'));
    await pumpEventQueue();
    expect(state.creating['p1']!.total, isNull);
    backend.emit(const BackendEvent(EventKind.install, id: 'p1', line: 'x'));
    backend.emit(const BackendEvent(EventKind.install, id: 'p1'));
    await pumpEventQueue();
    expect(state.creating['p1']!.installLines, ['x']);
    backend.emit(const BackendEvent(EventKind.error,
        id: 'p1', message: 'boom'));
    await pumpEventQueue();
    expect(state.creating['p1']!.failed, isTrue);
    expect(state.creating['p1']!.error, 'boom');
    expect(state.lastError, 'boom');
    backend.emit(const BackendEvent(EventKind.error, message: 'other'));
    await pumpEventQueue();
    expect(state.lastError, 'other');
    state.dismissCreate('p1');
    expect(state.creating, isEmpty);
  });

  test('created event refreshes and clears progress', () async {
    backend.emit(const BackendEvent(EventKind.download, id: 'srv-1'));
    backend.instancesResult = [testServer()];
    backend.emit(const BackendEvent(EventKind.created, id: 'srv-1'));
    await pumpEventQueue();
    await pumpEventQueue();
    expect(state.creating, isEmpty);
    expect(state.instances, hasLength(1));
  });

  test('refresh drops creating entries for existing instances', () async {
    backend.instancesResult = [testServer()];
    backend.emit(
        const BackendEvent(EventKind.download, id: 'srv-1', received: 10));
    await pumpEventQueue();
    expect(state.creating, isNotEmpty);
    await state.refresh();
    expect(state.creating, isEmpty);
  });

  test('java events track runtime downloads', () async {
    backend.emit(const BackendEvent(EventKind.java,
        feature: 21, stage: 'download', received: 50, total: 100));
    await pumpEventQueue();
    expect(state.javaDownloads[21]!.fraction, 0.5);
    backend.emit(const BackendEvent(EventKind.java,
        feature: 21, stage: 'extract'));
    await pumpEventQueue();
    expect(state.javaDownloads[21]!.stage, 'extract');
    backend.emit(const BackendEvent(EventKind.java,
        feature: 21, stage: 'installed'));
    await pumpEventQueue();
    expect(state.javaDownloads, isEmpty);
    // Events without a feature are ignored.
    backend.emit(const BackendEvent(EventKind.java, stage: 'download'));
    await pumpEventQueue();
    expect(state.javaDownloads, isEmpty);
    // A failed install leaves a stale entry until explicitly finished.
    backend.emit(const BackendEvent(EventKind.java,
        feature: 8, stage: 'download', received: 1));
    await pumpEventQueue();
    state.finishJavaDownload(8);
    expect(state.javaDownloads, isEmpty);
  });

  test('backup event notifies', () async {
    var notified = 0;
    state.addListener(() => notified++);
    backend.emit(const BackendEvent(EventKind.backup, id: 'srv-1'));
    await pumpEventQueue();
    expect(notified, greaterThan(0));
  });

  test('loadRecentLog fills the log', () async {
    await state.loadRecentLog('srv-1');
    expect(state.logOf('srv-1'), ['[12:00:00] server started']);
  });

  test('loadRecentLog failure records lastError', () async {
    backend.error = Exception('no log');
    await state.loadRecentLog('srv-1');
    expect(state.lastError, contains('no log'));
    expect(state.logOf('srv-1'), isEmpty);
  });

  test('loadRecentLog merges lines streamed during the fetch', () async {
    backend.emit(const BackendEvent(EventKind.log,
        id: 'srv-1', line: 'live-1'));
    backend.emit(const BackendEvent(EventKind.log,
        id: 'srv-1', line: 'live-2'));
    await pumpEventQueue();
    backend.logResult = ['snap-1', 'live-1'];
    await state.loadRecentLog('srv-1');
    expect(state.logOf('srv-1'), ['snap-1', 'live-1', 'live-2']);

    backend.logResult = ['snap-2'];
    await state.loadRecentLog('srv-1');
    expect(state.logOf('srv-1'),
        ['snap-2', 'snap-1', 'live-1', 'live-2']);
  });

  test('refresh failure records lastError', () async {
    backend.error = Exception('db gone');
    await state.refresh();
    expect(state.lastError, contains('db gone'));
  });

  test('error event only fails tracked creations', () async {
    backend.emit(const BackendEvent(EventKind.error,
        id: 'srv-1', message: 'oops'));
    await pumpEventQueue();
    expect(state.creating, isEmpty);
    expect(state.lastError, 'oops');

    backend.emit(const BackendEvent(EventKind.download,
        id: 'srv-2', received: 1, total: 2));
    backend.emit(const BackendEvent(EventKind.error,
        id: 'srv-2', message: 'disk full'));
    await pumpEventQueue();
    expect(state.creating['srv-2']?.failed, isTrue);

    // A late download event does not clear the failure.
    backend.emit(const BackendEvent(EventKind.download,
        id: 'srv-2', received: 2, total: 2));
    await pumpEventQueue();
    expect(state.creating['srv-2']?.failed, isTrue);
  });

  test('install lines are capped', () async {
    backend.emit(const BackendEvent(EventKind.download,
        id: 'c1', received: 1, total: 2));
    for (var i = 0; i < 250; i++) {
      backend.emit(BackendEvent(EventKind.install,
          id: 'c1', line: 'line-$i'));
    }
    await pumpEventQueue();
    final lines = state.creating['c1']!.installLines;
    expect(lines.length, 200);
    expect(lines.last, 'line-249');
  });

  test('actions delegate to backend', () async {
    await state.start('a');
    await state.stop('a');
    await state.restart('a');
    await state.kill('a');
    await state.sendCommand('a', 'say hi');
    await state.delete('a');
    expect(
        backend.calls,
        containsAll([
          'start:a',
          'stop:a',
          'restart:a',
          'kill:a',
          'cmd:a:say hi',
          'delete:a',
          'instances',
        ]));
    expect(state.lastError, isNull);
  });

  test('action errors surface in lastError and rethrow', () async {
    backend.error = Exception('nope');
    await expectLater(state.start('a'), throwsException);
    expect(state.lastError, contains('nope'));
  });

  test('parseStatus maps all values', () {
    expect(parseStatus('starting'), ServerStatus.starting);
    expect(parseStatus('running'), ServerStatus.running);
    expect(parseStatus('stopping'), ServerStatus.stopping);
    expect(parseStatus('crashed'), ServerStatus.crashed);
    expect(parseStatus('stopped'), ServerStatus.stopped);
    expect(parseStatus('???'), ServerStatus.stopped);
  });

  test('instance helpers', () {
    final s = testServer(status: ServerStatus.starting);
    expect(s.isOnline, isTrue);
    expect(s.isBusy, isTrue);
    expect(testServer(status: ServerStatus.stopping).isBusy, isTrue);
    expect(testServer(status: ServerStatus.stopped).isOnline, isFalse);
    expect(s.copyWith(name: 'x').name, 'x');
    expect(s.copyWith().name, s.name);
    expect(s.copyWith(status: ServerStatus.crashed).status,
        ServerStatus.crashed);
  });
}
