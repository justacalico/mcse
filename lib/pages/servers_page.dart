import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/server_card.dart';

class ServersPage extends StatelessWidget {
  const ServersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pending = app.creating.entries.toList();
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).navServers)),
      body: RefreshIndicator(
        onRefresh: app.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (pending.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    for (final entry in pending)
                      _CreatingTile(
                        id: entry.key,
                        progress: entry.value,
                      ),
                  ],
                ),
              ),
            if (app.instances.isEmpty && pending.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.dns_outlined, size: 64),
                      const SizedBox(height: 12),
                      Text(AppLocalizations.of(context).noServersYet),
                      Text(AppLocalizations.of(context).noServersHint),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    mainAxisExtent: 150,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ServerCard(app.instances[i]),
                    childCount: app.instances.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CreatingTile extends StatelessWidget {
  final String id;
  final CreateProgress progress;

  const _CreatingTile({required this.id, required this.progress});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.failed
                        ? l10n.createFailed
                        : l10n.creatingServer,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (progress.failed)
                  TextButton(
                    onPressed: () => app.dismissCreate(id),
                    child: Text(l10n.dismiss),
                  ),
              ],
            ),
            if (progress.failed)
              Text(progress.error ?? l10n.unknownError,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error))
            else ...[
              LinearProgressIndicator(value: progress.fraction),
              const SizedBox(height: 4),
              Text(
                progress.installLines.isNotEmpty
                    ? progress.installLines.last
                    : _downloadLabel(l10n, progress),
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _downloadLabel(AppLocalizations l10n, CreateProgress p) {
    final received = (p.received / 1048576).toStringAsFixed(1);
    if (p.total != null && p.total! > 0) {
      final total = (p.total! / 1048576).toStringAsFixed(1);
      return l10n.downloadingProgress(received, total);
    }
    return l10n.downloadingSimple(received);
  }
}
