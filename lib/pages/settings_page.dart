import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<AppTheme>(
            segments: const [
              ButtonSegment(
                  value: AppTheme.system, label: Text('System')),
              ButtonSegment(
                  value: AppTheme.light, label: Text('Light')),
              ButtonSegment(value: AppTheme.dark, label: Text('Dark')),
              ButtonSegment(value: AppTheme.oled, label: Text('OLED')),
            ],
            selected: {theme.mode},
            onSelectionChanged: (s) => theme.setMode(s.first),
          ),
          const SizedBox(height: 24),
          Text('Data directory', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(_dataDir ?? '…', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          Text('Java', style: Theme.of(context).textTheme.titleSmall),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.coffee),
            title: const Text('Java runtimes'),
            subtitle: Text(_runtimeCount == null
                ? '…'
                : '$_runtimeCount detected'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JavaPage())),
          ),
        ],
      ),
    );
  }
}
