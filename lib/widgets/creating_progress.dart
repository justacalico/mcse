import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

/// Progress display for an in-flight instance creation — shown as a tile
/// on the servers page and inside a dialog on the create page.
class CreatingProgress extends StatelessWidget {
  final String id;
  final CreateProgress progress;

  const CreatingProgress(
      {super.key, required this.id, required this.progress});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                progress.failed ? l10n.createFailed : l10n.creatingServer,
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
              style:
                  TextStyle(color: Theme.of(context).colorScheme.error))
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
