import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/models/app_update.dart';
import 'package:mcse/services/version_checker.dart';
import 'package:mcse/state/update_state.dart';

class _StubChecker extends VersionChecker {
  _StubChecker(this.result, {this.throwOnCheck = false});
  final AppUpdate result;
  final bool throwOnCheck;
  int calls = 0;

  @override
  Future<AppUpdate> check(String currentVersion) async {
    calls++;
    if (throwOnCheck) throw const VersionCheckException('nope');
    await Future.delayed(const Duration(milliseconds: 10));
    return result;
  }
}

void main() {
  test('caches result and notifies', () async {
    final checker = _StubChecker(
        const AppUpdate(currentVersion: '1', latestVersion: '2', updateAvailable: true));
    final state = UpdateState(checker: checker, currentVersion: () async => '1');
    var notified = 0;
    state.addListener(() => notified++);
    final update = await state.check();
    expect(update!.updateAvailable, isTrue);
    expect(state.update, update);
    expect(notified, 1);
    // Same value again → no extra notification.
    await state.check();
    expect(notified, 1);
    expect(checker.calls, 2);
  });

  test('dedupes concurrent checks', () async {
    final checker = _StubChecker(const AppUpdate());
    final state = UpdateState(checker: checker, currentVersion: () async => '1');
    final a = state.check();
    final b = state.check();
    await Future.wait([a, b]);
    expect(checker.calls, 1);
  });

  test('returns null on failure', () async {
    final checker = _StubChecker(const AppUpdate(), throwOnCheck: true);
    final state = UpdateState(checker: checker, currentVersion: () async => '1');
    expect(await state.check(), isNull);
  });
}
