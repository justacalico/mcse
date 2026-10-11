import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'theme_mode';

enum AppTheme { system, light, dark, oled }

class ThemeState extends ChangeNotifier {
  AppTheme mode;

  ThemeState([this.mode = AppTheme.system]);

  static Future<ThemeState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeState(_decode(prefs.getString(_prefKey)));
  }

  static AppTheme _decode(String? raw) => switch (raw) {
        'light' => AppTheme.light,
        'dark' => AppTheme.dark,
        'oled' => AppTheme.oled,
        _ => AppTheme.system,
      };

  Future<void> setMode(AppTheme mode) async {
    this.mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }
}
