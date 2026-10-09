import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../connections/models/connection_profile.dart';
import '../../connections/services/connection_repository.dart';
import '../../ssh/widgets/host_key_verification_dialog.dart';
import '../models/monitoring_config.dart';
import '../services/health_monitor_service.dart';

const _kKnownServices = ['nginx', 'apache2', 'docker', 'sshd', 'mysql', 'mariadb', 'postgresql', 'redis-server'];

/// Per-server monitoring configuration: on/off, refresh interval, and
/// which services to keep an eye on. Saving here immediately applies to
/// [HealthMonitorService] (restarts its timer for this profile) — no app
/// restart needed.
class MonitoringSettingsScreen extends StatefulWidget {
  const MonitoringSettingsScreen({super.key, required this.profileId});

  final String profileId;

  @override
  State<MonitoringSettingsScreen> createState() => _MonitoringSettingsScreenState();
}

class _MonitoringSettingsScreenState extends State<MonitoringSettingsScreen> {
  late MonitoringConfig _config;
  ConnectionProfile? _profile;

  @override
  void initState() {
    super.initState();
    final repo = context.read<ConnectionRepository>();
    for (final c in repo.connections) {
      if (c.id == widget.profileId) _profile = c;
    }
    _config = context.read<MonitoringConfigStore>().get(widget.profileId);
  }

  Future<void> _save() async {
    await context.read<MonitoringConfigStore>().save(_config);
    if (_profile != null && mounted) {
      context.read<HealthMonitorService>().applyConfig(
            _profile!,
            _config,
            onHostKeyVerification: (r) => showHostKeyVerificationDialog(context, r),
          );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(
        title: Text(profile?.name.toUpperCase() ?? 'MONITORING'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: profile == null
          ? const Center(child: Text('Server not found'))
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Monitoring'),
                  subtitle: Text(_config.enabled ? 'Enabled' : 'Disabled'),
                  value: _config.enabled,
                  onChanged: (v) => setState(() => _config = _config.copyWith(enabled: v)),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('INTERVAL', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
                for (final interval in HealthRefreshInterval.values)
                  RadioListTile<HealthRefreshInterval>(
                    title: Text(interval.label),
                    value: interval,
                    groupValue: _config.interval,
                    onChanged: (v) => setState(() => _config = _config.copyWith(interval: v)),
                  ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('WATCHED SERVICES', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
                for (final service in _kKnownServices)
                  CheckboxListTile(
                    title: Text(service),
                    value: _config.watchedServices.contains(service),
                    onChanged: (checked) {
                      final updated = [..._config.watchedServices];
                      if (checked == true) {
                        updated.add(service);
                      } else {
                        updated.remove(service);
                      }
                      setState(() => _config = _config.copyWith(watchedServices: updated));
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
