import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/relative_time.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../connections/models/connection_profile.dart';
import '../../connections/models/server_connection_state.dart';
import '../../connections/services/connection_repository.dart';
import '../../connections/services/server_connection_manager.dart';
import '../../ssh/widgets/host_key_verification_dialog.dart';
import '../models/health_status.dart';
import '../models/monitoring_config.dart';
import '../services/health_monitor_service.dart';

/// The MONITOR TAB — "Live Servers": every server with monitoring
/// enabled, each showing its calculated status and key metrics. This is
/// intentionally different from the HEALTH tab (single active server,
/// full detail, auto-loads) — Monitor tracks multiple servers at once,
/// each opted in explicitly via "Add Monitoring" below or from a
/// specific server's own Health detail screen. Tapping a card here opens
/// that server's full [HealthDetailScreen].
///
/// A saved server only appears here if its [MonitoringConfig.enabled] is
/// true — being saved, or even being the "active" connection elsewhere in
/// the app, does not imply monitoring.
class HealthOverviewScreen extends StatefulWidget {
  const HealthOverviewScreen({super.key});

  @override
  State<HealthOverviewScreen> createState() => _HealthOverviewScreenState();
}

class _HealthOverviewScreenState extends State<HealthOverviewScreen> {
  bool _monitoringStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_monitoringStarted) return;
    _monitoringStarted = true;
    // Resume monitoring for any server enabled in a previous session.
    // See HealthMonitorService's doc for the real Android background
    // limitation this is subject to — this only runs while the app is
    // alive, starting from when this screen is first opened.
    final repo = context.read<ConnectionRepository>();
    final configStore = context.read<MonitoringConfigStore>();
    final monitor = context.read<HealthMonitorService>();
    for (final profile in repo.connections) {
      final config = configStore.get(profile.id);
      if (config.enabled) {
        monitor.applyConfig(profile, config, onHostKeyVerification: (r) => showHostKeyVerificationDialog(context, r));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ConnectionRepository>();
    final configStore = context.watch<MonitoringConfigStore>();
    final monitor = context.watch<HealthMonitorService>();
    final connectionManager = context.watch<ServerConnectionManager>();

    final monitored = repo.connections.where((c) => configStore.get(c.id).enabled).toList();

    var good = 0, review = 0, warning = 0, offline = 0;
    for (final profile in monitored) {
      final result = calculateHealthStatus(monitor.latestFor(profile.id), connectionManager.stateFor(profile.id));
      switch (result.status) {
        case HealthStatus.good:
        case HealthStatus.info:
          good++;
        case HealthStatus.review:
          review++;
        case HealthStatus.warning:
          warning++;
        case HealthStatus.offline:
        case HealthStatus.unknown:
          offline++;
      }
    }

    return Scaffold(
      appBar: AppTopBar(
        sectionLabel: 'Monitor',
        activeConnection: repo.activeConnection,
        onTapConnectionPill: () => context.push('/connections'),
        onTapConnections: () => context.push('/connections'),
        onTapProfile: () => context.push('/settings'),
        onTapTransfers: () => context.push('/transfers'),
      ),
      body: monitored.isEmpty
          ? EmptyStateView(
              icon: Icons.monitor_heart_outlined,
              title: 'No servers being monitored',
              subtitle: 'Add a saved server to start monitoring it.',
              action: FilledButton.icon(
                onPressed: () => _addMonitoring(context, repo),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Monitoring'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _summaryRow(monitored.length, good, review, warning, offline),
                const SizedBox(height: 12),
                const Text('LIVE SERVERS', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.primary)),
                const SizedBox(height: 8),
                for (final profile in monitored) _serverCard(context, profile, monitor, connectionManager),
              ],
            ),
      floatingActionButton: monitored.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addMonitoring(context, repo),
              icon: const Icon(Icons.add),
              label: const Text('Add Monitoring'),
            ),
    );
  }

  /// Lets the user pick from their SAVED connections to add to
  /// monitoring — per the brief, monitoring is opt-in per server, and
  /// this is the explicit "select from the servers" entry point rather
  /// than only being reachable from a specific server's own Health
  /// detail screen.
  Future<void> _addMonitoring(BuildContext context, ConnectionRepository repo) async {
    final configStore = context.read<MonitoringConfigStore>();
    final candidates = repo.connections.where((c) => !configStore.get(c.id).enabled).toList();

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Every saved server is already being monitored.')),
      );
      return;
    }

    final picked = await showModalBottomSheet<ConnectionProfile>(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Monitoring', style: TextStyle(fontFamily: 'Geist', fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Choose a saved server to start monitoring.',
                  style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: candidates
                      .map((c) => ListTile(
                            leading: const Icon(Icons.dns_outlined),
                            title: Text(c.name),
                            subtitle: Text('${c.username}@${c.host}:${c.port}',
                                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11)),
                            onTap: () => Navigator.pop(context, c),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !context.mounted) return;

    // Enable with sensible defaults; the user can fine-tune interval and
    // watched services afterward via that server's Monitoring Settings.
    final config = configStore.get(picked.id).copyWith(enabled: true);
    await configStore.save(config);
    if (!context.mounted) return;
    context.read<HealthMonitorService>().applyConfig(
          picked,
          config,
          onHostKeyVerification: (r) => showHostKeyVerificationDialog(context, r),
        );
    if (context.mounted) {
      context.push('/health/${picked.id}/settings');
    }
  }  Widget _summaryRow(int total, int good, int review, int warning, int offline) {
    Widget stat(String label, int count, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
            child: Column(children: [
              Text('$count', style: TextStyle(fontFamily: 'Geist', fontSize: 18, fontWeight: FontWeight.w700, color: color)),
              Text(label, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 9, color: AppColors.onSurfaceVariant)),
            ]),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$total Monitored', style: const TextStyle(fontFamily: 'Geist', fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          stat('HEALTHY', good, AppColors.secondary),
          const SizedBox(width: 6),
          stat('REVIEW', review, AppColors.tertiary),
          const SizedBox(width: 6),
          stat('WARNING', warning, AppColors.error),
          const SizedBox(width: 6),
          stat('OFFLINE', offline, AppColors.outline),
        ]),
      ],
    );
  }

  Widget _serverCard(
    BuildContext context,
    ConnectionProfile profile,
    HealthMonitorService monitor,
    ServerConnectionManager connectionManager,
  ) {
    final health = monitor.latestFor(profile.id);
    final lastChecked = monitor.lastCheckedFor(profile.id);
    final checking = monitor.isChecking(profile.id);
    final result = calculateHealthStatus(health, connectionManager.stateFor(profile.id));
    final color = switch (result.status) {
      HealthStatus.good => AppColors.secondary,
      HealthStatus.info => AppColors.onSurfaceVariant,
      HealthStatus.review => AppColors.tertiary,
      HealthStatus.warning => AppColors.error,
      HealthStatus.offline => AppColors.outline,
      HealthStatus.unknown => AppColors.outline,
    };
    final isStale = lastChecked != null && DateTime.now().difference(lastChecked) > const Duration(minutes: 10);

    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => context.push('/health/${profile.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, size: 10, color: color),
                  const SizedBox(width: 6),
                  Expanded(child: Text(profile.name, style: const TextStyle(fontFamily: 'Geist', fontSize: 14, fontWeight: FontWeight.w600))),
                  if (checking)
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Text(result.status.label, style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                ],
              ),
              Text(profile.host, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 6),
              if (health == null)
                const Text('No data yet', style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.outline))
              else
                Row(
                  children: [
                    if (health.cpu.hasValue) _metric('CPU', '${health.cpu.value!.usagePercent.round()}%'),
                    if (health.memory.hasValue) _metric('RAM', '${(health.memory.value!.usedFraction * 100).round()}%'),
                    if (health.filesystems.hasValue && health.filesystems.value!.isNotEmpty)
                      _metric('Disk', '${(health.filesystems.value!.first.usedFraction * 100).round()}%'),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(isStale ? Icons.history_toggle_off : Icons.check_circle_outline, size: 12, color: isStale ? AppColors.tertiary : AppColors.outline),
                  const SizedBox(width: 4),
                  Text(
                    lastChecked == null ? 'Never checked' : '${isStale ? 'Stale — ' : ''}Last checked ${formatRelativeTime(lastChecked)}',
                    style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: isStale ? AppColors.tertiary : AppColors.outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.onSurfaceVariant),
          children: [
            TextSpan(text: '$label '),
            TextSpan(text: value, style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
