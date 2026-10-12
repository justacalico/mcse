import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import 'about_page.dart';
import 'create_page.dart';
import 'servers_page.dart';
import 'settings_page.dart';

/// Main navigation: Servers | Create | Settings | About.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  String? _shownError;
  final _serversNav = GlobalKey<NavigatorState>();

  void _select(int i) {
    if (i == 0 && _index == 0) {
      _serversNav.currentState?.popUntil((route) => route.isFirst);
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Navigator(
        key: _serversNav,
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => const ServersPage(),
        ),
      ),
      const CreatePage(),
      const SettingsPage(),
      const AboutPage(),
    ];
    final lastError = context.watch<AppState>().lastError;
    if (lastError != null && lastError != _shownError) {
      _shownError = lastError;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_shownError!)));
      });
    }
    final l10n = AppLocalizations.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final body = IndexedStack(index: _index, children: pages);
    return Scaffold(
      body: narrow
          ? body
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.dns_outlined),
                      selectedIcon: const Icon(Icons.dns),
                      label: Text(l10n.navServers),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.add_box_outlined),
                      selectedIcon: const Icon(Icons.add_box),
                      label: Text(l10n.navCreate),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings),
                      label: Text(l10n.navSettings),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.info_outline),
                      selectedIcon: const Icon(Icons.info),
                      label: Text(l10n.navAbout),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
      bottomNavigationBar: narrow
          ? NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dns_outlined),
                  selectedIcon: const Icon(Icons.dns),
                  label: l10n.navServers,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.add_box_outlined),
                  selectedIcon: const Icon(Icons.add_box),
                  label: l10n.navCreate,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: l10n.navSettings,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.info_outline),
                  selectedIcon: const Icon(Icons.info),
                  label: l10n.navAbout,
                ),
              ],
            )
          : null,
    );
  }
}
