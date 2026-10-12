import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../backend/backend.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

class BackupsTab extends StatefulWidget {
  final String serverId;
  const BackupsTab({super.key, required this.serverId});

  @override
  State<BackupsTab> createState() => _BackupsTabState();
}

class _BackupsTabState extends State<BackupsTab> {
  List<BackupInfo>? _backups;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list =
          await context.read<AppState>().backend.backups(widget.serverId);
      if (mounted) setState(() => _backups = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context).backupFailed('$e'))),
    );
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      await context.read<AppState>().backend.createBackup(widget.serverId);
      await _load();
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(BackupInfo b) async {
    try {
      await context
          .read<AppState>()
          .backend
          .deleteBackup(widget.serverId, b.name);
      await _load();
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _restore(BackupInfo b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(l10n.restoreTitle),
          content: Text(l10n.restoreBody(b.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.restore),
            ),
          ],
        );
      },
    );
    if (confirm != true || !mounted) return;
    final backend = context.read<AppState>().backend;
    setState(() => _busy = true);
    try {
      await backend.restoreBackup(widget.serverId, b.name);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _backups == null) {
      return Center(
          child:
              Text(AppLocalizations.of(context).backupsLoadFailed(_error!)));
    }
    if (_backups == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: FilledButton.icon(
                  icon: const Icon(Icons.backup),
                  label: Text(_busy
                      ? AppLocalizations.of(context).working
                      : AppLocalizations.of(context).createBackup),
                  onPressed: _busy ? null : _create,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _backups!.isEmpty
              ? Center(child: Text(AppLocalizations.of(context).noBackups))
              : ListView(
                  children: [
                    for (final b in _backups!)
                      ListTile(
                        leading: const Icon(Icons.archive_outlined),
                        title: Text(b.name),
                        subtitle: Text(
                            AppLocalizations.of(context).sizeMb(
                                (b.sizeBytes / 1048576)
                                    .toStringAsFixed(1))),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: AppLocalizations.of(context).restore,
                              icon: const Icon(Icons.restore),
                              onPressed: _busy ? null : () => _restore(b),
                            ),
                            IconButton(
                              tooltip: AppLocalizations.of(context).delete,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: _busy ? null : () => _delete(b),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
