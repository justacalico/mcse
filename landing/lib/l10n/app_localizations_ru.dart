// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'mcse — менеджер серверов Minecraft';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeOled => 'OLED';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Системный';

  @override
  String get heroTagline =>
      'Десктопный менеджер серверов Minecraft Java Edition. Vanilla, Paper, Purpur, Fabric, Forge и NeoForge — один бинарник со встроенным Rust-бэкендом.';

  @override
  String get download => 'Скачать';

  @override
  String get sourceCode => 'Исходный код';

  @override
  String get featuresTitle => 'Всё необходимое для запуска сервера';

  @override
  String get featEveryLoader => 'Любой загрузчик';

  @override
  String get featEveryLoaderBody =>
      'Vanilla, Paper, Purpur, Fabric, Forge и NeoForge с автоматической загрузкой.';

  @override
  String get featConsole => 'Живая консоль';

  @override
  String get featConsoleBody =>
      'Отправляйте команды и следите за журналом сервера в реальном времени.';

  @override
  String get featBackups => 'Резервные копии';

  @override
  String get featBackupsBody =>
      'Создавайте, восстанавливайте и удаляйте копии мира в один клик.';

  @override
  String get featJava => 'Среды выполнения Java';

  @override
  String get featJavaBody =>
      'Обнаруживает установленные JDK и устанавливает Temurin при необходимости.';

  @override
  String get featPropsBody =>
      'Редактируйте любое свойство из интерфейса — не нужно искать файлы.';

  @override
  String get featBinary => 'Один бинарник';

  @override
  String get featBinaryBody =>
      'Rust-бэкенд скомпилирован прямо в десктопное приложение.';

  @override
  String get showcaseTitle => 'Внутри приложения';

  @override
  String get shotServers => 'Все серверы на одном экране';

  @override
  String get shotCreate => 'Один мастер — любой загрузчик';

  @override
  String get shotConsole => 'Консоль и управление';

  @override
  String get shotSettings => 'Настройки Java и темы';

  @override
  String get archTitle => 'Создано, чтобы выйти за рамки десктопа';

  @override
  String get archBody =>
      'Логика управления живёт в отдельном Rust-бэкенде с REST + WebSocket API. Десктопное приложение на Flutter встраивает его; веб-интерфейс сможет работать с тем же API.';

  @override
  String get archFlutter => 'Flutter-десктоп';

  @override
  String get archPlatforms => 'Linux · Windows · macOS';

  @override
  String get archRust => 'Rust-бэкенд';

  @override
  String get archApi => 'REST + WebSocket API';

  @override
  String get archWeb => 'Веб-интерфейс';

  @override
  String get archWebSub => 'тот же API, любой браузер';

  @override
  String get archFrb => 'встроен (FRB)';

  @override
  String get downloadsTitle => 'Загрузки';

  @override
  String get allReleases => 'Все релизы на GitLab';

  @override
  String get releasesError =>
      'Не удалось загрузить релизы — скачайте их на GitLab.';

  @override
  String get noReleases => 'Релизов пока нет — первая сборка уже в пути.';

  @override
  String get noAssets => 'Нет файлов для скачивания';

  @override
  String get releases => 'Релизы';

  @override
  String get githubMirror => 'Зеркало на GitHub';

  @override
  String get footerLine => 'mcse — AGPL-3.0 · не связан с Mojang или Microsoft';
}
