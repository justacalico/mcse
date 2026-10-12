import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/app_localizations.dart';

const _repo = 'HttpAnimations/mcse';
const _repoUrl = 'https://gitlab.com/$_repo';
const _releasesUrl = '$_repoUrl/-/releases';
const _releasesApi =
    'https://gitlab.com/api/v4/projects/HttpAnimations%2Fmcse/releases?per_page=20';

void main() => runApp(const LandingApp());

enum SiteTheme { system, light, dark, oled }

class ThemeController extends ChangeNotifier {
  SiteTheme mode = SiteTheme.system;

  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('landing_theme');
    final c = ThemeController();
    c.mode = SiteTheme.values.asNameMap()[saved] ?? SiteTheme.system;
    return c;
  }

  Future<void> set(SiteTheme m) async {
    mode = m;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('landing_theme', m.name);
  }
}

class LocaleController extends ChangeNotifier {
  Locale? locale;

  static Future<LocaleController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final c = LocaleController();
    c.locale = decode(prefs.getString('landing_locale'));
    return c;
  }

  static Locale? decode(String? raw) {
    if (raw == null) return null;
    for (final l in AppLocalizations.supportedLocales) {
      if (l.toLanguageTag() == raw) return l;
    }
    return null;
  }

  Future<void> set(Locale? l) async {
    locale = l;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (l == null) {
      await prefs.remove('landing_locale');
    } else {
      await prefs.setString('landing_locale', l.toLanguageTag());
    }
  }
}

class LandingApp extends StatefulWidget {
  const LandingApp({super.key, this.controller, this.localeController});
  final ThemeController? controller;
  final LocaleController? localeController;

  @override
  State<LandingApp> createState() => _LandingAppState();
}

class _LandingAppState extends State<LandingApp> {
  late ThemeController _c;
  late LocaleController _l;
  late bool _ready;

