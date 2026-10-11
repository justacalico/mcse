import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../backend/backend.dart';
import '../state/app_state.dart';

/// Wizard: pick a loader → pick a game version → name + memory → create.
class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final _name = TextEditingController();
  final _motd = TextEditingController(text: 'A Minecraft Server');
  final _port = TextEditingController(text: '25565');
  List<LoaderInfo>? _loaders;
  List<GameVersionInfo>? _versions;
  String? _loader;
  String? _version;
  bool _stableOnly = true;
  bool _eula = false;
  double _ram = 4096;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    context.read<AppState>().backend.loaders().then((l) {
      if (mounted) setState(() => _loaders = l);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _motd.dispose();
    _port.dispose();
    super.dispose();
  }

  Future<void> _pickLoader(String kind) async {
    setState(() {
      _loader = kind;
      _version = null;
      _versions = null;
    });
    final versions =
        await context.read<AppState>().backend.gameVersions(kind);
    if (mounted && _loader == kind) {
      setState(() => _versions = versions);
    }
  }

  Iterable<GameVersionInfo> get _shown =>
      (_versions ?? []).where((v) => !_stableOnly || v.stable);

  Future<void> _create() async {
    final backend = context.read<AppState>().backend;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await backend.createInstance(CreateRequest(
        name: _name.text.trim().isEmpty ? 'Minecraft Server' : _name.text.trim(),
        loader: _loader!,
        gameVersion: _version!,
        minRamMb: _ram ~/ 2,
        maxRamMb: _ram.round(),
        properties: {
          'motd': _motd.text,
          'server-port': _port.text,
        },
      ));
      if (mounted) setState(() => _submitting = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreate =
        _loader != null && _version != null && _eula && !_submitting;
    return Scaffold(
      appBar: AppBar(title: const Text('Create server')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Loader', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_loaders == null)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final l in _loaders!)
                  ChoiceChip(
                    label: Text(l.label),
                    selected: _loader == l.kind,
                    onSelected: (_) => _pickLoader(l.kind),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Version',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              FilterChip(
                label: const Text('Releases only'),
                selected: _stableOnly,
                onSelected: (v) => setState(() => _stableOnly = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loader != null && _versions == null)
            const Center(child: CircularProgressIndicator())
          else
            DropdownButtonFormField<String>(
              initialValue: _version,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select a game version',
              ),
              items: [
                for (final v in _shown)
                  DropdownMenuItem(value: v.id, child: Text(v.id)),
              ],
              onChanged: (v) => setState(() => _version = v),
            ),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Server name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Memory: ${_ram.round()} MB'),
          Slider(
            value: _ram,
            min: 512,
            max: 16384,
            divisions: 31,
            label: '${_ram.round()} MB',
            onChanged: (v) => setState(() => _ram = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _motd,
            decoration: const InputDecoration(
              labelText: 'MOTD',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _port,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Port',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _eula,
            onChanged: (v) => setState(() => _eula = v ?? false),
            title: const Text('I accept the Minecraft EULA'),
            subtitle: const Text(
                'Required to run a server — see https://aka.ms/MinecraftEULA'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.rocket_launch),
            label: Text(_submitting ? 'Creating…' : 'Create server'),
            onPressed: canCreate ? _create : null,
          ),
        ],
      ),
    );
  }
}
