import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

class PropertiesTab extends StatefulWidget {
  final String serverId;
  const PropertiesTab({super.key, required this.serverId});

  @override
  State<PropertiesTab> createState() => _PropertiesTabState();
}

class _PropertiesTabState extends State<PropertiesTab> {
  Map<String, String>? _props;
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;
  String? _error;

  static const _fields = [
    'server-port',
    'motd',
    'max-players',
    'online-mode',
    'difficulty',
    'gamemode',
    'pvp',
    'spawn-protection',
    'view-distance',
    'simulation-distance',
    'white-list',
    'enable-command-block',
  ];

  @override
  void initState() {
    super.initState();
    context
        .read<AppState>()
        .backend
        .properties(widget.serverId)
        .then((props) {
      if (!mounted) return;
      setState(() {
        _props = props;
        for (final e in props.entries) {
          _controllers[e.key] = TextEditingController(text: e.value);
        }
      });
    }).catchError((Object e) {
      if (mounted) setState(() => _error = e.toString());
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final changes = {
        for (final e in _controllers.entries)
          if (e.value.text != _props?[e.key]) e.key: e.value.text,
      };
      await context
          .read<AppState>()
          .backend
          .setProperties(widget.serverId, changes);
      if (mounted) setState(() => _props = {...?_props, ...changes});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).propertiesSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saveFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
          child:
              Text(AppLocalizations.of(context).propsLoadFailed(_error!)));
    }
    if (_props == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final keys = [
      ..._fields.where((k) => _props!.containsKey(k)),
      ..._props!.keys.where((k) => !_fields.contains(k)),
    ];
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final key in keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _controllers[key],
                    decoration: InputDecoration(
                      labelText: key,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton.icon(
            icon: const Icon(Icons.save),
            label: Text(_saving
                ? AppLocalizations.of(context).saving
                : AppLocalizations.of(context).save),
            onPressed: _saving ? null : _save,
          ),
        ),
      ],
    );
  }
}
