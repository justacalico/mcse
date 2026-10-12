import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/version_checker.dart';
import '../state/update_state.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String? _version;
  bool _checking = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    context.read<UpdateState>().currentVersion().then((v) {
      if (mounted) setState(() => _version = v);
    }).catchError((_) {
      if (mounted) setState(() => _version = '?');
    });
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _feedback = null;
    });
    final result = await context.read<UpdateState>().check();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _checking = false;
      if (result == null) {
        _feedback = l10n.checkFailed;
      } else if (result.updateAvailable) {
        _feedback = l10n.updateAvailable(result.latestVersion);
      } else {
        _feedback = l10n.upToDate;
      }
    });
    if (result?.releaseUrl.isNotEmpty == true &&
        result!.updateAvailable) {
      launchUrl(Uri.parse(result.releaseUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final update = context.watch<UpdateState>().update;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAbout)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Image.asset('assets/icon.png', width: 64, height: 64),
          const SizedBox(height: 12),
          Text('mcse',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          Text(
            l10n.aboutTagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.tag),
            title: Text(l10n.version),
            subtitle: Text(_version ?? '…'),
          ),
          ListTile(
            leading: _checking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.system_update_alt),
            title: Text(l10n.checkForUpdates),
            subtitle: Text(_feedback ??
                (update?.updateAvailable == true
                    ? l10n.updateAvailable(update!.latestVersion)
                    : l10n.checkReleasesHint)),
            onTap: _checking ? null : _check,
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(l10n.sourceCode),
            subtitle: const Text(VersionChecker.repoUrl),
            onTap: () =>
                launchUrl(Uri.parse(VersionChecker.repoUrl)),
          ),
        ],
      ),
    );
  }
}
