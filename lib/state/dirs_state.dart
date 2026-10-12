import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dataKey = 'dir_data';
const _javaKey = 'dir_java';
const _backupsKey = 'dir_backups';

/// User-chosen storage locations, applied the next time the backend
/// starts. A null value means the default under the data dir.
class DirsState extends ChangeNotifier {
  String? dataDir;
  String? javaDir;
  String? backupsDir;

  DirsState({this.dataDir, this.javaDir, this.backupsDir});

  static Future<DirsState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return DirsState(
      dataDir: prefs.getString(_dataKey),
      javaDir: prefs.getString(_javaKey),
      backupsDir: prefs.getString(_backupsKey),
    );
  }

  static String? _clean(String? dir) {
    var s = dir?.trim() ?? '';
    while (s.length > 1 &&
        (s.endsWith('/') || s.endsWith('\\')) &&
        !(s.length == 3 && s[1] == ':')) {
      s = s.substring(0, s.length - 1);
    }
    return s.isEmpty ? null : s;
  }

  Future<void> _set(String key, String? dir, void Function(String?) apply) async {
    final value = _clean(dir);
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
    apply(value);
    notifyListeners();
  }

  Future<void> setDataDir(String? dir) =>
      _set(_dataKey, dir, (v) => dataDir = v);

  Future<void> setJavaDir(String? dir) =>
      _set(_javaKey, dir, (v) => javaDir = v);

  Future<void> setBackupsDir(String? dir) =>
      _set(_backupsKey, dir, (v) => backupsDir = v);
}
