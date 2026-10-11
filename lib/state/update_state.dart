import 'package:flutter/foundation.dart';

import '../models/app_update.dart';
import '../services/version_checker.dart';

/// Cached "check for updates" state. Concurrent calls share one in-flight
/// check, and the last result is kept for the UI.
class UpdateState extends ChangeNotifier {
  final VersionChecker checker;
  final Future<String> Function() currentVersion;

  AppUpdate? update;
  Future<AppUpdate?>? _inFlight;

  UpdateState({required this.checker, required this.currentVersion});

  /// Runs the check and returns the result, or null on failure. Repeated
  /// calls while a check is running all wait on the same request.
  Future<AppUpdate?> check() {
    return _inFlight ??=
        _check().whenComplete(() => _inFlight = null);
  }

  Future<AppUpdate?> _check() async {
    try {
      final result = await checker.check(await currentVersion());
      if (update != result) {
        update = result;
        notifyListeners();
      }
      return result;
    } catch (_) {
      return null;
    }
  }
}
