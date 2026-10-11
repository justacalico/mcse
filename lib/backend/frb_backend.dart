// coverage:ignore-file
// Thin glue over the generated flutter_rust_bridge bindings — platform
// code that can't run under `flutter test`. Everything testable lives in
// AppState, which works against the Backend interface.
import 'package:mcse_bridge/mcse_bridge.dart' as frb;

import 'backend.dart';

Future<Backend> createBackend() async {
  await frb.McseBridge.init();
  await frb.initBackend();
  return FrbBackend();
}

class FrbBackend implements Backend {
  @override
  Stream<BackendEvent> get events => frb.subscribeEvents().map(_mapEvent);

  BackendEvent _mapEvent(frb.EventDto e) => BackendEvent(
        switch (e.kind) {
          'status' => EventKind.status,
          'log' => EventKind.log,
          'download' => EventKind.download,
          'created' => EventKind.created,
          'backup' => EventKind.backup,
          'install' => EventKind.install,
          _ => EventKind.error,
        },
        id: e.id,
        status: e.status,
        line: e.line,
        received: e.received?.toInt(),
        total: e.total?.toInt(),
        name: e.name,
        message: e.message,
      );

  ServerInstance _instance(frb.InstanceDto i) => ServerInstance(
        id: i.id,
        name: i.name,
        loader: i.loader,
        gameVersion: i.gameVersion,
        dir: i.dir,
        jar: i.jar,
        javaPath: i.javaPath,
        minRamMb: i.minRamMb,
        maxRamMb: i.maxRamMb,
        jvmArgs: i.jvmArgs,
        status: parseStatus(i.status),
        createdAt: DateTime.fromMillisecondsSinceEpoch(i.createdAt * 1000),
      );

  BackupInfo _backup(frb.BackupDto b) => BackupInfo(
        b.name,
        b.sizeBytes.toInt(),
        DateTime.fromMillisecondsSinceEpoch(b.createdAt * 1000),
      );

  @override
  Future<List<LoaderInfo>> loaders() async =>
      (await frb.listLoaders())
          .map((l) => LoaderInfo(l.kind, l.label))
          .toList();

  @override
  Future<List<GameVersionInfo>> gameVersions(String loader) async =>
      (await frb.gameVersions(loader: loader))
          .map((v) => GameVersionInfo(v.id, v.stable))
          .toList();

  @override
  Future<String> createInstance(CreateRequest request) => frb.createInstance(
        name: request.name,
        loader: request.loader,
        gameVersion: request.gameVersion,
        acceptEula: true,
        minRamMb: request.minRamMb,
        maxRamMb: request.maxRamMb,
        properties: request.properties,
      );

  @override
  Future<List<ServerInstance>> instances() async =>
      (await frb.listInstances()).map(_instance).toList();

  @override
  Future<void> deleteInstance(String id, {bool removeFiles = true}) =>
      frb.deleteInstance(id: id, removeFiles: removeFiles);

  @override
  Future<void> start(String id) => frb.startInstance(id: id);
  @override
  Future<void> stop(String id) => frb.stopInstance(id: id);
  @override
  Future<void> restart(String id) => frb.restartInstance(id: id);
  @override
  Future<void> kill(String id) => frb.killInstance(id: id);
  @override
  Future<void> sendCommand(String id, String command) =>
      frb.sendCommand(id: id, command: command);
  @override
  Future<List<String>> recentLog(String id) => frb.recentLog(id: id);

  @override
  Future<ServerPing> ping(String id) async {
    final p = await frb.pingInstance(id: id);
    return ServerPing(p.motd, p.onlinePlayers, p.maxPlayers, p.versionName);
  }

  @override
  Future<void> updateInstance(
    String id, {
    String? name,
    int? minRamMb,
    int? maxRamMb,
    List<String>? jvmArgs,
    String? javaPath,
  }) =>
      frb.updateInstance(
        id: id,
        name: name,
        minRamMb: minRamMb,
        maxRamMb: maxRamMb,
        jvmArgs: jvmArgs,
        javaPath: javaPath,
      );

  @override
  Future<Map<String, String>> properties(String id) =>
      frb.getProperties(id: id);
  @override
  Future<void> setProperties(String id, Map<String, String> changes) =>
      frb.setProperties(id: id, changes: changes);
  @override
  Future<Map<String, String>> defaultProperties() => frb.defaultProperties();

  @override
  Future<List<BackupInfo>> backups(String id) async =>
      (await frb.listBackups(id: id)).map(_backup).toList();
  @override
  Future<BackupInfo> createBackup(String id) async =>
      _backup(await frb.createBackup(id: id));
  @override
  Future<void> deleteBackup(String id, String name) =>
      frb.deleteBackup(id: id, name: name);
  @override
  Future<void> restoreBackup(String id, String name) =>
      frb.restoreBackup(id: id, name: name);

  @override
  Future<List<JavaRuntimeInfo>> javaRuntimes() async =>
      (await frb.javaRuntimes())
          .map((r) => JavaRuntimeInfo(r.path, r.version, r.major))
          .toList();
  @override
  Future<JavaRuntimeInfo> installJava(int feature) async {
    final r = await frb.installJava(feature: feature);
    return JavaRuntimeInfo(r.path, r.version, r.major);
  }

  @override
  Future<int> requiredJava(String gameVersion) =>
      frb.requiredJava(gameVersion: gameVersion);

  @override
  Future<String> dataDir() => frb.backendDataDir();
}
