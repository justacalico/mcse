import 'dart:async';

import 'package:flutter/foundation.dart';

import '../backend/backend.dart';

const _logCap = 2000;
const _installCap = 200;

/// Download progress for an in-flight instance creation.
class CreateProgress {
  final String? name;
  final int received;
  final int? total;
  final List<String> installLines;
  final bool failed;
  final String? error;

  const CreateProgress({
    this.name,
    this.received = 0,
    this.total,
    this.installLines = const [],
    this.failed = false,
    this.error,
  });

  double? get fraction =>
      total != null && total! > 0 ? received / total! : null;
}

/// Progress of an in-flight java runtime download, keyed by feature version.
class JavaProgress {
  final String stage;
  final int received;
  final int? total;

  const JavaProgress({this.stage = 'download', this.received = 0, this.total});

  double? get fraction =>
      total != null && total! > 0 ? received / total! : null;
}

class AppState extends ChangeNotifier {
  final Backend backend;
  late final StreamSubscription<BackendEvent> _sub;

  List<ServerInstance> instances = [];
  final Map<String, List<String>> logs = {};
  final Map<String, CreateProgress> creating = {};
  final Map<int, JavaProgress> javaDownloads = {};
  String? lastError;

  AppState(this.backend) {
    _sub = backend.events.listen(_onEvent);
  }

  ServerInstance? instanceById(String id) {
    for (final i in instances) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<void> refresh() async {
    try {
      instances = await backend.instances();
    } catch (e) {
      lastError = e.toString();
    }
    for (final id in creating.keys.toList()) {
      // Instances that finished while events were being processed.
      if (instances.any((i) => i.id == id)) creating.remove(id);
    }
    notifyListeners();
  }

  void _onEvent(BackendEvent e) {
    switch (e.kind) {
      case EventKind.status:
        final idx = instances.indexWhere((i) => i.id == e.id);
        if (idx >= 0 && e.status != null) {
          instances[idx] =
              instances[idx].copyWith(status: parseStatus(e.status!));
          notifyListeners();
        }
      case EventKind.log:
        if (e.id == null || e.line == null) return;
        final log = logs.putIfAbsent(e.id!, () => []);
        log.add(e.line!);
        if (log.length > _logCap) log.removeRange(0, log.length - _logCap);
        notifyListeners();
      case EventKind.download:
        if (e.id == null) return;
        final prev = creating[e.id!];
        if (prev != null && prev.failed) return;
        creating[e.id!] = CreateProgress(
          name: prev?.name,
          received: e.received ?? 0,
          total: e.total,
          installLines: prev?.installLines ?? const [],
        );
        notifyListeners();
      case EventKind.install:
        if (e.id == null || e.line == null) return;
        final prev = creating[e.id!];
        final lines = [...?prev?.installLines, e.line!];
        creating[e.id!] = CreateProgress(
          name: prev?.name,
          received: prev?.received ?? 0,
          total: prev?.total,
          installLines: lines.length > _installCap
              ? lines.sublist(lines.length - _installCap)
              : lines,
        );
        notifyListeners();
      case EventKind.created:
        if (e.id != null) creating.remove(e.id!);
        refresh();
      case EventKind.backup:
        notifyListeners();
      case EventKind.java:
        final feature = e.feature;
        if (feature == null) return;
        if (e.stage == 'installed') {
          javaDownloads.remove(feature);
        } else {
          javaDownloads[feature] = JavaProgress(
            stage: e.stage ?? 'download',
            received: e.received ?? 0,
            total: e.total,
          );
        }
        notifyListeners();
      case EventKind.error:
        if (e.id != null && creating.containsKey(e.id)) {
          creating[e.id!] = CreateProgress(
              name: creating[e.id!]?.name,
              failed: true,
              error: e.message);
        }
        lastError = e.message;
        notifyListeners();
    }
  }

  List<String> logOf(String id) => logs[id] ?? const [];

  Future<void> loadRecentLog(String id) async {
    try {
      final fetched = await backend.recentLog(id);
      final existing = logs[id] ?? const <String>[];
      if (existing.isEmpty) {
        logs[id] = List.of(fetched);
      } else {
        // Keep lines that streamed in while the snapshot was in flight:
        // they follow the last fetched line in the existing list.
        final anchor = fetched.isEmpty ? -1 : existing.lastIndexOf(fetched.last);
        logs[id] = [...fetched, ...existing.sublist(anchor < 0 ? 0 : anchor + 1)];
      }
    } catch (e) {
      lastError = e.toString();
    }
    notifyListeners();
  }

  /// True when a live or in-flight instance already uses this name.
  bool nameTaken(String name) {
    final normalized = name.trim().toLowerCase();
    return instances
            .any((i) => i.name.trim().toLowerCase() == normalized) ||
        creating.values
            .any((p) => p.name?.trim().toLowerCase() == normalized);
  }

  /// Kicks off creation and seeds a progress entry so the UI has something
  /// to show before the first download event arrives. Returns the new id.
  Future<String> createInstance(CreateRequest request) async {
    final id = await backend.createInstance(request);
    creating[id] = CreateProgress(name: request.name);
    notifyListeners();
    return id;
  }

  void dismissCreate(String id) {
    creating.remove(id);
    notifyListeners();
  }

  /// Clear a java download entry when the install call settles — covers
  /// failures, which never produce an 'installed' event.
  void finishJavaDownload(int feature) {
    javaDownloads.remove(feature);
    notifyListeners();
  }

  Future<void> start(String id) => _run(() => backend.start(id));
  Future<void> stop(String id) => _run(() => backend.stop(id));
  Future<void> restart(String id) => _run(() => backend.restart(id));
  Future<void> kill(String id) => _run(() => backend.kill(id));

  Future<void> sendCommand(String id, String command) =>
      _run(() => backend.sendCommand(id, command));

  Future<void> delete(String id) async {
    await _run(() => backend.deleteInstance(id));
    logs.remove(id);
    await refresh();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      lastError = null;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
