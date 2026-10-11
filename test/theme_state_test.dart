import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/state/theme_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads persisted mode', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    expect((await ThemeState.load()).mode, AppTheme.light);
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    expect((await ThemeState.load()).mode, AppTheme.dark);
    SharedPreferences.setMockInitialValues({'theme_mode': 'oled'});
    expect((await ThemeState.load()).mode, AppTheme.oled);
    SharedPreferences.setMockInitialValues({'theme_mode': 'system'});
    expect((await ThemeState.load()).mode, AppTheme.system);
    SharedPreferences.setMockInitialValues({});
    expect((await ThemeState.load()).mode, AppTheme.system);
  });

  test('setMode notifies and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final state = ThemeState();
    var notified = 0;
    state.addListener(() => notified++);
    await state.setMode(AppTheme.dark);
    expect(state.mode, AppTheme.dark);
    expect(notified, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
    await state.setMode(AppTheme.oled);
    expect(prefs.getString('theme_mode'), 'oled');
    await state.setMode(AppTheme.light);
    expect(prefs.getString('theme_mode'), 'light');
    await state.setMode(AppTheme.system);
    expect(prefs.getString('theme_mode'), 'system');
  });
}
