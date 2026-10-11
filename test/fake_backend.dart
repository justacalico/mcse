import 'dart:async';

import 'package:mcse/backend/backend.dart';

/// Fully controllable in-memory Backend for tests.
class FakeBackend implements Backend {
  final _events = StreamController<BackendEvent>.broadcast();

  List<LoaderInfo> loadersResult = const [
    LoaderInfo('vanilla', 'Vanilla'),
    LoaderInfo('paper', 'Paper'),
  ];
  List<GameVersionInfo> versionsResult = const [
    GameVersionInfo('1.21.1', true),
    GameVersionInfo('25w01a', false),
  ];
  List<ServerInstance> instancesResult = [];
  List<String> logResult = const ['[12:00:00] server started'];
  Map<String, String> propertiesResult = const {'server-port': '25565'};
  Map<String, String> defaultPropertiesResult = const {'motd': 'hi'};
  List<BackupInfo> backupsResult = [
    BackupInfo('backup-1.zip', 1024, DateTime.fromMillisecondsSinceEpoch(0)),
  ];
  List<JavaRuntimeInfo> runtimesResult = const [
    JavaRuntimeInfo('/usr/bin/java', '21.0.3', 21),
  ];
  String dataDirResult = '/data/mcse';
  int requiredJavaResult = 21;
  Object? error;
  final Map<String, Object> callErrors = {};
  Duration? delay;

  final List<String> calls = [];

  void emit(BackendEvent e) => _events.add(e);

  Future<T> _maybe<T>(String name, T value) async {
    calls.add(name);
    if (delay != null) await Future.delayed(delay!);
    final e = callErrors[name] ?? error;
    if (e != null) throw e;
    return value;
  }

  @override
  Stream<BackendEvent> get events => _events.stream;

  @override
  Future<List<LoaderInfo>> loaders() => _maybe('loaders', loadersResult);
  @override
  Future<List<GameVersionInfo>> gameVersions(String loader) =>
      _maybe('gameVersions:$loader', versionsResult);
  @override
  Future<String> createInstance(CreateRequest request) =>
      _maybe('createInstance', 'new-id');
  @override
  Future<List<ServerInstance>> instances() =>
      _maybe('instances', instancesResult);
  @override
  Future<void> deleteInstance(String id, {bool removeFiles = true}) =>
      _maybe('delete:$id', null);
  @override
  Future<void> start(String id) => _maybe('start:$id', null);
  @override
  Future<void> stop(String id) => _maybe('stop:$id', null);
  @override
  Future<void> restart(String id) => _maybe('restart:$id', null);
  @override
  Future<void> kill(String id) => _maybe('kill:$id', null);
  @override
  Future<void> sendCommand(String id, String command) =>
      _maybe('cmd:$id:$command', null);
  @override
  Future<List<String>> recentLog(String id) =>
      _maybe('log:$id', List.of(logResult));
  @override
  Future<ServerPing> ping(String id) =>
      _maybe('ping:$id', const ServerPing('motd', 1, 20, '1.21'));
  @override
  Future<void> updateInstance(
    String id, {
    String? name,
    int? minRamMb,
    int? maxRamMb,
    List<String>? jvmArgs,
    String? javaPath,
  }) =>
      _maybe('update:$id', null);
  @override
  Future<Map<String, String>> properties(String id) =>
      _maybe('props:$id', propertiesResult);
  @override
  Future<void> setProperties(String id, Map<String, String> changes) =>
      _maybe('setProps:$id:$changes', null);
  @override
  Future<Map<String, String>> defaultProperties() =>
      _maybe('defaultProps', defaultPropertiesResult);
  @override
  Future<List<BackupInfo>> backups(String id) =>
      _maybe('backups:$id', backupsResult);
  @override
  Future<BackupInfo> createBackup(String id) => _maybe(
      'createBackup:$id',
      BackupInfo('backup-new.zip', 2048, DateTime.fromMillisecondsSinceEpoch(0)));
  @override
  Future<void> deleteBackup(String id, String name) =>
      _maybe('delBackup:$id:$name', null);
  @override
  Future<void> restoreBackup(String id, String name) =>
      _maybe('restoreBackup:$id:$name', null);
  @override
  Future<List<JavaRuntimeInfo>> javaRuntimes() =>
      _maybe('runtimes', runtimesResult);
  @override
  Future<JavaRuntimeInfo> installJava(int feature) =>
      _maybe('installJava:$feature',
          JavaRuntimeInfo('/data/jre$feature', '17.0.1', feature));
  @override
  Future<int> requiredJava(String gameVersion) =>
      _maybe('requiredJava:$gameVersion', requiredJavaResult);
  @override
  Future<String> dataDir() => _maybe('dataDir', dataDirResult);
}

ServerInstance testServer({
  String id = 'srv-1',
  String name = 'Test Server',
  ServerStatus status = ServerStatus.stopped,
}) =>
    ServerInstance(
      id: id,
      name: name,
      loader: 'paper',
      gameVersion: '1.21.1',
      dir: '/data/mcse/instances/$id',
      jar: 'paper.jar',
      minRamMb: 1024,
      maxRamMb: 4096,
      jvmArgs: const [],
      status: status,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
