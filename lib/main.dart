import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'backend/frb_backend.dart';
import 'state/locale_state.dart';
import 'state/theme_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      minimumSize: Size(860, 560),
      title: 'mcse',
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  final backend = await createBackend();
  final theme = await ThemeState.load();
  final locale = await LocaleState.load();
  runApp(buildApp(
    backend: backend,
    themeState: theme,
    localeState: locale,
    updateState: defaultUpdateState(_packageVersion),
  ));
}

Future<String> _packageVersion() async =>
    (await PackageInfo.fromPlatform()).version;
