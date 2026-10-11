import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../backend/backend.dart';
import '../state/app_state.dart';
import '../state/theme_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<JavaRuntimeInfo>? _runtimes;
  String? _dataDir;
  int? _installing;

  @override
  void initState() {
    super.initState();
    final backend = context.read<AppState>().backend;
    backend.javaRuntimes().then((r) {
      if (mounted) setState(() => _runtimes = r);
    }).catchError((_) {
      if (mounted) setState(() => _runtimes = const []);
    });
    backend.dataDir().then((d) {
      if (mounted) setState(() => _dataDir = d);
    }).catchError((_) {
      if (mounted) setState(() => _dataDir = '?');
    });
  }

  Future<void> _installJava(int feature) async {
    final backend = context.read<AppState>().backend;
    setState(() => _installing = feature);
    try {
      await backend.installJava(feature);
      final r = await backend.javaRuntimes();
      if (mounted) setState(() => _runtimes = r);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Java install failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _installing = null);
    }
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
          Text('Data directory',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(_dataDir ?? '…',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Java runtimes',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              for (final feature in const [8, 17, 21])
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _installing == feature
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: _installing != null
                              ? null
                              : () => _installJava(feature),
                          child: Text('Install $feature'),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_runtimes == null)
            const Center(child: CircularProgressIndicator())
          else if (_runtimes!.isEmpty)
            const Text('No Java runtimes found.')
          else
            for (final rt in _runtimes!)
              ListTile(
                dense: true,
                leading: const Icon(Icons.coffee),
                title: Text('Java ${rt.major} — ${rt.version}'),
                subtitle: Text(rt.path, overflow: TextOverflow.ellipsis),
              ),
        ],
      ),
    );
  }
}
