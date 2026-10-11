import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    const pages = [
      ServersPage(),
      CreatePage(),
      SettingsPage(),
      AboutPage(),
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
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dns_outlined),
                selectedIcon: Icon(Icons.dns),
                label: Text('Servers'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_box_outlined),
                selectedIcon: Icon(Icons.add_box),
                label: Text('Create'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.info_outline),
                selectedIcon: Icon(Icons.info),
                label: Text('About'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ],
      ),
    );
  }
}
