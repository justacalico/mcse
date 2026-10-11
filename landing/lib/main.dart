import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

class LandingApp extends StatefulWidget {
  const LandingApp({super.key, this.controller});
  final ThemeController? controller;

  @override
  State<LandingApp> createState() => _LandingAppState();
}

class _LandingAppState extends State<LandingApp> {
  late ThemeController _c;
  late bool _ready;

  @override
  void initState() {
    super.initState();
    _c = widget.controller ?? ThemeController();
    _ready = widget.controller != null;
    if (!_ready) {
      ThemeController.load().then((c) => setState(() {
            _c = c;
            _ready = true;
          }));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final oled = _c.mode == SiteTheme.oled;
        final dark = oled ||
            _c.mode == SiteTheme.dark ||
            (_c.mode == SiteTheme.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        final theme = _themeFor(dark: dark, oled: oled);
        return MaterialApp(
          title: 'mcse — Minecraft server manager',
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: LandingPage(controller: _c),
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
  const LandingPage({super.key, required this.controller});
  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
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
          SegmentedButton<SiteTheme>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: SiteTheme.system, icon: Icon(Icons.brightness_auto), tooltip: 'System'),
              ButtonSegment(value: SiteTheme.light, icon: Icon(Icons.light_mode), tooltip: 'Light'),
              ButtonSegment(value: SiteTheme.dark, icon: Icon(Icons.dark_mode), tooltip: 'Dark'),
              ButtonSegment(value: SiteTheme.oled, icon: Icon(Icons.nights_stay), tooltip: 'OLED'),
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
              'A desktop Minecraft Java Edition server manager. '
              'Vanilla, Paper, Purpur, Fabric, Forge and NeoForge — '
              'one binary, a built-in Rust backend.',
              style: t.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(spacing: 12, runSpacing: 12, children: [
            FilledButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download'),
              onPressed: () => launchUrl(Uri.parse(_releasesUrl)),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.code),
              label: const Text('Source code'),
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

  static const _items = [
    (Icons.dns, 'Every loader', 'Vanilla, Paper, Purpur, Fabric, Forge and NeoForge with automatic downloads.'),
    (Icons.terminal, 'Live console', 'Send commands and watch the server log in real time.'),
    (Icons.archive_outlined, 'Backups', 'Create, restore and delete world backups in one click.'),
    (Icons.coffee, 'Java runtimes', 'Detects installed JDKs and installs Temurin when needed.'),
    (Icons.tune, 'server.properties', 'Edit every property from the UI — no file hunting.'),
    (Icons.layers_outlined, 'Single binary', 'The Rust backend is compiled into the desktop app.'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(children: [
        Text('Everything you need to run a server', style: t.headlineMedium),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            for (final (icon, title, body) in _items)
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

  static const _shots = [
    ('assets/screenshots/servers.png', 'Your servers at a glance'),
    ('assets/screenshots/create.png', 'One wizard, every loader'),
    ('assets/screenshots/detail_console.png', 'Console and controls'),
    ('assets/screenshots/settings.png', 'Java and theme settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(children: [
        Text('Inside the app', style: t.headlineMedium),
        const SizedBox(height: 24),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            for (final (path, caption) in _shots)
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(children: [
        Text('Built to outgrow the desktop', style: t.headlineMedium),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'The management logic lives in a standalone Rust backend with a '
            'REST + WebSocket API. The Flutter desktop app embeds it; a web '
            'UI can talk to the same API tomorrow.',
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
              painter: _ArchPainter(scheme: scheme, textTheme: t),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ArchPainter extends CustomPainter {
  _ArchPainter({required this.scheme, required this.textTheme});
  final ColorScheme scheme;
  final TextTheme textTheme;

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
    box(Rect.fromLTWH(0, 40, 200, 80), 'Flutter desktop', 'Linux · Windows · macOS');
    box(Rect.fromLTWH(w - 200, 40, 200, 80), 'Rust backend', 'REST + WebSocket API');
    box(Rect.fromLTWH(w / 2 - 110, 180, 220, 70), 'Web UI', 'same API, any browser');
    arrow(const Offset(200, 80), Offset(w - 200, 80), 'embedded (FRB)');
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
  bool shouldRepaint(covariant _ArchPainter old) => old.scheme != scheme;
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
            date: (r['released_at'] as String? ?? '').substring(0, 10),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(children: [
        Text('Downloads', style: t.headlineMedium),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.open_in_new),
          label: const Text('All releases on GitLab'),
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
                return Text('Could not load releases — grab them on GitLab.',
                    style: t.bodyMedium);
              }
              final releases = snap.data ?? const [];
              if (releases.isEmpty) {
                return Text('No releases yet — the first build is on its way.',
                    style: t.bodyMedium);
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
                          const ListTile(
                              dense: true,
                              title: Text('No downloadable assets')),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Wrap(spacing: 24, children: [
          TextButton(
              onPressed: () => launchUrl(Uri.parse(_repoUrl)),
              child: const Text('GitLab')),
          TextButton(
              onPressed: () => launchUrl(Uri.parse(_releasesUrl)),
              child: const Text('Releases')),
          TextButton(
              onPressed: () => launchUrl(
                  Uri.parse('https://github.com/justacalico/mcse')),
              child: const Text('GitHub mirror')),
        ]),
        const SizedBox(height: 8),
        Text('mcse — AGPL-3.0 · not affiliated with Mojang or Microsoft',
            style: t.bodySmall),
      ]),
    );
  }
}
