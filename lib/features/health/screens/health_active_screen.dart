import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/server_connection_sheet.dart';
import '../../connections/services/connection_repository.dart';
import 'health_detail_screen.dart';

/// The HEALTH bottom-nav tab: shows the detailed health view for
/// whichever server is currently active — auto-loads on open, same
/// behavior as before the Monitor split. Just a thin wrapper around
/// [HealthDetailScreen] that resolves "the active connection" instead of
/// requiring a specific profile id, since a bottom-nav tab has no route
/// parameter to carry one.
class HealthActiveScreen extends StatelessWidget {
  const HealthActiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ConnectionRepository>().activeConnection;
    if (active == null) {
      return Scaffold(
        appBar: AppTopBar(
          sectionLabel: 'Health',
          activeConnection: null,
          onTapConnectionPill: () => showServerConnectionSheet(context, null),
          onTapConnections: () => context.push('/connections'),
          onTapProfile: () => context.push('/settings'),
          onTapTransfers: () => context.push('/transfers'),
        ),
        body: const EmptyStateView(
          icon: Icons.dns_outlined,
          title: 'No server selected',
          subtitle: 'Pick a saved connection to view its health.',
        ),
      );
    }
    // HealthDetailScreen already renders its own AppBar (with a back
    // button when pushed standalone); that's fine here too — it's just
    // a normal AppBar, and this tab has nothing else to show around it.
    return HealthDetailScreen(profileId: active.id);
  }
}
