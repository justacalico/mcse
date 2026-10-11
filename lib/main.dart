import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'backend/frb_backend.dart';
import 'state/theme_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final backend = await createBackend();
  final theme = await ThemeState.load();
  runApp(buildApp(
    backend: backend,
    themeState: theme,
    updateState: defaultUpdateState(_packageVersion),
  ));
}

Future<String> _packageVersion() async =>
    (await PackageInfo.fromPlatform()).version;
