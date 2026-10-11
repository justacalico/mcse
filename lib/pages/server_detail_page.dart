import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../backend/backend.dart';
import '../state/app_state.dart';
import '../widgets/status_chip.dart';

class ServerDetailPage extends StatelessWidget {
  final String serverId;

  const ServerDetailPage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final server = app.instanceById(serverId);
    if (server == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Server not found')),
      );
    }
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Flexible(
                child: Text(server.name, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 12),
              StatusChip(server.status),
            ],
          ),
          actions: [
            if (!server.isOnline)
              IconButton(
                tooltip: 'Start',
                icon: const Icon(Icons.play_arrow),
                onPressed: () => app.start(server.id),
              )
            else
              IconButton(
                tooltip: 'Stop',
                icon: const Icon(Icons.stop),
                onPressed:
                    server.isBusy ? null : () => app.stop(server.id),
              ),
            IconButton(
              tooltip: 'Kill',
              icon: const Icon(Icons.power_settings_new),
              onPressed:
                  server.isOnline ? () => app.kill(server.id) : null,
            ),
            IconButton(
              tooltip: 'Delete server',
              icon: const Icon(Icons.delete_outline),
              onPressed: server.isOnline
                  ? null
                  : () => _confirmDelete(context, app, server),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Console'),
              Tab(text: 'Properties'),
              Tab(text: 'Backups'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ConsoleTab(serverId: server.id),
            PropertiesTab(serverId: server.id),
            BackupsTab(serverId: server.id),
            ServerSettingsTab(server: server),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AppState app, ServerInstance server) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete server?'),
        content: Text(
            'This deletes "${server.name}" and all its files permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await app.delete(server.id);
                if (context.mounted) Navigator.of(context).pop();
              } catch (_) {}
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ------------------------- Console -------------------------

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
    final lines = context.watch<AppState>().logOf(widget.serverId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_atBottom && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
    return Column(
      children: [
        Expanded(
          child: lines.isEmpty
              ? const Center(child: Text('No console output yet.'))
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
                  style: const TextStyle(fontFamily: 'JetBrainsMono'),
                  decoration: const InputDecoration(
                    hintText: 'Enter a server command…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Send',
                icon: const Icon(Icons.send),
                onPressed: _send,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------- Properties -------------------------

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
          const SnackBar(content: Text('Properties saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Failed to load properties: $_error'));
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
            label: Text(_saving ? 'Saving…' : 'Save'),
            onPressed: _saving ? null : _save,
          ),
        ),
      ],
    );
  }
}

// ------------------------- Backups -------------------------

class BackupsTab extends StatefulWidget {
  final String serverId;
  const BackupsTab({super.key, required this.serverId});

  @override
  State<BackupsTab> createState() => _BackupsTabState();
}

class _BackupsTabState extends State<BackupsTab> {
  List<BackupInfo>? _backups;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list =
          await context.read<AppState>().backend.backups(widget.serverId);
      if (mounted) setState(() => _backups = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup failed: $e')),
    );
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      await context.read<AppState>().backend.createBackup(widget.serverId);
      await _load();
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(BackupInfo b) async {
    try {
      await context
          .read<AppState>()
          .backend
          .deleteBackup(widget.serverId, b.name);
      await _load();
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _restore(BackupInfo b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore backup?'),
        content: Text(
            'This stops the server and overwrites world data with ${b.name}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final backend = context.read<AppState>().backend;
    setState(() => _busy = true);
    try {
      await backend.restoreBackup(widget.serverId, b.name);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _backups == null) {
      return Center(child: Text('Failed to load backups: $_error'));
    }
    if (_backups == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton.icon(
            icon: const Icon(Icons.backup),
            label: Text(_busy ? 'Working…' : 'Create backup'),
            onPressed: _busy ? null : _create,
          ),
        ),
        Expanded(
          child: _backups!.isEmpty
              ? const Center(child: Text('No backups yet.'))
              : ListView(
                  children: [
                    for (final b in _backups!)
                      ListTile(
                        leading: const Icon(Icons.archive_outlined),
                        title: Text(b.name),
                        subtitle: Text(
                            '${(b.sizeBytes / 1048576).toStringAsFixed(1)} MB'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Restore',
                              icon: const Icon(Icons.restore),
                              onPressed: _busy ? null : () => _restore(b),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: _busy ? null : () => _delete(b),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ------------------------- Settings -------------------------

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
            const SnackBar(content: Text('Settings saved')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
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
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minRam,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min RAM (MB)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxRam,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max RAM (MB)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _jvmArgs,
          decoration: const InputDecoration(
            labelText: 'Extra JVM args',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: _javaPath,
          decoration: const InputDecoration(
            labelText: 'Java runtime',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Auto (best match)'),
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
                  child: Text('Java ${rt.major} — ${rt.path}',
                      overflow: TextOverflow.ellipsis),
                ),
          ],
          onChanged: (v) => setState(() => _javaPath = v),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.save),
          label: Text(_saving ? 'Saving…' : 'Save'),
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
