import 'dart:async';

import 'package:flutter/foundation.dart';

import '../backend/backend.dart';

const _logCap = 2000;

/// Download progress for an in-flight instance creation.
class CreateProgress {
  final int received;
  final int? total;
  final List<String> installLines;
  final bool failed;
  final String? error;

  const CreateProgress({
    this.received = 0,
    this.total,
    this.installLines = const [],
    this.failed = false,
    this.error,
  });

  double? get fraction =>
      total != null && total! > 0 ? received / total! : null;
}

class AppState extends ChangeNotifier {
  final Backend backend;
  late final StreamSubscription<BackendEvent> _sub;

  List<ServerInstance> instances = [];
  final Map<String, List<String>> logs = {};
  final Map<String, CreateProgress> creating = {};
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
    instances = await backend.instances();
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
        creating[e.id!] = CreateProgress(
          received: e.received ?? 0,
          total: e.total,
          installLines: creating[e.id!]?.installLines ?? const [],
        );
        notifyListeners();
      case EventKind.install:
        if (e.id == null || e.line == null) return;
        final prev = creating[e.id!];
        creating[e.id!] = CreateProgress(
          received: prev?.received ?? 0,
          total: prev?.total,
          installLines: [...?prev?.installLines, e.line!],
        );
        notifyListeners();
      case EventKind.created:
        if (e.id != null) creating.remove(e.id!);
        refresh();
      case EventKind.backup:
        notifyListeners();
      case EventKind.error:
        if (e.id != null) {
          creating[e.id!] = CreateProgress(
            failed: true,
            error: e.message ?? 'unknown error',
          );
        }
        lastError = e.message;
        notifyListeners();
    }
  }

  List<String> logOf(String id) => logs[id] ?? const [];

  Future<void> loadRecentLog(String id) async {
    logs[id] = await backend.recentLog(id);
    notifyListeners();
  }

  void dismissCreate(String id) {
    creating.remove(id);
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
