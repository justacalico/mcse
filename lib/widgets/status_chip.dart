import 'package:flutter/material.dart';

import '../backend/backend.dart';
import '../l10n/app_localizations.dart';

class StatusChip extends StatelessWidget {
  final ServerStatus status;

  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (status) {
      ServerStatus.running => (l10n.statusRunning, Colors.green),
      ServerStatus.starting => (l10n.statusStarting, Colors.amber),
      ServerStatus.stopping => (l10n.statusStopping, Colors.orange),
      ServerStatus.stopped => (l10n.statusStopped, Colors.grey),
      ServerStatus.crashed => (l10n.statusCrashed, Colors.red),
    };
    return Chip(
      avatar: Icon(Icons.circle, size: 12, color: color),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}
