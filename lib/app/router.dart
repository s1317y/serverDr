import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_shell.dart';
import '../features/about/screens/about_screen.dart';
import '../features/browser/screens/web_browser_screen.dart';
import '../features/connections/screens/connection_editor_screen.dart';
import '../features/connections/screens/connections_screen.dart';
import '../features/editor/screens/editor_screen.dart';
import '../features/health/screens/health_active_screen.dart';
import '../features/health/screens/health_detail_screen.dart';
import '../features/health/screens/health_overview_screen.dart';
import '../features/health/screens/monitoring_settings_screen.dart';
import '../features/security/screens/security_screen.dart';
import '../features/settings/screens/known_hosts_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/sftp/models/remote_file.dart';
import '../features/sftp/screens/sftp_screen.dart';
import '../features/ssh/screens/terminal_screen.dart';
import '../features/transfers/screens/transfers_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/files',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/files', builder: (context, state) => const SftpScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/terminal', builder: (context, state) => const TerminalScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/web', builder: (context, state) => const WebBrowserScreen()),
        ]),
        StatefulShellBranch(routes: [
          // HEALTH tab = single active-server detail, auto-loads on open —
          // see HealthActiveScreen's doc. Distinct from MONITOR below.
          GoRoute(path: '/health', builder: (context, state) => const HealthActiveScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/security', builder: (context, state) => const SecurityScreen()),
        ]),
        StatefulShellBranch(routes: [
          // MONITOR tab = multi-server "Live Servers" dashboard with its
          // own explicit per-server opt-in (HealthOverviewScreen).
          GoRoute(path: '/monitor', builder: (context, state) => const HealthOverviewScreen()),
        ]),
      ],
    ),
    // Connections and Transfers are reached from the top bar (connection
    // pill / transfers icon), not bottom-nav destinations — always pushed
    // full-screen over whichever tab is active.
    GoRoute(
      path: '/connections',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ConnectionsScreen(),
      routes: [
        GoRoute(
          path: ':id/edit',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return ConnectionEditorScreen(connectionId: id == 'new' ? null : id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/transfers',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const TransfersScreen(),
    ),
    GoRoute(
      path: '/health/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => HealthDetailScreen(profileId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'settings',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => MonitoringSettingsScreen(profileId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/known-hosts',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const KnownHostsScreen(),
    ),
    GoRoute(
      path: '/editor',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => EditorScreen(entry: state.extra as RemoteFile),
    ),
    GoRoute(
      path: '/about',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AboutScreen(),
      routes: [
        GoRoute(path: 'credits', builder: (context, state) => const CreditsScreen()),
        GoRoute(path: 'donate', builder: (context, state) => const DonateScreen()),
      ],
    ),
  ],
);
