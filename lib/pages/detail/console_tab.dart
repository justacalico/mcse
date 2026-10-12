import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

class ConsoleTab extends StatefulWidget {
  final String serverId;
  const ConsoleTab({super.key, required this.serverId});

  @override
  State<ConsoleTab> createState() => _ConsoleTabState();
}

class _ConsoleTabState extends State<ConsoleTab> {
  final _command = TextEditingController();
  final _scroll = ScrollController();
  bool _atBottom = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients) {
        _atBottom = _scroll.position.pixels >=
            _scroll.position.maxScrollExtent - 24;
      }
    });
    context.read<AppState>().loadRecentLog(widget.serverId);
  }

  @override
  void dispose() {
    _command.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _command.text.trim();
    if (text.isEmpty) return;
    context.read<AppState>().sendCommand(widget.serverId, text);
    _command.clear();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final lines = app.logOf(widget.serverId);
    final online = app.instanceById(widget.serverId)?.isOnline ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_atBottom && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
    return Column(
      children: [
        Expanded(
          child: lines.isEmpty
              ? Center(
                  child:
                      Text(AppLocalizations.of(context).noConsoleOutput))
              : Container(
                  color: const Color(0xFF101216),
                  width: double.infinity,
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(8),
                    itemCount: lines.length,
                    itemBuilder: (context, i) => Text(
                      lines[i],
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 12,
                        color: Color(0xFFD7E0EA),
                      ),
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _command,
                  enabled: online,
                  style: const TextStyle(fontFamily: 'JetBrainsMono'),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).commandHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: AppLocalizations.of(context).send,
                icon: const Icon(Icons.send),
                onPressed: online ? _send : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
