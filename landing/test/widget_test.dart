import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mcse_landing/l10n/app_localizations.dart';
import 'package:mcse_landing/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester,
      {ThemeController? theme, LocaleController? locale}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await http.runWithClient(
      () async {
        await tester.pumpWidget(LandingApp(
          controller: theme ?? ThemeController(),
          localeController: locale ?? LocaleController(),
        ));
        await tester.pumpAndSettle();
      },
      () => MockClient((_) async => http.Response('[]', 200)),
    );
  }

  test('LocaleController decode maps tags', () {
    expect(LocaleController.decode('en-GB'), const Locale('en', 'GB'));
    expect(LocaleController.decode('zh'), const Locale('zh'));
    expect(LocaleController.decode('ru'), const Locale('ru'));
    expect(LocaleController.decode('ga'), const Locale('ga'));
    expect(LocaleController.decode('fr'), isNull);
    expect(LocaleController.decode(null), isNull);
  });

  test('LocaleController load reads the saved tag', () async {
    SharedPreferences.setMockInitialValues({'landing_locale': 'ru'});
    expect((await LocaleController.load()).locale, const Locale('ru'));
  });

  test('LocaleController set persists and clears', () async {
    final c = LocaleController();
    await c.set(const Locale('ga'));
    expect(
        (await SharedPreferences.getInstance())
            .getString('landing_locale'),
        'ga');
    await c.set(null);
    expect(
        (await SharedPreferences.getInstance())
            .getString('landing_locale'),
        isNull);
  });

  test('en and en-GB arb files stay in sync', () {
    final en = File('lib/l10n/app_en.arb').readAsStringSync();
    final enGb = File('lib/l10n/app_en_GB.arb').readAsStringSync();
    expect(en.replaceAll('"@@locale": "en"', ''),
        enGb.replaceAll('"@@locale": "en_GB"', ''));
  });

  test('supported locales match the shipped arb files', () {
    expect(AppLocalizations.supportedLocales, [
      const Locale('en'),
      const Locale('en', 'GB'),
      const Locale('ga'),
      const Locale('ru'),
      const Locale('zh'),
    ]);
  });

  testWidgets('renders each locale', (tester) async {
    final locale = LocaleController();
    await pump(tester, locale: locale);
    final expected = {
      const Locale('en', 'GB'): 'Everything you need to run a server',
      const Locale('zh'): '运行服务器所需的一切',
      const Locale('ru'): 'Всё необходимое для запуска сервера',
      const Locale('ga'): 'Gach rud a theastaíonn chun freastalaí a rith',
    };
    for (final entry in expected.entries) {
      await locale.set(entry.key);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('language menu switches locale and persists', (tester) async {
    final locale = LocaleController();
    await pump(tester, locale: locale);
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    expect(find.text('Traditional English'), findsOneWidget);
    expect(find.text('简体中文'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('Gaeilge'), findsOneWidget);
    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();
    expect(locale.locale, const Locale('zh'));
    expect(find.text('桌面端 Minecraft Java 版服务器管理器。支持 Vanilla、Paper、Purpur、Fabric、Forge 与 NeoForge —— 一个二进制文件，内置 Rust 后端。'),
        findsOneWidget);
    expect(
        (await SharedPreferences.getInstance())
            .getString('landing_locale'),
        'zh');
  });
}
