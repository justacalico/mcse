import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../state/dirs_state.dart';
import '../state/locale_state.dart';
import '../state/theme_state.dart';
import 'java_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.pickDirectory = getDirectoryPath});

  final Future<String?> Function() pickDirectory;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int? _runtimeCount;
  String? _dataDir;
  String? _javaDir;
  String? _backupsDir;

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
    backend
        .javaDir()
        .then((d) {
          if (mounted) setState(() => _javaDir = d);
        })
        .catchError((_) {
          if (mounted) setState(() => _javaDir = '?');
        });
    backend
        .backupsDir()
        .then((d) {
          if (mounted) setState(() => _backupsDir = d);
        })
        .catchError((_) {
          if (mounted) setState(() => _backupsDir = '?');
        });
  }

  Future<void> _editDir({
    required String title,
    required String? effective,
    required String? pending,
    required Future<void> Function(String?) save,
  }) async {
    final l10n = AppLocalizations.of(context);
    final saved = await showDialog<String>(
      context: context,
      builder: (_) => _DirEditDialog(
        title: title,
        effective: effective,
        pending: pending,
        pickDirectory: widget.pickDirectory,
      ),
    );
    if (saved == null) return;
    await save(saved);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.settingsSaved)));
    }
  }

  Widget _dirTile({
    required String title,
    required String? effective,
    required String? pending,
    required Future<void> Function(String?) save,
  }) {
    final l10n = AppLocalizations.of(context);
    final subtitle = pending != null && pending != effective
        ? '$pending (${l10n.dirPendingRestart})'
        : (effective ?? '…');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.folder_outlined),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () => _editDir(
        title: title,
        effective: effective,
        pending: pending,
        save: save,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final locale = context.watch<LocaleState>();
    final dirs = context.watch<DirsState>();
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
          Text(l10n.storageTitle,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _dirTile(
            title: l10n.dataDir,
            effective: _dataDir,
            pending: dirs.dataDir,
            save: dirs.setDataDir,
          ),
          _dirTile(
            title: l10n.javaDir,
            effective: _javaDir,
            pending: dirs.javaDir,
            save: dirs.setJavaDir,
          ),
          _dirTile(
            title: l10n.backupsDir,
            effective: _backupsDir,
            pending: dirs.backupsDir,
            save: dirs.setBackupsDir,
          ),
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

class _DirEditDialog extends StatefulWidget {
  const _DirEditDialog({
    required this.title,
    required this.effective,
    required this.pending,
    required this.pickDirectory,
  });

  final String title;
  final String? effective;
  final String? pending;
  final Future<String?> Function() pickDirectory;

  @override
  State<_DirEditDialog> createState() => _DirEditDialogState();
}

class _DirEditDialogState extends State<_DirEditDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.pending ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: widget.effective,
            ),
            onSubmitted: (v) => Navigator.of(context).pop(v),
          ),
          const SizedBox(height: 8),
          Text(l10n.dirDialogHint,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_open),
            label: Text(l10n.browseDir),
            onPressed: () async {
              final dir = await widget.pickDirectory();
              if (dir != null) _controller.text = dir;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(''),
          child: Text(l10n.useDefaultDir),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
