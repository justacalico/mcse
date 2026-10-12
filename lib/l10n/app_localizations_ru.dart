// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get navServers => 'Серверы';

  @override
  String get navCreate => 'Создать';

  @override
  String get navSettings => 'Настройки';

  @override
  String get navAbout => 'О программе';

  @override
  String get noServersYet => 'Серверов пока нет';

  @override
  String get noServersHint => 'Создайте сервер на вкладке «Создать».';

  @override
  String get creatingServer => 'Создание сервера…';

  @override
  String get createFailed => 'Не удалось создать сервер';

  @override
  String get dismiss => 'Закрыть';

  @override
  String downloadingProgress(Object received, Object total) {
    return 'Загрузка $received / $total МБ';
  }

  @override
  String downloadingSimple(Object received) {
    return 'Загрузка $received МБ';
  }

  @override
  String get unknownError => 'неизвестная ошибка';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeOled => 'OLED';

  @override
  String get dataDir => 'Каталог данных';

  @override
  String get javaTitle => 'Java';

  @override
  String get javaRuntimes => 'Среды выполнения Java';

  @override
  String runtimesDetected(Object count) {
    return 'обнаружено: $count';
  }

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Системный';

  @override
  String get aboutTagline => 'Менеджер серверов Minecraft Java Edition';

  @override
  String get version => 'Версия';

  @override
  String get checkForUpdates => 'Проверить обновления';

  @override
  String get checkFailed => 'Ошибка проверки';

  @override
  String updateAvailable(Object version) {
    return 'Доступно обновление: $version';
  }

  @override
  String get upToDate => 'Установлена последняя версия';

  @override
  String get checkReleasesHint => 'Проверьте новые версии в релизах GitLab';

  @override
  String get sourceCode => 'Исходный код';

  @override
  String get createServerTitle => 'Создать сервер';

  @override
  String get loader => 'Загрузчик';

  @override
  String loadersFailed(Object error) {
    return 'Не удалось загрузить список загрузчиков: $error';
  }

  @override
  String get selectLoader => 'Выберите загрузчик';

  @override
  String get selectGameVersion => 'Выберите версию игры';

  @override
  String get serverName => 'Имя сервера';

  @override
  String get serverNameTaken => 'Сервер с таким именем уже существует';

  @override
  String memoryMb(Object amount) {
    return 'Память: $amount МБ';
  }

  @override
  String get motd => 'MOTD';

  @override
  String get port => 'Порт';

  @override
  String get acceptEula => 'Я принимаю Minecraft EULA';

  @override
  String get eulaRequired => 'Требуется для запуска сервера — см. ';

  @override
  String get creating => 'Создание…';

  @override
  String get defaultMotd => 'Сервер Minecraft';

  @override
  String get defaultServerName => 'Сервер Minecraft';

  @override
  String get serverNotFound => 'Сервер не найден';

  @override
  String get start => 'Запустить';

  @override
  String get stop => 'Остановить';

  @override
  String get kill => 'Завершить принудительно';

  @override
  String get restart => 'Перезапустить';

  @override
  String get deleteServerTooltip => 'Удалить сервер';

  @override
  String get tabConsole => 'Консоль';

  @override
  String get tabProperties => 'Свойства';

  @override
  String get tabBackups => 'Резервные копии';

  @override
  String get deleteServerTitle => 'Удалить сервер?';

  @override
  String deleteServerBody(Object name) {
    return 'Будут безвозвратно удалены «$name» и все его файлы.';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get noConsoleOutput => 'Вывод консоли пока пуст.';

  @override
  String get commandHint => 'Введите команду сервера…';

  @override
  String get send => 'Отправить';

  @override
  String get propertiesSaved => 'Свойства сохранены';

  @override
  String saveFailed(Object error) {
    return 'Ошибка сохранения: $error';
  }

  @override
  String get saving => 'Сохранение…';

  @override
  String get save => 'Сохранить';

  @override
  String propsLoadFailed(Object error) {
    return 'Не удалось загрузить свойства: $error';
  }

  @override
  String backupFailed(Object error) {
    return 'Ошибка резервного копирования: $error';
  }

  @override
  String get restoreTitle => 'Восстановить копию?';

  @override
  String restoreBody(Object name) {
    return 'Сервер будет остановлен, а данные мира будут перезаписаны копией $name.';
  }

  @override
  String get restore => 'Восстановить';

  @override
  String backupsLoadFailed(Object error) {
    return 'Не удалось загрузить резервные копии: $error';
  }

  @override
  String get working => 'Выполняется…';

  @override
  String get createBackup => 'Создать резервную копию';

  @override
  String get noBackups => 'Резервных копий пока нет.';

  @override
  String get nameLabel => 'Имя';

  @override
  String get minRam => 'Мин. ОЗУ (МБ)';

  @override
  String get maxRam => 'Макс. ОЗУ (МБ)';

  @override
  String get jvmArgs => 'Доп. аргументы JVM';

  @override
  String get javaRuntime => 'Среда выполнения Java';

  @override
  String get javaAuto => 'Авто (лучшее совпадение)';

  @override
  String get settingsSaved => 'Настройки сохранены';

  @override
  String sizeMb(Object size) {
    return '$size МБ';
  }

  @override
  String get downloads => 'Загрузки';

  @override
  String get releasesLoadFailed => 'Не удалось загрузить список релизов';

  @override
  String get retry => 'Повторить';

  @override
  String get detectedRuntimes => 'Обнаруженные среды';

  @override
  String get noRuntimes => 'Среды выполнения Java не найдены.';

  @override
  String javaInstallFailed(Object error) {
    return 'Ошибка установки Java: $error';
  }

  @override
  String javaRemoveFailed(Object error) {
    return 'Ошибка удаления Java: $error';
  }

  @override
  String get installed => 'Установлено';

  @override
  String get install => 'Установить';

  @override
  String get remove => 'Удалить';

  @override
  String get extracting => 'Распаковка…';

  @override
  String javaProgressTotal(Object received, Object total) {
    return '$received / $total МБ';
  }

  @override
  String javaProgressMb(Object received) {
    return '$received МБ';
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
  String get statusRunning => 'Работает';

  @override
  String get statusStarting => 'Запускается';

  @override
  String get statusStopping => 'Останавливается';

  @override
  String get statusStopped => 'Остановлен';

  @override
  String get statusCrashed => 'Аварийно завершён';
}