  @override
  void initState() {
    super.initState();
    _c = widget.controller ?? ThemeController();
    _l = widget.localeController ?? LocaleController();
    _ready = widget.controller != null && widget.localeController != null;
    if (!_ready) {
      Future.wait([
        if (widget.controller == null) ThemeController.load(),
        if (widget.localeController == null) LocaleController.load(),
      ]).then((loaded) {
        if (!mounted) return;
        setState(() {
          var i = 0;
          if (widget.controller == null) _c = loaded[i++] as ThemeController;
          if (widget.localeController == null) {
            _l = loaded[i] as LocaleController;
          }
          _ready = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: Listenable.merge([_c, _l]),
      builder: (context, _) {
        final oled = _c.mode == SiteTheme.oled;
        final dark = oled ||
            _c.mode == SiteTheme.dark ||
            (_c.mode == SiteTheme.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        final theme = _themeFor(dark: dark, oled: oled);
        return MaterialApp(
          onGenerateTitle: (context) =>
              AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          locale: _l.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: theme,
          home: LandingPage(controller: _c, localeController: _l),
        );
      },
    );
  }

  ThemeData _themeFor({required bool dark, required bool oled}) {
    const green = Color(0xFF54B049);
    if (!dark) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
            seedColor: green, brightness: Brightness.light),
      );
    }
    final scheme = ColorScheme.fromSeed(
        seedColor: green, brightness: Brightness.dark);
    final t = ThemeData(
        useMaterial3: true, brightness: Brightness.dark, colorScheme: scheme);
    if (oled) {
      return t.copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: scheme.copyWith(surface: Colors.black),
      );
    }
    return t;
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage(
      {super.key, required this.controller, required this.localeController});
  final ThemeController controller;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width > 860;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/img/icon.png', width: 28, height: 28)),
          const SizedBox(width: 10),
          const Text('mcse'),
        ]),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: l10n.language,
            initialValue: switch (
                localeController.locale?.toLanguageTag()) {
              'zh' || 'ru' || 'ga' =>
                localeController.locale!.toLanguageTag(),
              'en-GB' => 'en-GB',
              null => 'system',
              String t when t.startsWith('en') => 'en-GB',
              _ => 'system',
            },
            onSelected: (v) => localeController
                .set(v == 'system' ? null : LocaleController.decode(v)),
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'system', child: Text(l10n.languageSystem)),
              const PopupMenuItem(
                  value: 'en-GB', child: Text('Traditional English')),
              const PopupMenuItem(value: 'zh', child: Text('简体中文')),
              const PopupMenuItem(value: 'ru', child: Text('Русский')),
              const PopupMenuItem(value: 'ga', child: Text('Gaeilge')),
            ],
          ),
          SegmentedButton<SiteTheme>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: SiteTheme.system, icon: const Icon(Icons.brightness_auto), tooltip: l10n.themeSystem),
              ButtonSegment(value: SiteTheme.light, icon: const Icon(Icons.light_mode), tooltip: l10n.themeLight),
              ButtonSegment(value: SiteTheme.dark, icon: const Icon(Icons.dark_mode), tooltip: l10n.themeDark),
              ButtonSegment(value: SiteTheme.oled, icon: const Icon(Icons.nights_stay), tooltip: l10n.themeOled),
            ],
            selected: {controller.mode},
            onSelectionChanged: (s) => controller.set(s.first),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        children: [
          _Hero(wide: wide),
          const _Features(),
          const _Showcase(),
          const _Architecture(),
          const _Downloads(),
          const _Footer(),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: wide ? 96 : 24, vertical: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('assets/img/icon.png',
                  width: 96, height: 96)),
          const SizedBox(height: 24),
          Text('mcse', style: t.displayLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              AppLocalizations.of(context).heroTagline,
              style: t.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(spacing: 12, runSpacing: 12, children: [
            FilledButton.icon(
              icon: const Icon(Icons.download),
              label: Text(AppLocalizations.of(context).download),
              onPressed: () => launchUrl(Uri.parse(_releasesUrl)),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.code),
              label: Text(AppLocalizations.of(context).sourceCode),
              onPressed: () => launchUrl(Uri.parse(_repoUrl)),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Features extends StatelessWidget {
  const _Features();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (Icons.dns, l10n.featEveryLoader, l10n.featEveryLoaderBody),
      (Icons.terminal, l10n.featConsole, l10n.featConsoleBody),
      (Icons.archive_outlined, l10n.featBackups, l10n.featBackupsBody),
      (Icons.coffee, l10n.featJava, l10n.featJavaBody),
      (Icons.tune, 'server.properties', l10n.featPropsBody),
      (Icons.layers_outlined, l10n.featBinary, l10n.featBinaryBody),
    ];
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(children: [
        Text(l10n.featuresTitle, style: t.headlineMedium),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            for (final (icon, title, body) in items)
              SizedBox(
                width: 300,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: 32),
                        const SizedBox(height: 12),
                        Text(title, style: t.titleMedium),
                        const SizedBox(height: 4),
                        Text(body, style: t.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}

class _Showcase extends StatelessWidget {
  const _Showcase();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shots = [
      ('assets/screenshots/servers.png', l10n.shotServers),
      ('assets/screenshots/create.png', l10n.shotCreate),
      ('assets/screenshots/detail_console.png', l10n.shotConsole),
      ('assets/screenshots/settings.png', l10n.shotSettings),
    ];
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(children: [
        Text(l10n.showcaseTitle, style: t.headlineMedium),
        const SizedBox(height: 24),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            for (final (path, caption) in shots)
              Column(children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(path, width: 420),
                ),
                const SizedBox(height: 8),
                Text(caption, style: t.bodySmall),
              ]),
          ],
        ),
      ]),
    );
  }
}

