import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/byte_format.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../connections/services/connection_repository.dart';
import '../../connections/models/connection_profile.dart';
import '../../ssh/widgets/host_key_verification_dialog.dart';
import '../models/server_health.dart';
import '../services/health_service.dart';

enum _AutoRefresh { off, s30, m1, m5, m15 }

extension on _AutoRefresh {
  String get label => switch (this) {
        _AutoRefresh.off => 'Off',
        _AutoRefresh.s30 => '30 sec',
        _AutoRefresh.m1 => '1 min',
        _AutoRefresh.m5 => '5 min',
        _AutoRefresh.m15 => '15 min',
      };

  Duration? get interval => switch (this) {
        _AutoRefresh.off => null,
        _AutoRefresh.s30 => const Duration(seconds: 30),
        _AutoRefresh.m1 => const Duration(minutes: 1),
        _AutoRefresh.m5 => const Duration(minutes: 5),
        _AutoRefresh.m15 => const Duration(minutes: 15),
      };
}

/// Server Health — real data collected FROM INSIDE the server over the
/// existing SSH connection (see `HealthService`'s doc), not an external
/// ping monitor. Auto-refresh defaults to Off per the brief, to avoid
/// unnecessary persistent SSH activity on a mobile connection.
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  ServerHealth? _health;
  AppFailure? _failure;
  bool _loading = false;
  String? _loadedForId;
  _AutoRefresh _autoRefresh = _AutoRefresh.off;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = context.watch<ConnectionRepository>().activeConnection;
    if (active != null && active.id != _loadedForId) {
      _loadedForId = active.id;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final active = context.read<ConnectionRepository>().activeConnection;
    if (active == null) return;
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final health = await context.read<HealthService>().collect(
            active,
            onHostKeyVerification: (request) => showHostKeyVerificationDialog(context, request),
          );
      if (!mounted) return;
      setState(() {
        _health = health;
        _loading = false;
      });
      _scheduleAutoRefresh();
    } on AppFailure catch (f) {
      if (!mounted) return;
      setState(() {
        _failure = f;
        _loading = false;
      });
    }
  }

  void _scheduleAutoRefresh() {
    final interval = _autoRefresh.interval;
    if (interval == null) return;
    Future.delayed(interval, () {
      if (mounted && _autoRefresh.interval == interval) _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ConnectionRepository>().activeConnection;
    return Scaffold(
      appBar: AppTopBar(
        sectionLabel: 'System Health',
        activeConnection: active,
        onTapConnectionPill: () => context.push('/connections'),
        onTapConnections: () => context.push('/connections'),
        onTapProfile: () => context.push('/settings'),
        onTapTransfers: () => context.push('/transfers'),
      ),
      body: _buildBody(active),
    );
  }

  Widget _buildBody(ConnectionProfile? active) {
    if (active == null) {
      return const EmptyStateView(icon: Icons.dns_outlined, title: 'No server selected');
    }
    if (_failure != null) {
      return ErrorStateView(
        failure: _failure!,
        actions: [RecoveryAction(label: 'Retry', isPrimary: true, onPressed: _refresh)],
      );
    }
    final health = _health;
    if (health == null) {
      return const LoadingStateView(label: 'Collecting health data...');
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildHeaderRow(health),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _metricTile('CPU LOAD', health.cpu)),
            const SizedBox(width: 8),
            Expanded(child: _memoryTile(health.memory)),
          ]),
          const SizedBox(height: 8),
          _storageSummaryTile(health.filesystems),
          const SizedBox(height: 16),
          _servicesSection(health.services),
          const SizedBox(height: 16),
          _processesSection(health.processes),
          const SizedBox(height: 16),
          _networkSection(health.network),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(ServerHealth health) {
    final sys = health.system;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sys.hasValue ? (sys.value!.hostname ?? 'Unknown host') : 'System info ${sys.unavailableLabel}',
                  style: const TextStyle(fontFamily: 'Geist', fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              DropdownButton<_AutoRefresh>(
                value: _autoRefresh,
                underline: const SizedBox.shrink(),
                dropdownColor: AppColors.surfaceContainerHigh,
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurface),
                items: _AutoRefresh.values
                    .map((r) => DropdownMenuItem(value: r, child: Text('Auto: ${r.label}')))
                    .toList(),
                onChanged: (r) {
                  setState(() => _autoRefresh = r!);
                  _scheduleAutoRefresh();
                },
              ),
              IconButton(onPressed: _loading ? null : _refresh, icon: const Icon(Icons.refresh, size: 18)),
            ],
          ),
          if (sys.hasValue) ...[
            const SizedBox(height: 4),
            Text(
              '${sys.value!.os ?? '—'} · ${sys.value!.kernel ?? ''} ${sys.value!.architecture ?? ''}',
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant),
            ),
            if (sys.value!.uptimeSeconds != null) ...[
              const SizedBox(height: 2),
              Text(
                'Uptime: ${_formatUptime(sys.value!.uptimeSeconds!)}',
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.secondary),
              ),
            ],
          ],
          const SizedBox(height: 2),
          Text(
            'Last updated ${health.lastUpdated.toLocal()}'.split('.').first,
            style: const TextStyle(fontFamily: 'Geist', fontSize: 10, color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  String _formatUptime(int seconds) {
    final d = Duration(seconds: seconds);
    return '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m';
  }

  Widget _metricTile(String label, Collected<CpuInfo> cpu) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          if (!cpu.hasValue)
            Text(cpu.unavailableLabel, style: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.outline))
          else ...[
            Text('${cpu.value!.usagePercent.round()}%',
                style: const TextStyle(fontFamily: 'Geist', fontSize: 22, fontWeight: FontWeight.w700)),
            Text('${cpu.value!.coreCount} cores (load-based estimate)',
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurfaceVariant)),
            if (cpu.value!.loadAverage != null)
              Text(
                'load ${cpu.value!.loadAverage!.map((v) => v.toStringAsFixed(2)).join(' / ')}',
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurfaceVariant),
              ),
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
            Text('${(memory.value!.usedFraction * 100).round()}%',
                style: const TextStyle(fontFamily: 'Geist', fontSize: 22, fontWeight: FontWeight.w700)),
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
            Text(
              '${formatBytes(memory.value!.usedKb * 1024)} / ${formatBytes(memory.value!.totalKb * 1024)}',
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurfaceVariant),
            ),
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
                  Expanded(
                    child: Text(fs.mount,
                        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurface)),
                  ),
                  Text(
                    '${formatBytes(fs.usedKb * 1024)} / ${formatBytes(fs.totalKb * 1024)} (${(fs.usedFraction * 100).round()}%)',
                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurfaceVariant),
                  ),
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
                      Expanded(
                        child: Text(s.name, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12)),
                      ),
                      Text(s.stateLabel,
                          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.secondary)),
                    ],
                  ),
                );
              }).toList(),
            ),
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
