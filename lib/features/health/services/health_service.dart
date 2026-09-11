import '../../connections/models/connection_profile.dart';
import '../../ssh/models/host_key_verification.dart';
import '../models/server_health.dart';

/// Collects a [ServerHealth] snapshot for one server.
///
/// Health data comes from INSIDE the server over the existing SSH
/// connection (via `SshService.runCommand`, which reuses the same
/// authenticated connection the Terminal/Files tabs use — see that
/// method's doc) — never an external ping/monitor. This is a real
/// implementation detail the brief calls out explicitly.
abstract interface class HealthService {
  Future<ServerHealth> collect(
    ConnectionProfile profile, {
    required HostKeyDecisionHandler onHostKeyVerification,
  });
}
