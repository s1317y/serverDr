import '../../connections/models/connection_profile.dart';
import '../../ssh/models/host_key_verification.dart';
import '../../ssh/services/ssh_service.dart';
import '../models/security_check_result.dart';
import 'checks/authentication_check.dart';
import 'checks/docker_check.dart';
import 'checks/file_permissions_check.dart';
import 'checks/listening_ports_check.dart';
import 'checks/package_activity_check.dart';
import 'checks/persistence_check.dart';
import 'checks/ssh_config_check.dart';
import 'checks/users_check.dart';
import 'security_check.dart';

/// Runs the registered [SecurityCheck]s and aggregates their findings.
///
/// IMPLEMENTED: [AuthenticationCheck], [ListeningPortsCheck],
/// [SshConfigCheck], [UsersCheck], [PersistenceCheck],
/// [FilePermissionsCheck], [PackageActivityCheck], [DockerCheck] — eight
/// real, fully-working checks covering authentication, network, SSH
/// hardening, users, persistence/cron/authorized_keys, sensitive file
/// permissions, package activity, and Docker. Each is architecturally
/// independent — adding another category (recent file changes, web log
/// analysis, a full Log Explorer, custom user-defined checks) is exactly
/// "implement SecurityCheck, register it below," no UI changes needed.
/// Those specific categories are NOT implemented this pass — see the
/// phase report for why depth was prioritized over covering every
/// category shallowly.
class SecurityService {
  SecurityService(SshService sshService) : _sshService = sshService {
    _checks = [
      AuthenticationCheck(),
      ListeningPortsCheck(),
      SshConfigCheck(),
      UsersCheck(),
      PersistenceCheck(),
      FilePermissionsCheck(),
      PackageActivityCheck(),
      DockerCheck(),
    ];
  }

  final SshService _sshService;
  late final List<SecurityCheck> _checks;

  List<SecurityCheck> get availableChecks => List.unmodifiable(_checks);

  Future<SecurityScanResult> runScan(
    ConnectionProfile profile, {
    required HostKeyDecisionHandler onHostKeyVerification,
    Set<SecurityCategory>? onlyCategories,
  }) async {
    final checksToRun =
        onlyCategories == null ? _checks : _checks.where((c) => onlyCategories.contains(c.category)).toList();

    final findings = <SecurityCheckResult>[];
    for (final check in checksToRun) {
      final results = await check.run(profile, _sshService, onHostKeyVerification);
      findings.addAll(results);
    }

    return SecurityScanResult(findings: findings, completedAt: DateTime.now(), serverName: profile.name);
  }
}
