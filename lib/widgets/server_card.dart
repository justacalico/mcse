import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../backend/backend.dart';
import '../l10n/app_localizations.dart';
import '../pages/server_detail_page.dart';
import '../state/app_state.dart';
import 'status_chip.dart';

class ServerCard extends StatelessWidget {
  final ServerInstance server;

  const ServerCard(this.server, {super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final l10n = AppLocalizations.of(context);
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServerDetailPage(serverId: server.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      server.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip(server.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${server.loader} · ${server.gameVersion}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Row(
                children: [
                  if (!server.isOnline)
                    IconButton.filled(
                      tooltip: l10n.start,
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () => app.start(server.id),
                    )
                  else
                    IconButton.filled(
                      tooltip: l10n.stop,
                      icon: const Icon(Icons.stop),
                      onPressed: server.isBusy
                          ? null
                          : () => app.stop(server.id),
                    ),
                  if (server.isOnline) ...[
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: l10n.restart,
                      icon: const Icon(Icons.restart_alt),
                      onPressed:
                          server.isBusy ? null : () => app.restart(server.id),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
