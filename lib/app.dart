import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'backend/backend.dart';
import 'pages/home_page.dart';
import 'services/version_checker.dart';
import 'state/app_state.dart';
import 'state/theme_state.dart';
import 'state/update_state.dart';
import 'theme.dart';

Widget buildApp({
  required Backend backend,
  required ThemeState themeState,
  required UpdateState updateState,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: themeState),
      ChangeNotifierProvider.value(value: updateState),
      ChangeNotifierProvider(create: (_) => AppState(backend)..refresh()),
    ],
    child: const McseApp(),
  );
}

UpdateState defaultUpdateState(Future<String> Function() version) =>
    UpdateState(checker: VersionChecker(), currentVersion: version);

class McseApp extends StatelessWidget {
  const McseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    return MaterialApp(
      title: 'mcse',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: theme.mode,
      home: const HomePage(),
    );
  }
}
