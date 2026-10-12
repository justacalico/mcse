import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/backend/backend.dart';
import 'package:mcse/services/version_checker.dart';

void main() {
  test('data classes hold their values', () {
    final loader = LoaderInfo('paper', 'Paper');
    expect(loader.kind, 'paper');
    expect(loader.label, 'Paper');
    final version = GameVersionInfo('1.21.1', true);
    expect(version.id, '1.21.1');
    expect(version.stable, isTrue);
    final ping = ServerPing('motd', 3, 20, '1.21');
    expect(ping.motd, 'motd');
    expect(ping.onlinePlayers, 3);
    expect(ping.maxPlayers, 20);
    expect(ping.versionName, '1.21');
    const rt = JavaRuntimeInfo('/bin/java', '21', 21);
    expect(rt.path, '/bin/java');
    final release = JavaReleaseInfo(21, true);
    expect(release.feature, 21);
    expect(release.lts, isTrue);
    const backupName = 'b.zip';
    final backup = BackupInfo(backupName, 5, DateTime(0));
    expect(backup.sizeBytes, 5);
    const req = CreateRequest(
        name: 'n', loader: 'paper', gameVersion: '1.21.1');
    expect(req.minRamMb, 1024);
    expect(req.maxRamMb, 4096);
    expect(req.properties, isEmpty);
    const e = BackendEvent(EventKind.log);
    expect(e.kind, EventKind.log);
  });

  test('VersionCheckException toString', () {
    expect(const VersionCheckException('nope').toString(),
        'VersionCheckException: nope');
  });
}
