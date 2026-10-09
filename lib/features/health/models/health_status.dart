import 'package:flutter/foundation.dart';

import '../../connections/models/server_connection_state.dart';
import 'server_health.dart';

/// Calculated overall status for a monitored server — distinct from raw
/// [ServerHealth] data. Thresholds are fixed defaults for now (the brief
/// notes they should become configurable later).
enum HealthStatus { good, info, review, warning, offline, unknown }

extension HealthStatusLabel on HealthStatus {
  String get label => switch (this) {
        HealthStatus.good => 'GOOD',
        HealthStatus.info => 'INFO',
        HealthStatus.review => 'REVIEW',
        HealthStatus.warning => 'WARNING',
        HealthStatus.offline => 'OFFLINE',
        HealthStatus.unknown => 'UNKNOWN',
      };
}

@immutable
class HealthStatusResult {
  const HealthStatusResult(this.status, this.reasons);
  final HealthStatus status;
  final List<String> reasons;
}

/// Pure function: given the last known health snapshot (if any) and the
/// server's live connection state, decide GOOD/REVIEW/WARNING/OFFLINE/
/// UNKNOWN. Never upgrades a finding beyond what the numbers actually
/// show — e.g. disk >80% is REVIEW, not WARNING, until it crosses 90%.
HealthStatusResult calculateHealthStatus(ServerHealth? health, ServerConnectionState connectionState) {
  if (connectionState == ServerConnectionState.connectionFailed ||
      connectionState == ServerConnectionState.authenticationFailed) {
    return const HealthStatusResult(HealthStatus.offline, ['Connection unavailable']);
  }
  if (health == null) {
    return const HealthStatusResult(HealthStatus.unknown, ['No successful health check yet']);
  }

  final reasons = <String>[];
  var status = HealthStatus.good;

  const severityOrder = [HealthStatus.good, HealthStatus.info, HealthStatus.review, HealthStatus.warning];
  void bump(HealthStatus s, String reason) {
    reasons.add(reason);
    if (severityOrder.indexOf(s) > severityOrder.indexOf(status)) status = s;
  }

  if (health.memory.hasValue) {
    final pct = health.memory.value!.usedFraction * 100;
    if (pct > 90) {
      bump(HealthStatus.warning, 'Memory usage ${pct.round()}%');
    } else if (pct > 80) {
      bump(HealthStatus.review, 'Memory usage ${pct.round()}%');
    }
  }

  if (health.filesystems.hasValue) {
    for (final fs in health.filesystems.value!) {
      final pct = fs.usedFraction * 100;
      if (pct > 90) {
        bump(HealthStatus.warning, '${fs.mount} disk usage ${pct.round()}%');
      } else if (pct > 80) {
        bump(HealthStatus.review, '${fs.mount} disk usage ${pct.round()}%');
      }
      if (fs.inodesTotal != null && fs.inodesUsed != null && fs.inodesTotal! > 0) {
        final inodePct = (fs.inodesUsed! / fs.inodesTotal!) * 100;
        if (inodePct > 90) bump(HealthStatus.warning, '${fs.mount} inode usage ${inodePct.round()}%');
      }
    }
  }

  if (health.cpu.hasValue && health.cpu.value!.usagePercent > 90) {
    bump(HealthStatus.warning, 'CPU load estimate ${health.cpu.value!.usagePercent.round()}%');
  }

  if (reasons.isEmpty) reasons.add('All monitored metrics within normal range');
  return HealthStatusResult(status, reasons);
}
