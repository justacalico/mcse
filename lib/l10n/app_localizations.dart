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

  /// No description provided for @navServers.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get navServers;

  /// No description provided for @navCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get navCreate;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get navAbout;

  /// No description provided for @noServersYet.
  ///
  /// In en, this message translates to:
  /// **'No servers yet'**
  String get noServersYet;

  /// No description provided for @noServersHint.
  ///
  /// In en, this message translates to:
  /// **'Create one from the Create tab.'**
  String get noServersHint;

  /// No description provided for @creatingServer.
  ///
  /// In en, this message translates to:
  /// **'Creating server…'**
  String get creatingServer;

  /// No description provided for @createFailed.
  ///
  /// In en, this message translates to:
  /// **'Server creation failed'**
  String get createFailed;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @downloadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading {received} / {total} MB'**
  String downloadingProgress(Object received, Object total);

  /// No description provided for @downloadingSimple.
  ///
  /// In en, this message translates to:
  /// **'Downloading {received} MB'**
  String downloadingSimple(Object received);

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get unknownError;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

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

  /// No description provided for @dataDir.
  ///
  /// In en, this message translates to:
  /// **'Data directory'**
  String get dataDir;

  /// No description provided for @javaTitle.
  ///
  /// In en, this message translates to:
  /// **'Java'**
  String get javaTitle;

  /// No description provided for @javaRuntimes.
  ///
  /// In en, this message translates to:
  /// **'Java runtimes'**
  String get javaRuntimes;

  /// No description provided for @runtimesDetected.
  ///
  /// In en, this message translates to:
  /// **'{count} detected'**
  String runtimesDetected(Object count);

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

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Minecraft Java Edition server manager'**
  String get aboutTagline;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @checkFailed.
  ///
  /// In en, this message translates to:
  /// **'Check failed'**
  String get checkFailed;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available: {version}'**
  String updateAvailable(Object version);

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get upToDate;

  /// No description provided for @checkReleasesHint.
  ///
  /// In en, this message translates to:
  /// **'Check GitLab releases for a new version'**
  String get checkReleasesHint;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @createServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create server'**
  String get createServerTitle;

  /// No description provided for @loader.
  ///
  /// In en, this message translates to:
  /// **'Loader'**
  String get loader;

  /// No description provided for @loadersFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load loaders: {error}'**
  String loadersFailed(Object error);

  /// No description provided for @selectLoader.
  ///
  /// In en, this message translates to:
  /// **'Select a loader'**
  String get selectLoader;

  /// No description provided for @selectGameVersion.
  ///
  /// In en, this message translates to:
  /// **'Select a game version'**
  String get selectGameVersion;

  /// No description provided for @serverName.
  ///
  /// In en, this message translates to:
  /// **'Server name'**
  String get serverName;

  /// No description provided for @serverNameTaken.
  ///
  /// In en, this message translates to:
  /// **'A server with that name already exists'**
  String get serverNameTaken;

  /// No description provided for @memoryMb.
  ///
  /// In en, this message translates to:
  /// **'Memory: {amount} MB'**
  String memoryMb(Object amount);

  /// No description provided for @motd.
  ///
  /// In en, this message translates to:
  /// **'MOTD'**
  String get motd;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @acceptEula.
  ///
  /// In en, this message translates to:
  /// **'I accept the Minecraft EULA'**
  String get acceptEula;

  /// No description provided for @eulaRequired.
  ///
  /// In en, this message translates to:
  /// **'Required to run a server — see '**
  String get eulaRequired;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get creating;

  /// No description provided for @defaultMotd.
  ///
  /// In en, this message translates to:
  /// **'A Minecraft Server'**
  String get defaultMotd;

  /// No description provided for @defaultServerName.
  ///
  /// In en, this message translates to:
  /// **'Minecraft Server'**
  String get defaultServerName;

  /// No description provided for @serverNotFound.
  ///
  /// In en, this message translates to:
  /// **'Server not found'**
  String get serverNotFound;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @kill.
  ///
  /// In en, this message translates to:
  /// **'Kill'**
  String get kill;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @deleteServerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete server'**
  String get deleteServerTooltip;

  /// No description provided for @tabConsole.
  ///
  /// In en, this message translates to:
  /// **'Console'**
  String get tabConsole;

  /// No description provided for @tabProperties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get tabProperties;

  /// No description provided for @tabBackups.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get tabBackups;

  /// No description provided for @deleteServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete server?'**
  String get deleteServerTitle;

  /// No description provided for @deleteServerBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes \"{name}\" and all its files permanently.'**
  String deleteServerBody(Object name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noConsoleOutput.
  ///
  /// In en, this message translates to:
  /// **'No console output yet.'**
  String get noConsoleOutput;

  /// No description provided for @commandHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a server command…'**
  String get commandHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @propertiesSaved.
  ///
  /// In en, this message translates to:
  /// **'Properties saved'**
  String get propertiesSaved;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(Object error);

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @propsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load properties: {error}'**
  String propsLoadFailed(Object error);

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(Object error);

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore backup?'**
  String get restoreTitle;

  /// No description provided for @restoreBody.
  ///
  /// In en, this message translates to:
  /// **'This stops the server and overwrites world data with {name}.'**
  String restoreBody(Object name);

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @backupsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load backups: {error}'**
  String backupsLoadFailed(Object error);

  /// No description provided for @working.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get working;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get createBackup;

  /// No description provided for @noBackups.
  ///
  /// In en, this message translates to:
  /// **'No backups yet.'**
  String get noBackups;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @minRam.
  ///
  /// In en, this message translates to:
  /// **'Min RAM (MB)'**
  String get minRam;

  /// No description provided for @maxRam.
  ///
  /// In en, this message translates to:
  /// **'Max RAM (MB)'**
  String get maxRam;

  /// No description provided for @jvmArgs.
  ///
  /// In en, this message translates to:
  /// **'Extra JVM args'**
  String get jvmArgs;

  /// No description provided for @javaRuntime.
  ///
  /// In en, this message translates to:
  /// **'Java runtime'**
  String get javaRuntime;

  /// No description provided for @javaAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto (best match)'**
  String get javaAuto;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @sizeMb.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String sizeMb(Object size);

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @releasesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load releases'**
  String get releasesLoadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @detectedRuntimes.
  ///
  /// In en, this message translates to:
  /// **'Detected runtimes'**
  String get detectedRuntimes;

  /// No description provided for @noRuntimes.
  ///
  /// In en, this message translates to:
  /// **'No Java runtimes found.'**
  String get noRuntimes;

  /// No description provided for @javaInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Java install failed: {error}'**
  String javaInstallFailed(Object error);

  /// No description provided for @javaRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Java remove failed: {error}'**
  String javaRemoveFailed(Object error);

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @extracting.
  ///
  /// In en, this message translates to:
  /// **'Extracting…'**
  String get extracting;

  /// No description provided for @javaProgressTotal.
  ///
  /// In en, this message translates to:
  /// **'{received} / {total} MB'**
  String javaProgressTotal(Object received, Object total);

  /// No description provided for @javaProgressMb.
  ///
  /// In en, this message translates to:
  /// **'{received} MB'**
  String javaProgressMb(Object received);

  /// No description provided for @javaRuntimeVersion.
  ///
  /// In en, this message translates to:
  /// **'Java {major} — {version}'**
  String javaRuntimeVersion(Object major, Object version);

  /// No description provided for @javaFeature.
  ///
  /// In en, this message translates to:
  /// **'Java {feature}'**
  String javaFeature(Object feature);

  /// No description provided for @javaRuntimePath.
  ///
  /// In en, this message translates to:
  /// **'Java {major} — {path}'**
  String javaRuntimePath(Object major, Object path);

  /// No description provided for @statusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get statusRunning;

  /// No description provided for @statusStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get statusStarting;

  /// No description provided for @statusStopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping'**
  String get statusStopping;

  /// No description provided for @statusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get statusStopped;

  /// No description provided for @statusCrashed.
  ///
  /// In en, this message translates to:
  /// **'Crashed'**
  String get statusCrashed;
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
