import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../backend/backend.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

/// Wizard: pick a loader → pick a game version → name + memory → create.
class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final _name = TextEditingController();
  final _motd = TextEditingController();
  bool _motdInit = false;
  final _port = TextEditingController(text: '25565');
  List<LoaderInfo>? _loaders;
  List<GameVersionInfo>? _versions;
  String? _loader;
  String? _version;
  bool _eula = false;
  final _eulaLink = TapGestureRecognizer()
    ..onTap = () => launchUrl(
        Uri.parse('https://aka.ms/MinecraftEULA'));
  double _ram = 4096;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    context.read<AppState>().backend.loaders().then((l) {
      if (mounted) setState(() => _loaders = l);
    }).catchError((Object e) {
      if (mounted) setState(() => _error = e.toString());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_motdInit) {
      _motdInit = true;
      _motd.text = AppLocalizations.of(context).defaultMotd;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _motd.dispose();
    _port.dispose();
    _eulaLink.dispose();
    super.dispose();
  }

  Future<void> _pickLoader(String kind) async {
    setState(() {
      _loader = kind;
      _version = null;
      _versions = null;
    });
    try {
      final versions =
          await context.read<AppState>().backend.gameVersions(kind);
      if (mounted && _loader == kind) {
        setState(() => _versions = versions);
      }
    } catch (e) {
      if (mounted && _loader == kind) {
        setState(() {
          _versions = const [];
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _create() async {
    final backend = context.read<AppState>().backend;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await backend.createInstance(CreateRequest(
        name: _name.text.trim().isEmpty
            ? AppLocalizations.of(context).defaultServerName
            : _name.text.trim(),
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
    final l10n = AppLocalizations.of(context);
    final canCreate =
        _loader != null && _version != null && _eula && !_submitting;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createServerTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.loader, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_loaders == null)
            _error == null
                ? const Center(child: CircularProgressIndicator())
                : Text(l10n.loadersFailed(_error!),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error))
          else
            DropdownButtonFormField<String>(
              initialValue: _loader,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.selectLoader,
              ),
              items: [
                for (final l in _loaders!)
                  DropdownMenuItem(value: l.kind, child: Text(l.label)),
              ],
              onChanged: (v) {
                if (v != null) _pickLoader(v);
              },
            ),
          const SizedBox(height: 24),
          Text(l10n.version, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_loader != null && _versions == null)
            const Center(child: CircularProgressIndicator())
          else
            DropdownButtonFormField<String>(
              initialValue: _version,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.selectGameVersion,
              ),
              items: [
                for (final v in _versions ?? <GameVersionInfo>[])
                  DropdownMenuItem(value: v.id, child: Text(v.id)),
              ],
              onChanged: (v) => setState(() => _version = v),
            ),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: l10n.serverName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.memoryMb('${_ram.round()}')),
          Slider(
            value: _ram,
            min: 512,
            max: 16384,
            divisions: 31,
            label: l10n.sizeMb('${_ram.round()}'),
            onChanged: (v) => setState(() => _ram = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _motd,
            decoration: InputDecoration(
              labelText: l10n.motd,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _port,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.port,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _eula,
            onChanged: (v) => setState(() => _eula = v ?? false),
            title: Text(l10n.acceptEula),
            subtitle: Text.rich(
              TextSpan(
                text: l10n.eulaRequired,
                children: [
                  TextSpan(
                    text: 'https://aka.ms/MinecraftEULA',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    mouseCursor: SystemMouseCursors.click,
                    recognizer: _eulaLink,
                  ),
                ],
              ),
            ),
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
            label: Text(_submitting ? l10n.creating : l10n.createServerTitle),
            onPressed: canCreate ? _create : null,
          ),
        ],
      ),
    );
  }
}
