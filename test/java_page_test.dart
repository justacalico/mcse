import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/backend/backend.dart';

import 'fake_backend.dart';
import 'helpers.dart';

void main() {
  Future<void> openJavaPage(WidgetTester tester, FakeBackend backend) async {
    await tester.pumpWidget(testApp(backend));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Java runtimes'), 200);
    await tester.tap(find.text('Java runtimes'));
    await tester.pumpAndSettle();
  }

  Finder releaseRow(String title) => find.ancestor(
      of: find.text(title), matching: find.byType(ListTile));

  testWidgets('lists downloadable releases with install actions',
      (tester) async {
    final backend = FakeBackend();
    await openJavaPage(tester, backend);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Java 25'), findsOneWidget);
    expect(find.text('Java 17'), findsOneWidget);
    expect(find.text('LTS'), findsWidgets);
    expect(find.text('Install'), findsNWidgets(4));
  });

  testWidgets('install calls the backend and refreshes runtimes',
      (tester) async {
    final backend = FakeBackend();
    await openJavaPage(tester, backend);
    backend.calls.clear();
    await tester.tap(find.descendant(
        of: releaseRow('Java 17'), matching: find.text('Install')));
    await tester.pumpAndSettle();
    expect(backend.calls, contains('installJava:17'));
    expect(backend.calls, contains('runtimes'));
  });

  testWidgets('managed runtime is marked installed and removable',
      (tester) async {
    final backend = FakeBackend()
      ..runtimesResult = const [
        JavaRuntimeInfo(
            '/data/mcse/runtimes/temurin-21/bin/java', '21.0.5', 21,
            managed: true),
        JavaRuntimeInfo('/usr/bin/java', '25.0.1', 25),
      ];
    await openJavaPage(tester, backend);
    expect(
        find.descendant(
            of: releaseRow('Java 21'), matching: find.text('Installed')),
        findsOneWidget);
    expect(find.byTooltip('Remove'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    expect(backend.calls, contains('removeJava:21'));
  });

  testWidgets('download progress shows a bar and label', (tester) async {
    final backend = FakeBackend();
    await openJavaPage(tester, backend);
    backend.emit(const BackendEvent(EventKind.java,
        feature: 17,
        stage: 'download',
        received: 50 * 1024 * 1024,
        total: 100 * 1024 * 1024));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('50 / 100 MB'), findsOneWidget);
    backend.emit(const BackendEvent(EventKind.java,
        feature: 17, stage: 'extract'));
    // The extract stage shows an indeterminate bar, which never settles.
    await tester.pump();
    await tester.pump();
    expect(find.text('Extracting…'), findsOneWidget);
    backend.emit(const BackendEvent(EventKind.java,
        feature: 17, stage: 'installed'));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('install failure shows a snackbar', (tester) async {
    final backend = FakeBackend();
    await openJavaPage(tester, backend);
    backend.callErrors['installJava:8'] = Exception('download failed');
    await tester.tap(find.descendant(
        of: releaseRow('Java 8'), matching: find.text('Install')));
    await tester.pumpAndSettle();
    expect(find.textContaining('download failed'), findsOneWidget);
  });

  testWidgets('releases load failure offers retry', (tester) async {
    final backend = FakeBackend()
      ..callErrors['javaReleases'] = Exception('offline');
    await openJavaPage(tester, backend);
    expect(find.text('Could not load releases'), findsOneWidget);
    backend.callErrors.remove('javaReleases');
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Java 25'), findsOneWidget);
  });

  testWidgets('no runtimes state', (tester) async {
    final backend = FakeBackend()..runtimesResult = [];
    await openJavaPage(tester, backend);
    expect(find.text('No Java runtimes found.'), findsOneWidget);
  });
}
