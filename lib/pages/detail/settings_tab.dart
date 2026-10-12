import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../backend/backend.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

class ServerSettingsTab extends StatefulWidget {
  final ServerInstance server;
  const ServerSettingsTab({super.key, required this.server});

  @override
  State<ServerSettingsTab> createState() => _ServerSettingsTabState();
}

class _ServerSettingsTabState extends State<ServerSettingsTab> {
  late final TextEditingController _name;
  late final TextEditingController _minRam;
  late final TextEditingController _maxRam;
  late final TextEditingController _jvmArgs;
  List<JavaRuntimeInfo>? _runtimes;
  String? _javaPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.server;
    _name = TextEditingController(text: s.name);
    _minRam = TextEditingController(text: '${s.minRamMb}');
    _maxRam = TextEditingController(text: '${s.maxRamMb}');
    _jvmArgs = TextEditingController(text: s.jvmArgs.join(' '));
    _javaPath = s.javaPath;
    context.read<AppState>().backend.javaRuntimes().then((rts) {
      if (mounted) setState(() => _runtimes = rts);
    }).catchError((_) {
      if (mounted) setState(() => _runtimes = const []);
    });
  }

  @override
  void didUpdateWidget(covariant ServerSettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.server != widget.server) {
      final s = widget.server;
      _name.text = s.name;
      _minRam.text = '${s.minRamMb}';
      _maxRam.text = '${s.maxRamMb}';
      _jvmArgs.text = s.jvmArgs.join(' ');
      _javaPath = s.javaPath;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _minRam.dispose();
    _maxRam.dispose();
    _jvmArgs.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    setState(() => _saving = true);
    try {
      await app.backend.updateInstance(
            widget.server.id,
            name: _name.text,
            minRamMb: int.tryParse(_minRam.text),
            maxRamMb: int.tryParse(_maxRam.text),
            jvmArgs: _jvmArgs.text
                .split(RegExp(r'\s+'))
                .where((a) => a.isNotEmpty)
                .toList(),
            javaPath: _javaPath,
          );
      if (mounted) {
        await app.refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(AppLocalizations.of(context).settingsSaved)),
          );
        }
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).nameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minRam,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).minRam,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxRam,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).maxRam,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _jvmArgs,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).jvmArgs,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: _javaPath,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).javaRuntime,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(AppLocalizations.of(context).javaAuto),
            ),
            if (_javaPath != null &&
                (_runtimes ?? const []).every((r) => r.path != _javaPath))
              DropdownMenuItem<String?>(
                value: _javaPath,
                child: Text(_javaPath!,
                    overflow: TextOverflow.ellipsis),
              ),
            if (_runtimes != null)
              for (final rt in _runtimes!)
                DropdownMenuItem<String?>(
                  value: rt.path,
                  child: Text(
                      AppLocalizations.of(context)
                          .javaRuntimePath(rt.major, rt.path),
                      overflow: TextOverflow.ellipsis),
                ),
          ],
          onChanged: (v) => setState(() => _javaPath = v),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.save),
          label: Text(_saving
              ? AppLocalizations.of(context).saving
              : AppLocalizations.of(context).save),
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
