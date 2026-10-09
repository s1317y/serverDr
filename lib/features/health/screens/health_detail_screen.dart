import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/byte_format.dart';
import '../../../core/utils/relative_time.dart';
import '../../connections/models/connection_profile.dart';
import '../../connections/models/server_connection_state.dart';
import '../../connections/services/connection_repository.dart';
import '../../connections/services/server_connection_manager.dart';
import '../../ssh/widgets/host_key_verification_dialog.dart';
import '../models/health_status.dart';
import '../models/server_health.dart';
import '../services/health_monitor_service.dart';

/// Detailed single-server Health view. Reads from [HealthMonitorService] —
/// the SAME collector/cache the multi-server overview screen uses — so
/// there is exactly one place health data actually gets collected.
/// Refresh here triggers a real check now; it does not duplicate
/// HealthService's collection logic.
class HealthDetailScreen extends StatelessWidget {
  const HealthDetailScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ConnectionRepository>();
    ConnectionProfile? profile;
    for (final c in repo.connections) {
      if (c.id == profileId) profile = c;
    }
    if (profile == null) {
      return Scaffold(appBar: AppBar(title: const Text('Health')), body: const Center(child: Text('Server not found')));
    }

    final monitor = context.watch<HealthMonitorService>();
    final connectionManager = context.watch<ServerConnectionManager>();
    final health = monitor.latestFor(profile.id);
    final lastChecked = monitor.lastCheckedFor(profile.id);
    final checking = monitor.isChecking(profile.id);
    final statusResult = calculateHealthStatus(health, connectionManager.stateFor(profile.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile.name, style: const TextStyle(fontFamily: 'Geist', fontSize: 15)),
            Text(profile.host, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/health/${profile!.id}/settings'),
            icon: const Icon(Icons.tune),
            tooltip: 'Monitoring settings',
          ),
          IconButton(
            onPressed: checking
                ? null
                : () => monitor.checkNow(profile!, onHostKeyVerification: (r) => showHostKeyVerificationDialog(context, r)),
            icon: checking
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: health == null
          ? _emptyState(context, profile, checking, monitor)
          : RefreshIndicator(
              onRefresh: () => monitor.checkNow(profile!, onHostKeyVerification: (r) => showHostKeyVerificationDialog(context, r)),
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _freshnessBanner(statusResult, lastChecked),
                  const SizedBox(height: 10),
                  _headerRow(health, lastChecked),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _cpuTile(health.cpu, monitor.cpuTrend(profile.id))),
                    const SizedBox(width: 8),
                    Expanded(child: _memoryTile(health.memory)),
                  ]),
                  const SizedBox(height: 8),
                  _storageSummaryTile(health.filesystems),
                  const SizedBox(height: 16),
                  _servicesSection(health.services),
                  const SizedBox(height: 16),
                  _dockerSection(health.dockerAvailable),
                  const SizedBox(height: 16),
                  _processesSection(health.processes),
                  const SizedBox(height: 16),
                  _networkSection(health.network),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _emptyState(BuildContext context, ConnectionProfile profile, bool checking, HealthMonitorService monitor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monitor_heart_outlined, size: 40, color: AppColors.outline),
            const SizedBox(height: 12),
            const Text('No health data yet', style: TextStyle(fontFamily: 'Geist', fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (checking)
              const CircularProgressIndicator()
            else
              FilledButton.icon(
                onPressed: () => monitor.checkNow(profile, onHostKeyVerification: (r) => showHostKeyVerificationDialog(context, r)),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Check Now'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _freshnessBanner(HealthStatusResult statusResult, DateTime? lastChecked) {
    final color = switch (statusResult.status) {
      HealthStatus.good => AppColors.secondary,
      HealthStatus.info => AppColors.onSurfaceVariant,
      HealthStatus.review => AppColors.tertiary,
      HealthStatus.warning => AppColors.error,
      HealthStatus.offline => AppColors.error,
      HealthStatus.unknown => AppColors.outline,
    };
    final isStale = lastChecked != null && DateTime.now().difference(lastChecked) > const Duration(minutes: 10);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.4))),
      child: Row(
        children: [
          Icon(isStale ? Icons.history_toggle_off : Icons.circle, size: isStale ? 16 : 10, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${isStale ? 'STALE — ' : ''}${statusResult.status.label}',
                    style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                Text(statusResult.reasons.join(' · '), style: const TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.onSurfaceVariant)),
                if (lastChecked != null)
                  Text('Updated ${formatRelativeTime(lastChecked)}',
                      style: const TextStyle(fontFamily: 'Geist', fontSize: 10, color: AppColors.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow(ServerHealth health, DateTime? lastChecked) {
    final sys = health.system;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sys.hasValue ? (sys.value!.hostname ?? 'Unknown host') : 'System info ${sys.unavailableLabel}',
              style: const TextStyle(fontFamily: 'Geist', fontSize: 14, fontWeight: FontWeight.w600)),
          if (sys.hasValue) ...[
            const SizedBox(height: 4),
            Text('${sys.value!.os ?? '—'} · ${sys.value!.kernel ?? ''} ${sys.value!.architecture ?? ''}',
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant)),
            if (sys.value!.uptimeSeconds != null)
              Text('Uptime: ${_formatUptime(sys.value!.uptimeSeconds!)}',
                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.secondary)),
          ],
        ],
      ),
    );
  }

  String _formatUptime(int seconds) {
    final d = Duration(seconds: seconds);
    return '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m';
  }

  Widget _cpuTile(Collected<CpuInfo> cpu, ({double? average, double? peak}) trend) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CPU LOAD', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          if (!cpu.hasValue)
            Text(cpu.unavailableLabel, style: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.outline))
          else ...[
            Text('${cpu.value!.usagePercent.round()}%', style: const TextStyle(fontFamily: 'Geist', fontSize: 22, fontWeight: FontWeight.w700)),
            Text('${cpu.value!.coreCount} cores (load-based estimate)',
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurfaceVariant)),
            if (trend.average != null)
              Text('1h avg ${trend.average!.round()}% · peak ${trend.peak!.round()}%',
                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  Widget _memoryTile(Collected<MemoryInfo> memory) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MEMORY', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          if (!memory.hasValue)
            Text(memory.unavailableLabel, style: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.outline))
          else ...[
            Text('${(memory.value!.usedFraction * 100).round()}%', style: const TextStyle(fontFamily: 'Geist', fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: memory.value!.usedFraction.clamp(0, 1),
                minHeight: 5,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation(AppColors.tertiary),
              ),
            ),
            const SizedBox(height: 2),
            Text('${formatBytes(memory.value!.usedKb * 1024)} / ${formatBytes(memory.value!.totalKb * 1024)}',
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  Widget _storageSummaryTile(Collected<List<FilesystemInfo>> fsCollected) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STORAGE', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          if (!fsCollected.hasValue)
            Text(fsCollected.unavailableLabel, style: const TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.outline))
          else
            for (final fs in fsCollected.value!.take(5)) ...[
              Row(
                children: [
                  Expanded(child: Text(fs.mount, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurface))),
                  Text('${formatBytes(fs.usedKb * 1024)} / ${formatBytes(fs.totalKb * 1024)} (${(fs.usedFraction * 100).round()}%)',
                      style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: fs.usedFraction.clamp(0, 1),
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(fs.usedFraction > 0.85 ? AppColors.error : AppColors.secondary),
                ),
              ),
              const SizedBox(height: 6),
            ],
        ],
      ),
    );
  }

  Widget _servicesSection(Collected<List<ServiceInfo>> services) {
    return _sectionCard(
      title: 'System Services',
      child: !services.hasValue
          ? Text(services.unavailableLabel, style: const TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.outline))
          : Column(
              children: services.value!.take(10).map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: s.active ? AppColors.secondary : AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s.name, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12))),
                      Text(s.stateLabel, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.secondary)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _dockerSection(bool dockerAvailable) {
    return _sectionCard(
      title: 'Docker',
      child: dockerAvailable
          ? const Text(
              'Docker is installed on this server. Per-container CPU/memory/uptime detail is not '
              'collected yet — this phase only detects availability.',
              style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.onSurfaceVariant),
            )
          : const Text('Not available', style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.outline)),
    );
  }

  Widget _processesSection(Collected<List<ProcessInfo>> processes) {
    return _sectionCard(
      title: 'Top Processes (by CPU)',
      child: !processes.hasValue
          ? Text(processes.unavailableLabel, style: const TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.outline))
          : Column(
              children: processes.value!.take(10).map((p) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(width: 50, child: Text('${p.pid}', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11))),
                      SizedBox(width: 60, child: Text(p.user, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11))),
                      SizedBox(
                          width: 46,
                          child: Text('${p.cpuPercent.toStringAsFixed(1)}%',
                              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.tertiary))),
                      Expanded(
                        child: Text(p.command,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _networkSection(Collected<List<NetworkInterfaceInfo>> network) {
    return _sectionCard(
      title: 'Network Interfaces',
      child: !network.hasValue
          ? Text(network.unavailableLabel, style: const TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.outline))
          : Column(
              children: network.value!.map((n) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(width: 70, child: Text(n.name, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11))),
                      Expanded(
                        child: Text(n.addresses.join(', '),
                            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Geist', fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
