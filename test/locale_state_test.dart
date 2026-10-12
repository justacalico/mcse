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

  testWidgets('every supported locale provides translations',
      (tester) async {
    for (final locale in AppLocalizations.supportedLocales) {
      final backend = FakeBackend();
      await tester.pumpWidget(
          testApp(backend, localeState: LocaleState(locale)));
      await tester.pumpAndSettle();
      final element = tester.element(find.byType(Scaffold).first);
      final l10n = AppLocalizations.of(element);
      expect(l10n.navServers, isNotEmpty);
      expect(l10n.createServerTitle, isNotEmpty);
      expect(l10n.statusRunning, isNotEmpty);
      expect(l10n.storageTitle, isNotEmpty);
      expect(l10n.javaDir, isNotEmpty);
      expect(l10n.backupsDir, isNotEmpty);
      expect(l10n.dirDialogHint, isNotEmpty);
      expect(l10n.browseDir, isNotEmpty);
      expect(l10n.useDefaultDir, isNotEmpty);
      expect(l10n.dirPendingRestart, isNotEmpty);
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
