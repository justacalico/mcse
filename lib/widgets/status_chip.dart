import 'package:flutter/material.dart';

import '../backend/backend.dart';

class StatusChip extends StatelessWidget {
  final ServerStatus status;

  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ServerStatus.running => ('Running', Colors.green),
      ServerStatus.starting => ('Starting', Colors.amber),
      ServerStatus.stopping => ('Stopping', Colors.orange),
      ServerStatus.stopped => ('Stopped', Colors.grey),
      ServerStatus.crashed => ('Crashed', Colors.red),
    };
    return Chip(
      avatar: Icon(Icons.circle, size: 12, color: color),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}
