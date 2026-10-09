import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HealthRefreshInterval {
  manual,
  m1,
  m5,
  m15,
  m30,
  h1;

  String get label => switch (this) {
        HealthRefreshInterval.manual => 'Manual',
        HealthRefreshInterval.m1 => '1 minute',
        HealthRefreshInterval.m5 => '5 minutes',
        HealthRefreshInterval.m15 => '15 minutes',
        HealthRefreshInterval.m30 => '30 minutes',
        HealthRefreshInterval.h1 => '1 hour',
      };

  Duration? get duration => switch (this) {
        HealthRefreshInterval.manual => null,
        HealthRefreshInterval.m1 => const Duration(minutes: 1),
        HealthRefreshInterval.m5 => const Duration(minutes: 5),
        HealthRefreshInterval.m15 => const Duration(minutes: 15),
        HealthRefreshInterval.m30 => const Duration(minutes: 30),
        HealthRefreshInterval.h1 => const Duration(hours: 1),
      };
}

/// Per-server monitoring configuration.
///
/// A saved server is monitored only if [enabled] is true — saving a
/// connection profile never implies monitoring it (see the phase brief:
/// "a server being saved does NOT automatically mean it is monitored").
/// Default is disabled with a Manual interval, so nothing runs
/// unattended until the user opts in.
@immutable
class MonitoringConfig {
  const MonitoringConfig({
    required this.profileId,
    this.enabled = false,
    this.interval = HealthRefreshInterval.manual,
    this.watchedServices = const ['nginx', 'docker', 'sshd', 'mysql', 'redis'],
  });

  final String profileId;
  final bool enabled;
  final HealthRefreshInterval interval;
  final List<String> watchedServices;

  MonitoringConfig copyWith({bool? enabled, HealthRefreshInterval? interval, List<String>? watchedServices}) {
    return MonitoringConfig(
      profileId: profileId,
      enabled: enabled ?? this.enabled,
      interval: interval ?? this.interval,
      watchedServices: watchedServices ?? this.watchedServices,
    );
  }

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'enabled': enabled,
        'interval': interval.name,
        'watchedServices': watchedServices,
      };

  factory MonitoringConfig.fromJson(Map<String, dynamic> json) => MonitoringConfig(
        profileId: json['profileId'] as String,
        enabled: json['enabled'] as bool? ?? false,
        interval: HealthRefreshInterval.values.byName(json['interval'] as String? ?? 'manual'),
        watchedServices: (json['watchedServices'] as List?)?.cast<String>() ?? const ['nginx', 'docker', 'sshd'],
      );
}

/// Persists [MonitoringConfig] per profile via `shared_preferences` — not
/// sensitive data, same rationale as the connection profile list.
class MonitoringConfigStore {
  MonitoringConfigStore(this._prefs);

  final SharedPreferences _prefs;
  // Kept as 'serverkit.*' deliberately — see connection_repository.dart's
  // note. This one is a PREFIX for per-server keys (one per profile id);
  // renaming it would drop every existing user's monitoring configuration
  // for every saved server at once.
  static const _keyPrefix = 'serverkit.monitoring.';

  MonitoringConfig get(String profileId) {
    final raw = _prefs.getString('$_keyPrefix$profileId');
    if (raw == null) return MonitoringConfig(profileId: profileId);
    try {
      return MonitoringConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return MonitoringConfig(profileId: profileId);
    }
  }

  Future<void> save(MonitoringConfig config) async {
    await _prefs.setString('$_keyPrefix${config.profileId}', jsonEncode(config.toJson()));
  }

  /// All profile ids that have monitoring turned on, scanning stored
  /// keys — used to know which servers to poll on app start.
  List<String> get monitoredProfileIds {
    final ids = <String>[];
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith(_keyPrefix)) continue;
      final id = key.substring(_keyPrefix.length);
      if (get(id).enabled) ids.add(id);
    }
    return ids;
  }
}
