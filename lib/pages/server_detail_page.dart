import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../backend/backend.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/status_chip.dart';
import 'detail/backups_tab.dart';
import 'detail/console_tab.dart';
import 'detail/properties_tab.dart';
import 'detail/settings_tab.dart';

class ServerDetailPage extends StatelessWidget {
  final String serverId;

  const ServerDetailPage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final server = app.instanceById(serverId);
    if (server == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
            child: Text(AppLocalizations.of(context).serverNotFound)),
      );
    }
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Flexible(
                child: Text(server.name, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 12),
              StatusChip(server.status),
            ],
          ),
          actions: [
            if (!server.isOnline)
              IconButton(
                tooltip: l10n.start,
                icon: const Icon(Icons.play_arrow),
                onPressed: () => app.start(server.id),
              )
            else
              IconButton(
                tooltip: l10n.stop,
                icon: const Icon(Icons.stop),
                onPressed:
                    server.isBusy ? null : () => app.stop(server.id),
              ),
            IconButton(
              tooltip: l10n.kill,
              icon: const Icon(Icons.power_settings_new),
              onPressed:
                  server.isOnline ? () => app.kill(server.id) : null,
            ),
            IconButton(
              tooltip: l10n.deleteServerTooltip,
              icon: const Icon(Icons.delete_outline),
              onPressed: server.isOnline
                  ? null
                  : () => _confirmDelete(context, app, server),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.tabConsole),
              Tab(text: l10n.tabProperties),
              Tab(text: l10n.tabBackups),
              Tab(text: l10n.navSettings),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ConsoleTab(serverId: server.id),
            PropertiesTab(serverId: server.id),
            BackupsTab(serverId: server.id),
            ServerSettingsTab(server: server),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AppState app, ServerInstance server) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(l10n.deleteServerTitle),
          content: Text(l10n.deleteServerBody(server.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await app.delete(server.id);
                  if (context.mounted) Navigator.of(context).pop();
                } catch (_) {}
              },
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }
}
