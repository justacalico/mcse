import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../state/locale_state.dart';
import '../state/theme_state.dart';
import 'java_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int? _runtimeCount;
  String? _dataDir;

  @override
  void initState() {
    super.initState();
    final backend = context.read<AppState>().backend;
    backend
        .javaRuntimes()
        .then((r) {
          if (mounted) setState(() => _runtimeCount = r.length);
        })
        .catchError((_) {
          if (mounted) setState(() => _runtimeCount = 0);
        });
    backend
        .dataDir()
        .then((d) {
          if (mounted) setState(() => _dataDir = d);
        })
        .catchError((_) {
          if (mounted) setState(() => _dataDir = '?');
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final locale = context.watch<LocaleState>();
    final l10n = AppLocalizations.of(context);
    final langTag = locale.locale?.toLanguageTag();
    final lang = switch (langTag) {
      'en-GB' || 'zh' || 'ru' || 'ga' => langTag!,
      String t when t.startsWith('en') => 'en-GB',
      _ => 'system',
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.appearance,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<AppTheme>(
            segments: [
              ButtonSegment(
                  value: AppTheme.system,
                  label: Text(l10n.themeSystem)),
              ButtonSegment(
                  value: AppTheme.light, label: Text(l10n.themeLight)),
              ButtonSegment(
                  value: AppTheme.dark, label: Text(l10n.themeDark)),
              ButtonSegment(
                  value: AppTheme.oled, label: Text(l10n.themeOled)),
            ],
            selected: {theme.mode},
            onSelectionChanged: (s) => theme.setMode(s.first),
          ),
          const SizedBox(height: 24),
          Text(l10n.language,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: lang,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                  value: 'system', child: Text(l10n.languageSystem)),
              const DropdownMenuItem(
                  value: 'en-GB',
                  child: Text('Traditional English')),
              const DropdownMenuItem(
                  value: 'zh', child: Text('简体中文')),
              const DropdownMenuItem(
                  value: 'ru', child: Text('Русский')),
              const DropdownMenuItem(
                  value: 'ga', child: Text('Gaeilge')),
            ],
            onChanged: (v) =>
                locale.setLocale(v == 'system' ? null : LocaleState.decode(v)),
          ),
          const SizedBox(height: 24),
          Text(l10n.dataDir,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(_dataDir ?? '…', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          Text(l10n.javaTitle,
              style: Theme.of(context).textTheme.titleSmall),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.coffee),
            title: Text(l10n.javaRuntimes),
            subtitle: Text(_runtimeCount == null
                ? '…'
                : l10n.runtimesDetected(_runtimeCount!)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JavaPage())),
          ),
        ],
      ),
    );
  }
}
