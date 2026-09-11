import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';

/// Wraps the 5-tab bottom navigation from every Stitch screen footer:
/// FILES / TERMINAL / WEB / TRANSFERS / SETTINGS.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          backgroundColor: AppColors.surfaceContainer,
          indicatorColor: AppColors.primary.withValues(alpha: 0.16),
          height: 60,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Files'),
            NavigationDestination(icon: Icon(Icons.terminal_outlined), selectedIcon: Icon(Icons.terminal), label: 'Terminal'),
            NavigationDestination(icon: Icon(Icons.public_outlined), selectedIcon: Icon(Icons.public), label: 'Web'),
            NavigationDestination(icon: Icon(Icons.swap_vert), selectedIcon: Icon(Icons.swap_vert_circle), label: 'Transfers'),
            NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
