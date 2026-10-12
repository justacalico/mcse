import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ga.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'GB'),
    Locale('ga'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'mcse — Minecraft server manager'**
  String get appTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeOled.
  ///
  /// In en, this message translates to:
  /// **'OLED'**
  String get themeOled;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @heroTagline.
  ///
  /// In en, this message translates to:
  /// **'A desktop Minecraft Java Edition server manager. Vanilla, Paper, Purpur, Fabric, Forge and NeoForge — one binary, a built-in Rust backend.'**
  String get heroTagline;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @featuresTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything you need to run a server'**
  String get featuresTitle;

  /// No description provided for @featEveryLoader.
  ///
  /// In en, this message translates to:
  /// **'Every loader'**
  String get featEveryLoader;

  /// No description provided for @featEveryLoaderBody.
  ///
  /// In en, this message translates to:
  /// **'Vanilla, Paper, Purpur, Fabric, Forge and NeoForge with automatic downloads.'**
  String get featEveryLoaderBody;

  /// No description provided for @featConsole.
  ///
  /// In en, this message translates to:
  /// **'Live console'**
  String get featConsole;

  /// No description provided for @featConsoleBody.
  ///
  /// In en, this message translates to:
  /// **'Send commands and watch the server log in real time.'**
  String get featConsoleBody;

  /// No description provided for @featBackups.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get featBackups;

  /// No description provided for @featBackupsBody.
  ///
  /// In en, this message translates to:
  /// **'Create, restore and delete world backups in one click.'**
  String get featBackupsBody;

  /// No description provided for @featJava.
  ///
  /// In en, this message translates to:
  /// **'Java runtimes'**
  String get featJava;

  /// No description provided for @featJavaBody.
  ///
  /// In en, this message translates to:
  /// **'Detects installed JDKs and installs Temurin when needed.'**
  String get featJavaBody;

  /// No description provided for @featPropsBody.
  ///
  /// In en, this message translates to:
  /// **'Edit every property from the UI — no file hunting.'**
  String get featPropsBody;

  /// No description provided for @featBinary.
  ///
  /// In en, this message translates to:
  /// **'Single binary'**
  String get featBinary;

  /// No description provided for @featBinaryBody.
  ///
  /// In en, this message translates to:
  /// **'The Rust backend is compiled into the desktop app.'**
  String get featBinaryBody;

  /// No description provided for @showcaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Inside the app'**
  String get showcaseTitle;

  /// No description provided for @shotServers.
  ///
  /// In en, this message translates to:
  /// **'Your servers at a glance'**
  String get shotServers;

  /// No description provided for @shotCreate.
  ///
  /// In en, this message translates to:
  /// **'One wizard, every loader'**
  String get shotCreate;

  /// No description provided for @shotConsole.
  ///
  /// In en, this message translates to:
  /// **'Console and controls'**
  String get shotConsole;

  /// No description provided for @shotSettings.
  ///
  /// In en, this message translates to:
  /// **'Java and theme settings'**
  String get shotSettings;

  /// No description provided for @archTitle.
  ///
  /// In en, this message translates to:
  /// **'Built to outgrow the desktop'**
  String get archTitle;

  /// No description provided for @archBody.
  ///
  /// In en, this message translates to:
  /// **'The management logic lives in a standalone Rust backend with a REST + WebSocket API. The Flutter desktop app embeds it; a web UI can talk to the same API tomorrow.'**
  String get archBody;

  /// No description provided for @archFlutter.
  ///
  /// In en, this message translates to:
  /// **'Flutter desktop'**
  String get archFlutter;

  /// No description provided for @archPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Linux · Windows · macOS'**
  String get archPlatforms;

  /// No description provided for @archRust.
  ///
  /// In en, this message translates to:
  /// **'Rust backend'**
  String get archRust;

  /// No description provided for @archApi.
  ///
  /// In en, this message translates to:
  /// **'REST + WebSocket API'**
  String get archApi;

  /// No description provided for @archWeb.
  ///
  /// In en, this message translates to:
  /// **'Web UI'**
  String get archWeb;

  /// No description provided for @archWebSub.
  ///
  /// In en, this message translates to:
  /// **'same API, any browser'**
  String get archWebSub;

  /// No description provided for @archFrb.
  ///
  /// In en, this message translates to:
  /// **'embedded (FRB)'**
  String get archFrb;

  /// No description provided for @downloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsTitle;

  /// No description provided for @allReleases.
  ///
  /// In en, this message translates to:
  /// **'All releases on GitLab'**
  String get allReleases;

  /// No description provided for @releasesError.
  ///
  /// In en, this message translates to:
  /// **'Could not load releases — grab them on GitLab.'**
  String get releasesError;

  /// No description provided for @noReleases.
  ///
  /// In en, this message translates to:
  /// **'No releases yet — the first build is on its way.'**
  String get noReleases;

  /// No description provided for @noAssets.
  ///
  /// In en, this message translates to:
  /// **'No downloadable assets'**
  String get noAssets;

  /// No description provided for @releases.
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get releases;

  /// No description provided for @githubMirror.
  ///
  /// In en, this message translates to:
  /// **'GitHub mirror'**
  String get githubMirror;

  /// No description provided for @footerLine.
  ///
  /// In en, this message translates to:
  /// **'mcse — AGPL-3.0 · not affiliated with Mojang or Microsoft'**
  String get footerLine;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ga', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return AppLocalizationsEnGb();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ga':
      return AppLocalizationsGa();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
