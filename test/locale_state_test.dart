import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/l10n/app_localizations.dart';
import 'package:mcse/state/locale_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';
import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to system locale', () async {
    SharedPreferences.setMockInitialValues({});
    expect(LocaleState().locale, isNull);
    expect((await LocaleState.load()).locale, isNull);
  });

  test('load reads persisted locale', () async {
    SharedPreferences.setMockInitialValues({'locale': 'zh'});
    expect((await LocaleState.load()).locale, const Locale('zh'));
  });

  test('setLocale persists and notifies', () async {
    SharedPreferences.setMockInitialValues({});
    final state = LocaleState();
    var notified = 0;
    state.addListener(() => notified++);
    await state.setLocale(const Locale('ru'));
    expect(state.locale, const Locale('ru'));
    expect(notified, 1);
    expect(
        (await SharedPreferences.getInstance()).getString('locale'), 'ru');
  });

  test('setLocale null clears the preference', () async {
    SharedPreferences.setMockInitialValues({'locale': 'ga'});
    final state = LocaleState(const Locale('ga'));
    await state.setLocale(null);
    expect(state.locale, isNull);
    expect(
        (await SharedPreferences.getInstance()).getString('locale'), isNull);
  });

  test('decode maps tags to supported locales', () {
    expect(LocaleState.decode('en-GB'), const Locale('en', 'GB'));
    expect(LocaleState.decode('zh'), const Locale('zh'));
    expect(LocaleState.decode('ru'), const Locale('ru'));
    expect(LocaleState.decode('ga'), const Locale('ga'));
    expect(LocaleState.decode('fr'), isNull);
    expect(LocaleState.decode(null), isNull);
  });

  test('en and en-GB arb files stay in sync', () {
    final en = File('lib/l10n/app_en.arb').readAsStringSync();
    final enGb = File('lib/l10n/app_en_GB.arb').readAsStringSync();
    expect(en.replaceAll('"@@locale": "en"', ''),
        enGb.replaceAll('"@@locale": "en_GB"', ''));
  });

  test('unsupported locale lookup throws', () {
    expect(() => lookupAppLocalizations(const Locale('fr')),
        throwsA(isA<FlutterError>()));
  });

  testWidgets('every supported locale provides translations',
      (tester) async {
    for (final locale in AppLocalizations.supportedLocales) {
      final backend = FakeBackend();
      await tester.pumpWidget(
          testApp(backend, localeState: LocaleState(locale)));
      await tester.pumpAndSettle();
      final element = tester.element(find.byType(Scaffold).first);
      final l10n = AppLocalizations.of(element);
      final strings = [
        l10n.navServers,
        l10n.navCreate,
        l10n.navSettings,
        l10n.navAbout,
        l10n.noServersYet,
        l10n.noServersHint,
        l10n.creatingServer,
        l10n.createFailed,
        l10n.dismiss,
        l10n.downloadingProgress('1', '2'),
        l10n.downloadingSimple('1'),
        l10n.unknownError,
        l10n.appearance,
        l10n.themeSystem,
        l10n.themeLight,
        l10n.themeDark,
        l10n.themeOled,
        l10n.dataDir,
        l10n.storageTitle,
        l10n.javaDir,
        l10n.backupsDir,
        l10n.dirDialogHint,
        l10n.browseDir,
        l10n.useDefaultDir,
        l10n.dirPendingRestart,
        l10n.javaTitle,
        l10n.javaRuntimes,
        l10n.runtimesDetected('2'),
        l10n.language,
        l10n.languageSystem,
        l10n.aboutTagline,
        l10n.version,
        l10n.checkForUpdates,
        l10n.checkFailed,
        l10n.updateAvailable('1.2.3'),
        l10n.upToDate,
        l10n.checkReleasesHint,
        l10n.sourceCode,
        l10n.createServerTitle,
        l10n.loader,
        l10n.loadersFailed('x'),
        l10n.selectLoader,
        l10n.selectGameVersion,
        l10n.serverName,
        l10n.serverNameTaken,
        l10n.memoryMb('1024'),
        l10n.motd,
        l10n.port,
        l10n.acceptEula,
        l10n.eulaRequired,
        l10n.creating,
        l10n.defaultMotd,
        l10n.defaultServerName,
        l10n.serverNotFound,
        l10n.start,
        l10n.stop,
        l10n.kill,
        l10n.restart,
        l10n.deleteServerTooltip,
        l10n.tabConsole,
        l10n.tabProperties,
        l10n.tabBackups,
        l10n.deleteServerTitle,
        l10n.deleteServerBody('s'),
        l10n.cancel,
        l10n.delete,
        l10n.noConsoleOutput,
        l10n.commandHint,
        l10n.send,
        l10n.propertiesSaved,
        l10n.saveFailed('x'),
        l10n.saving,
        l10n.save,
        l10n.propsLoadFailed('x'),
        l10n.backupFailed('x'),
        l10n.restoreTitle,
        l10n.restoreBody('b'),
        l10n.restore,
        l10n.backupsLoadFailed('x'),
        l10n.working,
        l10n.createBackup,
        l10n.noBackups,
        l10n.nameLabel,
        l10n.minRam,
        l10n.maxRam,
        l10n.jvmArgs,
        l10n.javaRuntime,
        l10n.javaAuto,
        l10n.settingsSaved,
        l10n.sizeMb('1.0'),
        l10n.downloads,
        l10n.releasesLoadFailed,
        l10n.retry,
        l10n.detectedRuntimes,
        l10n.noRuntimes,
        l10n.javaInstallFailed('x'),
        l10n.javaRemoveFailed('x'),
        l10n.installed,
        l10n.install,
        l10n.remove,
        l10n.extracting,
        l10n.javaProgressTotal('1', '2'),
        l10n.javaProgressMb('1'),
        l10n.javaRuntimeVersion('21', '21.0.3'),
        l10n.javaFeature('21'),
        l10n.javaRuntimePath('21', '/bin/java'),
        l10n.statusRunning,
        l10n.statusStarting,
        l10n.statusStopping,
        l10n.statusStopped,
        l10n.statusCrashed,
      ];
      for (final s in strings) {
        expect(s, isNotEmpty, reason: '$locale');
      }
    }
  });

  testWidgets('language picker switches the app locale', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final backend = FakeBackend();
    final localeState = LocaleState();
    await tester
        .pumpWidget(testApp(backend, localeState: localeState));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('简体中文').last);
    await tester.pumpAndSettle();

    expect(localeState.locale, const Locale('zh'));
    expect(find.text('设置'), findsWidgets);
    expect(find.text('外观'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский').last);
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsWidgets);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gaeilge').last);
    await tester.pumpAndSettle();
    expect(find.text('Socruithe'), findsWidgets);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Traditional English').last);
    await tester.pumpAndSettle();
    expect(localeState.locale, const Locale('en', 'GB'));
    expect(find.text('Appearance'), findsOneWidget);
  });
}