class _Architecture extends StatelessWidget {
  const _Architecture();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(children: [
        Text(l10n.archTitle, style: t.headlineMedium),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            l10n.archBody,
            style: t.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: CustomPaint(
              size: const Size(720, 260),
              painter: _ArchPainter(
                scheme: scheme,
                textTheme: t,
                flutterLabel: l10n.archFlutter,
                platformsLabel: l10n.archPlatforms,
                rustLabel: l10n.archRust,
                apiLabel: l10n.archApi,
                webLabel: l10n.archWeb,
                webSubLabel: l10n.archWebSub,
                frbLabel: l10n.archFrb,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ArchPainter extends CustomPainter {
  _ArchPainter({
    required this.scheme,
    required this.textTheme,
    required this.flutterLabel,
    required this.platformsLabel,
    required this.rustLabel,
    required this.apiLabel,
    required this.webLabel,
    required this.webSubLabel,
    required this.frbLabel,
  });
  final ColorScheme scheme;
  final TextTheme textTheme;
  final String flutterLabel;
  final String platformsLabel;
  final String rustLabel;
  final String apiLabel;
  final String webLabel;
  final String webSubLabel;
  final String frbLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = scheme.surfaceContainerHighest
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = scheme.outline
      ..strokeWidth = 2;
    final accent = Paint()
      ..color = scheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    void box(Rect r, String title, String sub) {
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
      canvas.drawRRect(rr, boxPaint);
      canvas.drawRRect(rr, accent..strokeWidth = 1.5);
      _text(canvas, title, r.center - const Offset(0, 10),
          textTheme.titleSmall!, scheme.onSurface);
      _text(canvas, sub, r.center + const Offset(0, 14),
          textTheme.bodySmall!, scheme.onSurfaceVariant);
    }

    void arrow(Offset a, Offset b, String label) {
      canvas.drawLine(a, b, linePaint);
      final dir = (b - a);
      final unit = dir / dir.distance;
      final tip = b;
      final left = tip - Offset(unit.dx * 10 - unit.dy * 5, unit.dy * 10 + unit.dx * 5);
      final right = tip - Offset(unit.dx * 10 + unit.dy * 5, unit.dy * 10 - unit.dx * 5);
      canvas.drawPath(Path()..addPolygon([tip, left, right], true), Paint()..color = scheme.outline);
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 - 14);
      _text(canvas, label, mid, textTheme.labelSmall!, scheme.outline);
    }

    final w = size.width;
    box(Rect.fromLTWH(0, 40, 200, 80), flutterLabel, platformsLabel);
    box(Rect.fromLTWH(w - 200, 40, 200, 80), rustLabel, apiLabel);
    box(Rect.fromLTWH(w / 2 - 110, 180, 220, 70), webLabel, webSubLabel);
    arrow(const Offset(200, 80), Offset(w - 200, 80), frbLabel);
    arrow(Offset(w / 2 + 110, 180), Offset(w - 100, 120), 'HTTP + WS');
  }

  void _text(Canvas c, String s, Offset center, TextStyle style, Color color) {
    final tp = TextPainter(
        text: TextSpan(text: s, style: style.copyWith(color: color)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ArchPainter old) =>
      old.scheme != scheme ||
      old.flutterLabel != flutterLabel ||
      old.platformsLabel != platformsLabel ||
      old.rustLabel != rustLabel ||
      old.apiLabel != apiLabel ||
      old.webLabel != webLabel ||
      old.webSubLabel != webSubLabel ||
      old.frbLabel != frbLabel;
}

class _Downloads extends StatefulWidget {
  const _Downloads();

  @override
  State<_Downloads> createState() => _DownloadsState();
}

class _DownloadsState extends State<_Downloads> {
  late final Future<List<_Release>> _future = _load();

  Future<List<_Release>> _load() async {
    final res = await http
        .get(Uri.parse(_releasesApi),
            headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return const [];
    return [
      for (final r in decoded)
        if (r is Map<String, dynamic>)
          _Release(
            tag: r['tag_name'] as String? ?? '',
            name: r['name'] as String? ?? '',
            date: (r['released_at'] as String? ?? '').safeDate(),
            assets: [
              for (final l in (r['assets']?['links'] as List? ?? const []))
                if (l is Map<String, dynamic>)
                  _Asset(name: l['name'] as String? ?? '',
                      url: l['direct_asset_url'] as String? ??
                          l['url'] as String? ?? ''),
            ],
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(children: [
        Text(l10n.downloadsTitle, style: t.headlineMedium),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.open_in_new),
          label: Text(l10n.allReleases),
          onPressed: () => launchUrl(Uri.parse(_releasesUrl)),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: FutureBuilder<List<_Release>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) {
                return Text(l10n.releasesError, style: t.bodyMedium);
              }
              final releases = snap.data ?? const [];
              if (releases.isEmpty) {
                return Text(l10n.noReleases, style: t.bodyMedium);
              }
              return Column(children: [
                for (final r in releases)
                  Card(
                    child: ExpansionTile(
                      title: Text(r.name.isNotEmpty ? r.name : r.tag),
                      subtitle: Text('${r.tag} · ${r.date}'),
                      children: [
                        for (final a in r.assets)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.file_download_outlined),
                            title: Text(a.name),
                            onTap: () => launchUrl(Uri.parse(a.url)),
                          ),
                        if (r.assets.isEmpty)
                          ListTile(
                              dense: true,
                              title: Text(l10n.noAssets)),
                      ],
                    ),
                  ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

class _Release {
  final String tag, name, date;
  final List<_Asset> assets;
  const _Release(
      {required this.tag,
      required this.name,
      required this.date,
      required this.assets});
}

class _Asset {
  final String name, url;
  const _Asset({required this.name, required this.url});
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Wrap(spacing: 24, children: [
          TextButton(
              onPressed: () => launchUrl(Uri.parse(_repoUrl)),
              child: const Text('GitLab')),
          TextButton(
              onPressed: () => launchUrl(Uri.parse(_releasesUrl)),
              child: Text(l10n.releases)),
          TextButton(
              onPressed: () => launchUrl(
                  Uri.parse('https://github.com/justacalico/mcse')),
              child: Text(l10n.githubMirror)),
        ]),
        const SizedBox(height: 8),
        Text(l10n.footerLine, style: t.bodySmall),
      ]),
    );
  }
}

extension on String {
  String safeDate() => length >= 10 ? substring(0, 10) : this;
}
