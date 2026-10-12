import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

const _prefKey = 'locale';

class LocaleState extends ChangeNotifier {
  Locale? locale;

  LocaleState([this.locale]);

  static Future<LocaleState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LocaleState(decode(prefs.getString(_prefKey)));
  }

  static Locale? decode(String? raw) {
    if (raw == null) return null;
    for (final l in AppLocalizations.supportedLocales) {
      if (l.toLanguageTag() == raw) return l;
    }
    return null;
  }

  Future<void> setLocale(Locale? locale) async {
    this.locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, locale.toLanguageTag());
    }
  }
}
