// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navServers => 'Servers';

  @override
  String get navCreate => 'Create';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAbout => 'About';

  @override
  String get noServersYet => 'No servers yet';

  @override
  String get noServersHint => 'Create one from the Create tab.';

  @override
  String get creatingServer => 'Creating server…';

  @override
  String get createFailed => 'Server creation failed';

  @override
  String get dismiss => 'Dismiss';

  @override
  String downloadingProgress(Object received, Object total) {
    return 'Downloading $received / $total MB';
  }

  @override
  String downloadingSimple(Object received) {
    return 'Downloading $received MB';
  }

  @override
  String get unknownError => 'unknown error';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeOled => 'OLED';

  @override
  String get dataDir => 'Data directory';

  @override
  String get javaTitle => 'Java';

  @override
  String get javaRuntimes => 'Java runtimes';

  @override
  String runtimesDetected(Object count) {
    return '$count detected';
  }

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get aboutTagline => 'Minecraft Java Edition server manager';

  @override
  String get version => 'Version';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkFailed => 'Check failed';

  @override
  String updateAvailable(Object version) {
    return 'Update available: $version';
  }

  @override
  String get upToDate => 'Up to date';

  @override
  String get checkReleasesHint => 'Check GitLab releases for a new version';

  @override
  String get sourceCode => 'Source code';

  @override
  String get createServerTitle => 'Create server';

  @override
  String get loader => 'Loader';

  @override
  String loadersFailed(Object error) {
    return 'Failed to load loaders: $error';
  }

  @override
  String get selectLoader => 'Select a loader';

  @override
  String get selectGameVersion => 'Select a game version';

  @override
  String get serverName => 'Server name';

  @override
  String memoryMb(Object amount) {
    return 'Memory: $amount MB';
  }

  @override
  String get motd => 'MOTD';

  @override
  String get port => 'Port';

  @override
  String get acceptEula => 'I accept the Minecraft EULA';

  @override
  String get eulaRequired => 'Required to run a server — see ';

  @override
  String get creating => 'Creating…';

  @override
  String get defaultMotd => 'A Minecraft Server';

  @override
  String get defaultServerName => 'Minecraft Server';

  @override
  String get serverNotFound => 'Server not found';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get kill => 'Kill';

  @override
  String get restart => 'Restart';

  @override
  String get deleteServerTooltip => 'Delete server';

  @override
  String get tabConsole => 'Console';

  @override
  String get tabProperties => 'Properties';

  @override
  String get tabBackups => 'Backups';

  @override
  String get deleteServerTitle => 'Delete server?';

  @override
  String deleteServerBody(Object name) {
    return 'This deletes \"$name\" and all its files permanently.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get noConsoleOutput => 'No console output yet.';

  @override
  String get commandHint => 'Enter a server command…';

  @override
  String get send => 'Send';

  @override
  String get propertiesSaved => 'Properties saved';

  @override
  String saveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get saving => 'Saving…';

  @override
  String get save => 'Save';

  @override
  String propsLoadFailed(Object error) {
    return 'Failed to load properties: $error';
  }

  @override
  String backupFailed(Object error) {
    return 'Backup failed: $error';
  }

  @override
  String get restoreTitle => 'Restore backup?';

  @override
  String restoreBody(Object name) {
    return 'This stops the server and overwrites world data with $name.';
  }

  @override
  String get restore => 'Restore';

  @override
  String backupsLoadFailed(Object error) {
    return 'Failed to load backups: $error';
  }

  @override
  String get working => 'Working…';

  @override
  String get createBackup => 'Create backup';

  @override
  String get noBackups => 'No backups yet.';

  @override
  String get nameLabel => 'Name';

  @override
  String get minRam => 'Min RAM (MB)';

  @override
  String get maxRam => 'Max RAM (MB)';

  @override
  String get jvmArgs => 'Extra JVM args';

  @override
  String get javaRuntime => 'Java runtime';

  @override
  String get javaAuto => 'Auto (best match)';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String sizeMb(Object size) {
    return '$size MB';
  }

  @override
  String get downloads => 'Downloads';

  @override
  String get releasesLoadFailed => 'Could not load releases';

  @override
  String get retry => 'Retry';

  @override
  String get detectedRuntimes => 'Detected runtimes';

  @override
  String get noRuntimes => 'No Java runtimes found.';

  @override
  String javaInstallFailed(Object error) {
    return 'Java install failed: $error';
  }

  @override
  String javaRemoveFailed(Object error) {
    return 'Java remove failed: $error';
  }

  @override
  String get installed => 'Installed';

  @override
  String get install => 'Install';

  @override
  String get remove => 'Remove';

  @override
  String get extracting => 'Extracting…';

  @override
  String javaProgressTotal(Object received, Object total) {
    return '$received / $total MB';
  }

  @override
  String javaProgressMb(Object received) {
    return '$received MB';
  }

  @override
  String javaRuntimeVersion(Object major, Object version) {
    return 'Java $major — $version';
  }

  @override
  String javaFeature(Object feature) {
    return 'Java $feature';
  }

  @override
  String javaRuntimePath(Object major, Object path) {
    return 'Java $major — $path';
  }

  @override
  String get statusRunning => 'Running';

  @override
  String get statusStarting => 'Starting';

  @override
  String get statusStopping => 'Stopping';

  @override
  String get statusStopped => 'Stopped';

  @override
  String get statusCrashed => 'Crashed';
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class AppLocalizationsEnGb extends AppLocalizationsEn {
  AppLocalizationsEnGb() : super('en_GB');

  @override
  String get navServers => 'Servers';

  @override
  String get navCreate => 'Create';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAbout => 'About';

  @override
  String get noServersYet => 'No servers yet';

  @override
  String get noServersHint => 'Create one from the Create tab.';

  @override
  String get creatingServer => 'Creating server…';

  @override
  String get createFailed => 'Server creation failed';

  @override
  String get dismiss => 'Dismiss';

  @override
  String downloadingProgress(Object received, Object total) {
    return 'Downloading $received / $total MB';
  }

  @override
  String downloadingSimple(Object received) {
    return 'Downloading $received MB';
  }

  @override
  String get unknownError => 'unknown error';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeOled => 'OLED';

  @override
  String get dataDir => 'Data directory';

  @override
  String get javaTitle => 'Java';

  @override
  String get javaRuntimes => 'Java runtimes';

  @override
  String runtimesDetected(Object count) {
    return '$count detected';
  }

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get aboutTagline => 'Minecraft Java Edition server manager';

  @override
  String get version => 'Version';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkFailed => 'Check failed';

  @override
  String updateAvailable(Object version) {
    return 'Update available: $version';
  }

  @override
  String get upToDate => 'Up to date';

  @override
  String get checkReleasesHint => 'Check GitLab releases for a new version';

  @override
  String get sourceCode => 'Source code';

  @override
  String get createServerTitle => 'Create server';

  @override
  String get loader => 'Loader';

  @override
  String loadersFailed(Object error) {
    return 'Failed to load loaders: $error';
  }

  @override
  String get selectLoader => 'Select a loader';

  @override
  String get selectGameVersion => 'Select a game version';

  @override
  String get serverName => 'Server name';

  @override
  String memoryMb(Object amount) {
    return 'Memory: $amount MB';
  }

  @override
  String get motd => 'MOTD';

  @override
  String get port => 'Port';

  @override
  String get acceptEula => 'I accept the Minecraft EULA';

  @override
  String get eulaRequired => 'Required to run a server — see ';

  @override
  String get creating => 'Creating…';

  @override
  String get defaultMotd => 'A Minecraft Server';

  @override
  String get defaultServerName => 'Minecraft Server';

  @override
  String get serverNotFound => 'Server not found';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get kill => 'Kill';

  @override
  String get restart => 'Restart';

  @override
  String get deleteServerTooltip => 'Delete server';

  @override
  String get tabConsole => 'Console';

  @override
  String get tabProperties => 'Properties';

  @override
  String get tabBackups => 'Backups';

  @override
  String get deleteServerTitle => 'Delete server?';

  @override
  String deleteServerBody(Object name) {
    return 'This deletes \"$name\" and all its files permanently.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get noConsoleOutput => 'No console output yet.';

  @override
  String get commandHint => 'Enter a server command…';

  @override
  String get send => 'Send';

  @override
  String get propertiesSaved => 'Properties saved';

  @override
  String saveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get saving => 'Saving…';

  @override
  String get save => 'Save';

  @override
  String propsLoadFailed(Object error) {
    return 'Failed to load properties: $error';
  }

  @override
  String backupFailed(Object error) {
    return 'Backup failed: $error';
  }

  @override
  String get restoreTitle => 'Restore backup?';

  @override
  String restoreBody(Object name) {
    return 'This stops the server and overwrites world data with $name.';
  }

  @override
  String get restore => 'Restore';

  @override
  String backupsLoadFailed(Object error) {
    return 'Failed to load backups: $error';
  }

  @override
  String get working => 'Working…';

  @override
  String get createBackup => 'Create backup';

  @override
  String get noBackups => 'No backups yet.';

  @override
  String get nameLabel => 'Name';

  @override
  String get minRam => 'Min RAM (MB)';

  @override
  String get maxRam => 'Max RAM (MB)';

  @override
  String get jvmArgs => 'Extra JVM args';

  @override
  String get javaRuntime => 'Java runtime';

  @override
  String get javaAuto => 'Auto (best match)';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String sizeMb(Object size) {
    return '$size MB';
  }

  @override
  String get downloads => 'Downloads';

  @override
  String get releasesLoadFailed => 'Could not load releases';

  @override
  String get retry => 'Retry';

  @override
  String get detectedRuntimes => 'Detected runtimes';

  @override
  String get noRuntimes => 'No Java runtimes found.';

  @override
  String javaInstallFailed(Object error) {
    return 'Java install failed: $error';
  }

  @override
  String javaRemoveFailed(Object error) {
    return 'Java remove failed: $error';
  }

  @override
  String get installed => 'Installed';

  @override
  String get install => 'Install';

  @override
  String get remove => 'Remove';

  @override
  String get extracting => 'Extracting…';

  @override
  String javaProgressTotal(Object received, Object total) {
    return '$received / $total MB';
  }

  @override
  String javaProgressMb(Object received) {
    return '$received MB';
  }

  @override
  String javaRuntimeVersion(Object major, Object version) {
    return 'Java $major — $version';
  }

  @override
  String javaFeature(Object feature) {
    return 'Java $feature';
  }

  @override
  String javaRuntimePath(Object major, Object path) {
    return 'Java $major — $path';
  }

  @override
  String get statusRunning => 'Running';

  @override
  String get statusStarting => 'Starting';

  @override
  String get statusStopping => 'Stopping';

  @override
  String get statusStopped => 'Stopped';

  @override
  String get statusCrashed => 'Crashed';
}
