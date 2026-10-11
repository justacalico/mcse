import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/models/app_update.dart';
import 'package:mcse/state/update_state.dart';

import 'fake_backend.dart';
import 'helpers.dart';

void main() {
  setUp(mockUrlLauncher);

  Future<void> openAbout(WidgetTester tester, FakeBackend backend,
      {UpdateState? update}) async {
    await tester.pumpWidget(testApp(backend, updateState: update));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows version and links', (tester) async {
    await openAbout(tester, FakeBackend());
    expect(find.text('mcse'), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
    expect(find.text('Releases'), findsOneWidget);
  });

  testWidgets('update available shows prompt and launches url',
      (tester) async {
    final update = stubUpdateState(
        result: const AppUpdate(
            currentVersion: '1.0.0',
            latestVersion: '2.0.0',
            updateAvailable: true,
            releaseUrl: 'https://example.com/r'));
    await openAbout(tester, FakeBackend(), update: update);
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2.0.0'), findsWidgets);
  });

  testWidgets('up to date shows confirmation', (tester) async {
    await openAbout(tester, FakeBackend());
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('Up to date'), findsOneWidget);
  });

  testWidgets('known update shows in tile before checking', (tester) async {
    final update = stubUpdateState(
        result: const AppUpdate(
            currentVersion: '1.0.0',
            latestVersion: '2.0.0',
            updateAvailable: true,
            releaseUrl: 'https://example.com/r'));
    await update.check();
    await openAbout(tester, FakeBackend(), update: update);
    expect(find.text('Update available: 2.0.0'), findsOneWidget);
  });

  testWidgets('releases tile launches the releases page', (tester) async {
    await openAbout(tester, FakeBackend());
    await tester.tap(find.text('Releases'));
    await tester.pumpAndSettle();
  });

  testWidgets('check failure shows error', (tester) async {
    await openAbout(tester, FakeBackend(), update: stubUpdateState(fail: true));
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('Check failed'), findsOneWidget);
  });

  testWidgets('version load failure shows placeholder', (tester) async {
    await openAbout(
        tester,
        FakeBackend(),
        update: UpdateState(
          checker: StubVersionChecker(const AppUpdate()),
          currentVersion: () async => throw StateError('no pkg'),
        ));
    expect(find.text('?'), findsOneWidget);
  });
}
