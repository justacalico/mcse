import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/state/theme_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads persisted mode', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    expect((await ThemeState.load()).mode, ThemeMode.light);
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    expect((await ThemeState.load()).mode, ThemeMode.dark);
    SharedPreferences.setMockInitialValues({'theme_mode': 'system'});
    expect((await ThemeState.load()).mode, ThemeMode.system);
    SharedPreferences.setMockInitialValues({});
    expect((await ThemeState.load()).mode, ThemeMode.system);
  });

  test('setMode notifies and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final state = ThemeState();
    var notified = 0;
    state.addListener(() => notified++);
    await state.setMode(ThemeMode.dark);
    expect(state.mode, ThemeMode.dark);
    expect(notified, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
    await state.setMode(ThemeMode.light);
    expect(prefs.getString('theme_mode'), 'light');
    await state.setMode(ThemeMode.system);
    expect(prefs.getString('theme_mode'), 'system');
  });
}
