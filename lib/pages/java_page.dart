import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../backend/backend.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

/// Java download manager: every feature release Adoptium offers, install
/// progress, and the runtimes already on the system.
class JavaPage extends StatefulWidget {
  const JavaPage({super.key});

  @override
  State<JavaPage> createState() => _JavaPageState();
}

class _JavaPageState extends State<JavaPage> {
  List<JavaRuntimeInfo>? _runtimes;
  List<JavaReleaseInfo>? _releases;
  Object? _releasesError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final backend = context.read<AppState>().backend;
    backend.javaRuntimes().then((r) {
      if (mounted) setState(() => _runtimes = r);
    }).catchError((_) {
      if (mounted) setState(() => _runtimes = const []);
    });
    await _loadReleases();
  }

  Future<void> _loadReleases() async {
    final backend = context.read<AppState>().backend;
    try {
      final r = await backend.javaReleases();
      if (mounted) {
        setState(() {
          _releases = r;
          _releasesError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _releasesError = e);
    }
  }

  Future<void> _refreshRuntimes() async {
    try {
      final r = await context.read<AppState>().backend.javaRuntimes();
      if (mounted) setState(() => _runtimes = r);
    } catch (_) {}
  }

  Future<void> _install(int feature) async {
    final state = context.read<AppState>();
    try {
      await state.backend.installJava(feature);
      await _refreshRuntimes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).javaInstallFailed('$e'))),
        );
      }
    } finally {
      state.finishJavaDownload(feature);
    }
  }

  Future<void> _remove(int feature) async {
    final backend = context.read<AppState>().backend;
    try {
      await backend.removeJava(feature);
      await _refreshRuntimes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).javaRemoveFailed('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<AppState>().javaDownloads;
    final installed = {
      for (final rt in _runtimes ?? const <JavaRuntimeInfo>[])
        if (rt.managed) rt.major,
    };
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.javaTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.downloads,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_releases == null && _releasesError == null)
            const Center(child: CircularProgressIndicator())
          else if (_releasesError != null)
            Row(
              children: [
                Expanded(
                  child: Text(l10n.releasesLoadFailed,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                TextButton(
                    onPressed: _loadReleases, child: Text(l10n.retry)),
              ],
            )
          else
            for (final rel in _releases!)
              _releaseTile(
                  rel, downloads[rel.feature], installed.contains(rel.feature)),
          const SizedBox(height: 24),
          Text(l10n.detectedRuntimes,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_runtimes == null)
            const Center(child: CircularProgressIndicator())
          else if (_runtimes!.isEmpty)
            Text(l10n.noRuntimes)
          else
            for (final rt in _runtimes!) _runtimeTile(rt),
        ],
      ),
    );
  }

  Widget _releaseTile(
      JavaReleaseInfo rel, JavaProgress? progress, bool installed) {
    Widget trailing;
    if (progress != null) {
      trailing = SizedBox(
        width: 150,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            LinearProgressIndicator(value: progress.fraction),
            const SizedBox(height: 4),
            Text(_progressLabel(AppLocalizations.of(context), progress),
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
    } else if (installed) {
      trailing = Text(AppLocalizations.of(context).installed,
          style: Theme.of(context).textTheme.bodySmall);
    } else {
      trailing = TextButton(
        onPressed: () => _install(rel.feature),
        child: Text(AppLocalizations.of(context).install),
      );
    }
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Text(AppLocalizations.of(context).javaFeature(rel.feature)),
          if (rel.lts)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child:
                  Text('LTS', style: Theme.of(context).textTheme.labelSmall),
            ),
        ],
      ),
      trailing: trailing,
    );
  }

  Widget _runtimeTile(JavaRuntimeInfo rt) => ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.coffee),
        title: Text(AppLocalizations.of(context)
            .javaRuntimeVersion(rt.major, rt.version)),
        subtitle: Text(rt.path, overflow: TextOverflow.ellipsis),
        trailing: rt.managed
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: AppLocalizations.of(context).remove,
                onPressed: () => _remove(rt.major),
              )
            : null,
      );

  String _progressLabel(AppLocalizations l10n, JavaProgress p) {
    if (p.stage == 'extract') return l10n.extracting;
    final mb = (p.received / 1048576).toStringAsFixed(0);
    final total = p.total;
    if (total == null || total == 0) return l10n.javaProgressMb(mb);
    return l10n.javaProgressTotal(
        mb, (total / 1048576).toStringAsFixed(0));
  }
}
