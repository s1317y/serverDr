import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_failure.dart';
import '../../connections/models/connection_profile.dart';
import '../../ssh/models/host_key_verification.dart';
import '../models/monitoring_config.dart';
import '../models/server_health.dart';
import 'health_service.dart';

/// Owns periodic health collection for every server with monitoring
/// enabled, plus a small in-memory history per server.
///
/// ANDROID BACKGROUND LIMITATION (real, not hedging): the `Timer.periodic`
/// this uses only fires while the Dart isolate is alive — i.e. reliably
/// while ServerDr is in the foreground, and for a limited time after
/// backgrounding depending on the device/OEM's process lifecycle policy.
/// It does NOT survive the OS killing the app, and this phase does not
/// integrate `WorkManager`/`android_alarm_manager` for true background
/// scheduling — that's real follow-up work, deliberately not implemented
/// here so as not to promise monitoring the app can't actually deliver.
/// [lastCheckedFor] always reflects the last time a check ACTUALLY ran,
/// so the UI can show "Last checked 12m ago" honestly instead of an
/// implied "live" state.
///
/// Only stores structured metrics (via [ServerHealth]) — never raw
/// terminal output — capped at [_maxHistoryPerServer] snapshots per
/// server, per the brief's "lightweight" requirement.
class HealthMonitorService extends ChangeNotifier {
  HealthMonitorService(this._healthService);

  final HealthService _healthService;
  static const _maxHistoryPerServer = 60;

  final Map<String, ServerHealth> _latest = {};
  final Map<String, List<ServerHealth>> _history = {};
  final Map<String, DateTime> _lastChecked = {};
  final Map<String, DateTime> _lastSuccessful = {};
  final Map<String, AppFailure?> _lastError = {};
  final Map<String, Timer> _timers = {};
  final Map<String, bool> _checking = {};

  ServerHealth? latestFor(String profileId) => _latest[profileId];
  List<ServerHealth> historyFor(String profileId) => List.unmodifiable(_history[profileId] ?? const []);
  DateTime? lastCheckedFor(String profileId) => _lastChecked[profileId];
  DateTime? lastSuccessfulFor(String profileId) => _lastSuccessful[profileId];
  AppFailure? lastErrorFor(String profileId) => _lastError[profileId];
  bool isChecking(String profileId) => _checking[profileId] ?? false;

  /// (Re)starts periodic polling for [profile] per [config]. Safe to call
  /// repeatedly (e.g. whenever settings change) — cancels any previous
  /// timer first. A Manual interval means "monitored, but only checked
  /// when the user asks" — still tracked here so it appears in the Live
  /// Servers list with its last-known data.
  void applyConfig(
    ConnectionProfile profile,
    MonitoringConfig config, {
    required HostKeyDecisionHandler onHostKeyVerification,
  }) {
    _timers.remove(profile.id)?.cancel();
    if (!config.enabled) {
      notifyListeners(); // so screens watching this list drop the server immediately
      return;
    }

    // Kick off an immediate check so enabling monitoring doesn't leave
    // the card blank until the first interval elapses.
    checkNow(profile, onHostKeyVerification: onHostKeyVerification);

    final duration = config.interval.duration;
    if (duration != null) {
      _timers[profile.id] = Timer.periodic(duration, (_) {
        checkNow(profile, onHostKeyVerification: onHostKeyVerification);
      });
    }
  }

  void stop(String profileId) {
    _timers.remove(profileId)?.cancel();
  }

  Future<void> checkNow(
    ConnectionProfile profile, {
    required HostKeyDecisionHandler onHostKeyVerification,
  }) async {
    if (_checking[profile.id] == true) return; // don't stack overlapping checks
    _checking[profile.id] = true;
    notifyListeners();
    try {
      final health = await _healthService.collect(profile, onHostKeyVerification: onHostKeyVerification);
      _latest[profile.id] = health;
      _lastChecked[profile.id] = DateTime.now();
      _lastSuccessful[profile.id] = DateTime.now();
      _lastError[profile.id] = null;

      final history = _history.putIfAbsent(profile.id, () => []);
      history.add(health);
      if (history.length > _maxHistoryPerServer) history.removeAt(0);
    } on AppFailure catch (f) {
      // Deliberately keep _latest[profile.id] as-is — "last known health"
      // must survive a failed check, per the offline-experience brief.
      _lastChecked[profile.id] = DateTime.now();
      _lastError[profile.id] = f;
    } catch (_) {
      _lastChecked[profile.id] = DateTime.now();
      _lastError[profile.id] = const AppFailure(AppFailureKind.unknown);
    } finally {
      _checking[profile.id] = false;
      notifyListeners();
    }
  }

  /// Simple trend helper for the "1h average / peak" UI — CPU-only for
  /// now (the brief's example), computed from in-memory history.
  ({double? average, double? peak}) cpuTrend(String profileId) {
    final history = _history[profileId];
    if (history == null || history.isEmpty) return (average: null, peak: null);
    final values = history.where((h) => h.cpu.hasValue).map((h) => h.cpu.value!.usagePercent).toList();
    if (values.isEmpty) return (average: null, peak: null);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final peak = values.reduce((a, b) => a > b ? a : b);
    return (average: avg, peak: peak);
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }
}
