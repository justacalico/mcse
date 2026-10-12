import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
    setState(() {
      _checking = false;
      if (result == null) {
        _feedback = 'Check failed';
      } else if (result.updateAvailable) {
        _feedback = 'Update available: ${result.latestVersion}';
      } else {
        _feedback = 'Up to date';
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
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Image.asset('assets/icon.png', width: 64, height: 64),
          const SizedBox(height: 12),
          Text('mcse',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          Text(
            'Minecraft Java Edition server manager',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.tag),
            title: const Text('Version'),
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
            title: const Text('Check for updates'),
            subtitle: Text(_feedback ??
                (update?.updateAvailable == true
                    ? 'Update available: ${update!.latestVersion}'
                    : 'Check GitLab releases for a new version')),
            onTap: _checking ? null : _check,
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Source code'),
            subtitle: const Text(VersionChecker.repoUrl),
            onTap: () =>
                launchUrl(Uri.parse(VersionChecker.repoUrl)),
          ),
        ],
      ),
    );
  }
}
