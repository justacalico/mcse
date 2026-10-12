// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get navServers => '服务器';

  @override
  String get navCreate => '创建';

  @override
  String get navSettings => '设置';

  @override
  String get navAbout => '关于';

  @override
  String get noServersYet => '还没有服务器';

  @override
  String get noServersHint => '在“创建”标签页中新建一个。';

  @override
  String get creatingServer => '正在创建服务器…';

  @override
  String get createFailed => '服务器创建失败';

  @override
  String get dismiss => '关闭';

  @override
  String downloadingProgress(Object received, Object total) {
    return '正在下载 $received / $total MB';
  }

  @override
  String downloadingSimple(Object received) {
    return '正在下载 $received MB';
  }

  @override
  String get unknownError => '未知错误';

  @override
  String get appearance => '外观';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeOled => 'OLED';

  @override
  String get dataDir => '数据目录';

  @override
  String get javaTitle => 'Java';

  @override
  String get javaRuntimes => 'Java 运行时';

  @override
  String runtimesDetected(Object count) {
    return '已检测到 $count 个';
  }

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get aboutTagline => 'Minecraft Java 版服务器管理器';

  @override
  String get version => '版本';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get checkFailed => '检查失败';

  @override
  String updateAvailable(Object version) {
    return '有可用更新：$version';
  }

  @override
  String get upToDate => '已是最新';

  @override
  String get checkReleasesHint => '前往 GitLab 发布页检查新版本';

  @override
  String get sourceCode => '源代码';

  @override
  String get createServerTitle => '创建服务器';

  @override
  String get loader => '加载器';

  @override
  String loadersFailed(Object error) {
    return '加载器列表加载失败：$error';
  }

  @override
  String get selectLoader => '选择加载器';

  @override
  String get selectGameVersion => '选择游戏版本';

  @override
  String get serverName => '服务器名称';

  @override
  String get serverNameTaken => '同名服务器已存在';

  @override
  String memoryMb(Object amount) {
    return '内存：$amount MB';
  }

  @override
  String get motd => 'MOTD';

  @override
  String get port => '端口';

  @override
  String get acceptEula => '我接受 Minecraft EULA';

  @override
  String get eulaRequired => '运行服务器前必须同意 —— 详见 ';

  @override
  String get creating => '创建中…';

  @override
  String get defaultMotd => '一个 Minecraft 服务器';

  @override
  String get defaultServerName => 'Minecraft 服务器';

  @override
  String get serverNotFound => '未找到服务器';

  @override
  String get start => '启动';

  @override
  String get stop => '停止';

  @override
  String get kill => '强制结束';

  @override
  String get restart => '重启';

  @override
  String get deleteServerTooltip => '删除服务器';

  @override
  String get tabConsole => '控制台';

  @override
  String get tabProperties => '属性';

  @override
  String get tabBackups => '备份';

  @override
  String get deleteServerTitle => '删除服务器？';

  @override
  String deleteServerBody(Object name) {
    return '将永久删除“$name”及其所有文件。';
  }

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get noConsoleOutput => '暂无控制台输出。';

  @override
  String get commandHint => '输入服务器命令…';

  @override
  String get send => '发送';

  @override
  String get propertiesSaved => '属性已保存';

  @override
  String saveFailed(Object error) {
    return '保存失败：$error';
  }

  @override
  String get saving => '保存中…';

  @override
  String get save => '保存';

  @override
  String propsLoadFailed(Object error) {
    return '属性加载失败：$error';
  }

  @override
  String backupFailed(Object error) {
    return '备份失败：$error';
  }

  @override
  String get restoreTitle => '恢复备份？';

  @override
  String restoreBody(Object name) {
    return '将停止服务器并用 $name 覆盖存档数据。';
  }

  @override
  String get restore => '恢复';

  @override
  String backupsLoadFailed(Object error) {
    return '备份加载失败：$error';
  }

  @override
  String get working => '处理中…';

  @override
  String get createBackup => '创建备份';

  @override
  String get noBackups => '还没有备份。';

  @override
  String get nameLabel => '名称';

  @override
  String get minRam => '最小内存 (MB)';

  @override
  String get maxRam => '最大内存 (MB)';

  @override
  String get jvmArgs => '额外 JVM 参数';

  @override
  String get javaRuntime => 'Java 运行时';

  @override
  String get javaAuto => '自动（最佳匹配）';

  @override
  String get settingsSaved => '设置已保存';

  @override
  String sizeMb(Object size) {
    return '$size MB';
  }

  @override
  String get downloads => '下载';

  @override
  String get releasesLoadFailed => '无法加载发行版列表';

  @override
  String get retry => '重试';

  @override
  String get detectedRuntimes => '检测到的运行时';

  @override
  String get noRuntimes => '未找到 Java 运行时。';

  @override
  String javaInstallFailed(Object error) {
    return 'Java 安装失败：$error';
  }

  @override
  String javaRemoveFailed(Object error) {
    return 'Java 移除失败：$error';
  }

  @override
  String get installed => '已安装';

  @override
  String get install => '安装';

  @override
  String get remove => '移除';

  @override
  String get extracting => '解压中…';

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
  String get statusRunning => '运行中';

  @override
  String get statusStarting => '启动中';

  @override
  String get statusStopping => '停止中';

  @override
  String get statusStopped => '已停止';

  @override
  String get statusCrashed => '已崩溃';
}
