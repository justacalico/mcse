// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Irish (`ga`).
class AppLocalizationsGa extends AppLocalizations {
  AppLocalizationsGa([String locale = 'ga']) : super(locale);

  @override
  String get navServers => 'Freastalaithe';

  @override
  String get navCreate => 'Cruthaigh';

  @override
  String get navSettings => 'Socruithe';

  @override
  String get navAbout => 'Maidir leis';

  @override
  String get noServersYet => 'Níl aon fhreastalaí ann fós';

  @override
  String get noServersHint => 'Cruthaigh ceann ón gcluaisín Cruthaigh.';

  @override
  String get creatingServer => 'Freastalaí á chruthú…';

  @override
  String get createFailed => 'Theip ar chruthú an fhreastalaí';

  @override
  String get dismiss => 'Ruaig';

  @override
  String downloadingProgress(Object received, Object total) {
    return '$received / $total MB á n-ioslódáil';
  }

  @override
  String downloadingSimple(Object received) {
    return '$received MB á n-ioslódáil';
  }

  @override
  String get unknownError => 'earráid anaithnid';

  @override
  String get appearance => 'Dealramh';

  @override
  String get themeSystem => 'Córas';

  @override
  String get themeLight => 'Solas';

  @override
  String get themeDark => 'Dorcha';

  @override
  String get themeOled => 'OLED';

  @override
  String get dataDir => 'Eolaire sonraí';

  @override
  String get javaTitle => 'Java';

  @override
  String get javaRuntimes => 'Rith-amanna Java';

  @override
  String runtimesDetected(Object count) {
    return '$count aimsithe';
  }

  @override
  String get language => 'Teanga';

  @override
  String get languageSystem => 'Córas';

  @override
  String get aboutTagline => 'Bainisteoir freastalaí Minecraft Java Edition';

  @override
  String get version => 'Leagan';

  @override
  String get checkForUpdates => 'Seiceáil le haghaidh nuashonruithe';

  @override
  String get checkFailed => 'Theip ar an seiceáil';

  @override
  String updateAvailable(Object version) {
    return 'Nuashonrú ar fáil: $version';
  }

  @override
  String get upToDate => 'Tá an leagan is déanaí agat';

  @override
  String get checkReleasesHint =>
      'Seiceáil eisiúintí GitLab le haghaidh leagan nua';

  @override
  String get sourceCode => 'Cód foinse';

  @override
  String get createServerTitle => 'Cruthaigh freastalaí';

  @override
  String get loader => 'Lódálaí';

  @override
  String loadersFailed(Object error) {
    return 'Theip ar na lódálaithe a lódáil: $error';
  }

  @override
  String get selectLoader => 'Roghnaigh lódálaí';

  @override
  String get selectGameVersion => 'Roghnaigh leagan cluiche';

  @override
  String get serverName => 'Ainm an fhreastalaí';

  @override
  String get serverNameTaken => 'Tá freastalaí leis an ainm sin ann cheana';

  @override
  String memoryMb(Object amount) {
    return 'Cuimhne: $amount MB';
  }

  @override
  String get motd => 'MOTD';

  @override
  String get port => 'Port';

  @override
  String get acceptEula => 'Glacaim le EULA Minecraft';

  @override
  String get eulaRequired => 'Riachtanach chun freastalaí a rith — féach ';

  @override
  String get creating => 'Á chruthú…';

  @override
  String get defaultMotd => 'Freastalaí Minecraft';

  @override
  String get defaultServerName => 'Freastalaí Minecraft';

  @override
  String get serverNotFound => 'Freastalaí gan aimsiú';

  @override
  String get start => 'Tosaigh';

  @override
  String get stop => 'Stop';

  @override
  String get kill => 'Maraigh';

  @override
  String get restart => 'Atosaigh';

  @override
  String get deleteServerTooltip => 'Scrios an freastalaí';

  @override
  String get tabConsole => 'Consól';

  @override
  String get tabProperties => 'Airíonna';

  @override
  String get tabBackups => 'Cúltacaí';

  @override
  String get deleteServerTitle => 'Scrios an freastalaí?';

  @override
  String deleteServerBody(Object name) {
    return 'Scriosfar \"$name\" agus a chomhaid go léir go buan.';
  }

  @override
  String get cancel => 'Cealaigh';

  @override
  String get delete => 'Scrios';

  @override
  String get noConsoleOutput => 'Níl aon aschur consóil fós.';

  @override
  String get commandHint => 'Cuir isteach ordú freastalaí…';

  @override
  String get send => 'Seol';

  @override
  String get propertiesSaved => 'Airíonna sábháilte';

  @override
  String saveFailed(Object error) {
    return 'Theip ar an sábháil: $error';
  }

  @override
  String get saving => 'Á shábháil…';

  @override
  String get save => 'Sábháil';

  @override
  String propsLoadFailed(Object error) {
    return 'Theip ar lódáil na n-airíonna: $error';
  }

  @override
  String backupFailed(Object error) {
    return 'Theip ar an gcúltaca: $error';
  }

  @override
  String get restoreTitle => 'Athchóirigh an cúltaca?';

  @override
  String restoreBody(Object name) {
    return 'Stopfar an freastalaí agus forscríobhfar sonraí an domhain le $name.';
  }

  @override
  String get restore => 'Athchóirigh';

  @override
  String backupsLoadFailed(Object error) {
    return 'Theip ar lódáil na gcúltacaí: $error';
  }

  @override
  String get working => 'Ag obair…';

  @override
  String get createBackup => 'Cruthaigh cúltaca';

  @override
  String get noBackups => 'Níl aon chúltaca ann fós.';

  @override
  String get nameLabel => 'Ainm';

  @override
  String get minRam => 'RAM íosta (MB)';

  @override
  String get maxRam => 'RAM uasta (MB)';

  @override
  String get jvmArgs => 'Argóintí JVM breise';

  @override
  String get javaRuntime => 'Rith-am Java';

  @override
  String get javaAuto => 'Uathoibríoch (an meaitseáil is fearr)';

  @override
  String get settingsSaved => 'Socruithe sábháilte';

  @override
  String sizeMb(Object size) {
    return '$size MB';
  }

  @override
  String get downloads => 'Íoslódálacha';

  @override
  String get releasesLoadFailed => 'Níorbh fhéidir eisiúintí a lódáil';

  @override
  String get retry => 'Déan arís';

  @override
  String get detectedRuntimes => 'Rith-amanna aimsithe';

  @override
  String get noRuntimes => 'Níor aimsíodh aon rith-am Java.';

  @override
  String javaInstallFailed(Object error) {
    return 'Theip ar shuiteáil Java: $error';
  }

  @override
  String javaRemoveFailed(Object error) {
    return 'Theip ar bhaint Java: $error';
  }

  @override
  String get installed => 'Suiteáilte';

  @override
  String get install => 'Suiteáil';

  @override
  String get remove => 'Bain';

  @override
  String get extracting => 'Á asbhaint…';

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
  String get statusRunning => 'Ag rith';

  @override
  String get statusStarting => 'Ag tosú';

  @override
  String get statusStopping => 'Ag stopadh';

  @override
  String get statusStopped => 'Stoptha';

  @override
  String get statusCrashed => 'Tuairteáilte';
}
