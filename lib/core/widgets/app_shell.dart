import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Final bottom navigation: FILES / TERMINAL / WEB / HEALTH / SECURITY /
/// MONITOR — exactly 6 primary destinations.
///
/// HEALTH here means the single-server detail view for whichever server
/// is currently active (auto-loads on open, like Terminal/Files did
/// before the connection-state work — no "Connect" gate, since Health
/// just runs a read-only command and doesn't need an interactive
/// session). MONITOR is the separate multi-server "Live Servers"
/// dashboard with its own explicit opt-in per server.
///
/// Connections is reached via the top-bar connection pill (see
/// AppTopBar/ServerConnectionSheet), not a bottom tab — this app only has
/// 6 bottom-nav slots and Health+Security+Monitor all need one.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          height: 60,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Files'),
            NavigationDestination(icon: Icon(Icons.terminal_outlined), selectedIcon: Icon(Icons.terminal), label: 'Terminal'),
            NavigationDestination(icon: Icon(Icons.public_outlined), selectedIcon: Icon(Icons.public), label: 'Web'),
            NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Health'),
            NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Security'),
            NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), selectedIcon: Icon(Icons.monitor_heart), label: 'Monitor'),
          ],
        ),
      ),
    );
  }
}
