import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/creating_progress.dart';
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
                      Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CreatingProgress(
                            id: entry.key,
                            progress: entry.value,
                          ),
                        ),
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
