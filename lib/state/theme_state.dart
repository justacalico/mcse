import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'theme_mode';

class ThemeState extends ChangeNotifier {
  ThemeMode mode;

  ThemeState([this.mode = ThemeMode.system]);

  static Future<ThemeState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeState(_decode(prefs.getString(_prefKey)));
  }

  static ThemeMode _decode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> setMode(ThemeMode mode) async {
    this.mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKey,
        switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        });
  }
}
