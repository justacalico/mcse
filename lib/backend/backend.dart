import 'dart:async';

enum ServerStatus { stopped, starting, running, stopping, crashed }

ServerStatus parseStatus(String raw) => switch (raw) {
      'starting' => ServerStatus.starting,
      'running' => ServerStatus.running,
      'stopping' => ServerStatus.stopping,
      'crashed' => ServerStatus.crashed,
      _ => ServerStatus.stopped,
    };

class ServerInstance {
  final String id;
  final String name;
  final String loader;
  final String gameVersion;
  final String dir;
  final String? jar;
  final String? javaPath;
  final int minRamMb;
  final int maxRamMb;
  final List<String> jvmArgs;
  final ServerStatus status;
  final DateTime createdAt;

  const ServerInstance({
    required this.id,
    required this.name,
    required this.loader,
    required this.gameVersion,
    required this.dir,
    required this.minRamMb,
    required this.maxRamMb,
    required this.jvmArgs,
    required this.status,
    required this.createdAt,
    this.jar,
    this.javaPath,
  });

  ServerInstance copyWith({
    String? name,
    ServerStatus? status,
    String? javaPath,
    int? minRamMb,
    int? maxRamMb,
    List<String>? jvmArgs,
    String? jar,
  }) =>
      ServerInstance(
        id: id,
        name: name ?? this.name,
        loader: loader,
        gameVersion: gameVersion,
        dir: dir,
        jar: jar ?? this.jar,
        javaPath: javaPath ?? this.javaPath,
        minRamMb: minRamMb ?? this.minRamMb,
        maxRamMb: maxRamMb ?? this.maxRamMb,
        jvmArgs: jvmArgs ?? this.jvmArgs,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  bool get isOnline =>
      status == ServerStatus.running || status == ServerStatus.starting;

  bool get isBusy =>
      status == ServerStatus.starting || status == ServerStatus.stopping;
}

class LoaderInfo {
  final String kind;
  final String label;
  const LoaderInfo(this.kind, this.label);
}

class GameVersionInfo {
  final String id;
  final bool stable;
  const GameVersionInfo(this.id, this.stable);
}

class JavaRuntimeInfo {
  final String path;
  final String version;
  final int major;
  final bool managed;
  const JavaRuntimeInfo(this.path, this.version, this.major,
      {this.managed = false});
}

class JavaReleaseInfo {
  final int feature;
  final bool lts;
  const JavaReleaseInfo(this.feature, this.lts);
}

class BackupInfo {
  final String name;
  final int sizeBytes;
  final DateTime createdAt;
  const BackupInfo(this.name, this.sizeBytes, this.createdAt);
}

class ServerPing {
  final String motd;
  final int onlinePlayers;
  final int maxPlayers;
  final String versionName;
  const ServerPing(
      this.motd, this.onlinePlayers, this.maxPlayers, this.versionName);
}

class CreateRequest {
  final String name;
  final String loader;
  final String gameVersion;
  final int minRamMb;
  final int maxRamMb;
  final Map<String, String> properties;

  const CreateRequest({
    required this.name,
    required this.loader,
    required this.gameVersion,
    this.minRamMb = 1024,
    this.maxRamMb = 4096,
    this.properties = const {},
  });
}

enum EventKind { status, log, download, created, backup, install, java, error }

class BackendEvent {
  final EventKind kind;
  final String? id;
  final String? status;
  final String? line;
  final int? received;
  final int? total;
  final String? name;
  final String? message;
  final int? feature;
  final String? stage;

  const BackendEvent(
    this.kind, {
    this.id,
    this.status,
    this.line,
    this.received,
    this.total,
    this.name,
    this.message,
    this.feature,
    this.stage,
  });
}

/// Everything the UI needs from the backend. Implemented by the embedded
/// Rust backend (desktop/mobile) — and in the future by an HTTP client
/// talking to `mcse-backend` for a web UI.
abstract class Backend {
  Stream<BackendEvent> get events;

  Future<List<LoaderInfo>> loaders();
  Future<List<GameVersionInfo>> gameVersions(String loader);

  /// Kicks off creation in the background, returns the new instance id.
  Future<String> createInstance(CreateRequest request);
  Future<List<ServerInstance>> instances();
  Future<void> deleteInstance(String id, {bool removeFiles = true});
  Future<void> start(String id);
  Future<void> stop(String id);
  Future<void> restart(String id);
  Future<void> kill(String id);
  Future<void> sendCommand(String id, String command);
  Future<List<String>> recentLog(String id);
  Future<ServerPing> ping(String id);
  Future<void> updateInstance(
    String id, {
    String? name,
    int? minRamMb,
    int? maxRamMb,
    List<String>? jvmArgs,
    String? javaPath,
  });

  Future<Map<String, String>> properties(String id);
  Future<void> setProperties(String id, Map<String, String> changes);
  Future<Map<String, String>> defaultProperties();

  Future<List<BackupInfo>> backups(String id);
  Future<BackupInfo> createBackup(String id);
  Future<void> deleteBackup(String id, String name);
  Future<void> restoreBackup(String id, String name);

  Future<List<JavaRuntimeInfo>> javaRuntimes();
  Future<List<JavaReleaseInfo>> javaReleases();
  Future<JavaRuntimeInfo> installJava(int feature);
  Future<void> removeJava(int feature);
  Future<int> requiredJava(String gameVersion);

  Future<String> dataDir();
}
