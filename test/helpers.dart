import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/app.dart';
import 'package:mcse/l10n/app_localizations.dart';
import 'package:mcse/models/app_update.dart';
import 'package:mcse/services/version_checker.dart';
import 'package:mcse/state/locale_state.dart';
import 'package:mcse/state/theme_state.dart';
import 'package:mcse/state/update_state.dart';

import 'fake_backend.dart';

class StubVersionChecker extends VersionChecker {
  StubVersionChecker(this.result, {this.fail = false});
  final AppUpdate result;
  final bool fail;

  @override
  Future<AppUpdate> check(String currentVersion) async {
    if (fail) throw const VersionCheckException('nope');
    return result;
  }
}

UpdateState stubUpdateState({AppUpdate? result, bool fail = false}) =>
    UpdateState(
      checker:
          StubVersionChecker(result ?? const AppUpdate(), fail: fail),
      currentVersion: () async => '1.0.0',
    );

Widget testApp(FakeBackend backend,
        {UpdateState? updateState, LocaleState? localeState}) =>
    buildApp(
      backend: backend,
      themeState: ThemeState(),
      localeState: localeState ?? LocaleState(),
      updateState: updateState ?? stubUpdateState(),
    );

Widget localized(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

/// Loads the app's real fonts plus MaterialIcons so golden tests render
/// real glyphs instead of Ahem blocks.
Future<void> loadTestFonts() async {
  for (final entry in {
    'Inter': 'assets/fonts/Inter.ttf',
    'JetBrainsMono': 'assets/fonts/JetBrainsMono.ttf',
  }.entries) {
    final loader = FontLoader(entry.key)
      ..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  final icons = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(
        ByteData.sublistView(await icons.readAsBytes())));
  await loader.load();
}

/// Makes url_launcher calls succeed in tests.
void mockUrlLauncher() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/url_launcher'),
    (call) async => true,
  );
}
