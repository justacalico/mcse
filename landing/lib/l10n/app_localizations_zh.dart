// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'mcse — Minecraft 服务器管理器';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeOled => 'OLED';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get heroTagline =>
      '桌面端 Minecraft Java 版服务器管理器。支持 Vanilla、Paper、Purpur、Fabric、Forge 与 NeoForge —— 一个二进制文件，内置 Rust 后端。';

  @override
  String get download => '下载';

  @override
  String get sourceCode => '源代码';

  @override
  String get featuresTitle => '运行服务器所需的一切';

  @override
  String get featEveryLoader => '所有加载器';

  @override
  String get featEveryLoaderBody =>
      '支持 Vanilla、Paper、Purpur、Fabric、Forge 和 NeoForge，自动下载。';

  @override
  String get featConsole => '实时控制台';

  @override
  String get featConsoleBody => '发送命令并实时查看服务器日志。';

  @override
  String get featBackups => '备份';

  @override
  String get featBackupsBody => '一键创建、恢复和删除存档备份。';

  @override
  String get featJava => 'Java 运行时';

  @override
  String get featJavaBody => '检测已安装的 JDK，并在需要时安装 Temurin。';

  @override
  String get featPropsBody => '在界面中编辑所有属性 —— 无需翻找文件。';

  @override
  String get featBinary => '单一二进制';

  @override
  String get featBinaryBody => 'Rust 后端已编译进桌面应用。';

  @override
  String get showcaseTitle => '应用一览';

  @override
  String get shotServers => '服务器一目了然';

  @override
  String get shotCreate => '一个向导，所有加载器';

  @override
  String get shotConsole => '控制台与操作';

  @override
  String get shotSettings => 'Java 与主题设置';

  @override
  String get archTitle => '为超越桌面而生';

  @override
  String get archBody =>
      '管理逻辑位于独立的 Rust 后端，提供 REST + WebSocket API。Flutter 桌面应用将其内嵌；未来网页 UI 也可以对接同一 API。';

  @override
  String get archFlutter => 'Flutter 桌面端';

  @override
  String get archPlatforms => 'Linux · Windows · macOS';

  @override
  String get archRust => 'Rust 后端';

  @override
  String get archApi => 'REST + WebSocket API';

  @override
  String get archWeb => '网页 UI';

  @override
  String get archWebSub => '同一 API，任意浏览器';

  @override
  String get archFrb => '内嵌 (FRB)';

  @override
  String get downloadsTitle => '下载';

  @override
  String get allReleases => 'GitLab 上的所有发行版';

  @override
  String get releasesError => '无法加载发行版 —— 请前往 GitLab 获取。';

  @override
  String get noReleases => '暂无发行版 —— 首个版本即将到来。';

  @override
  String get noAssets => '没有可下载的附件';

  @override
  String get releases => '发行版';

  @override
  String get githubMirror => 'GitHub 镜像';

  @override
  String get footerLine => 'mcse — AGPL-3.0 · 与 Mojang 或 Microsoft 无关';
}
