import '../../connections/models/connection_profile.dart';
import '../../ssh/models/host_key_verification.dart';
import '../../ssh/services/ssh_service.dart';
import '../models/security_check_result.dart';
import 'checks/authentication_check.dart';
import 'checks/listening_ports_check.dart';
import 'checks/ssh_config_check.dart';
import 'security_check.dart';

/// Runs the registered [SecurityCheck]s and aggregates their findings.
///
/// IMPLEMENTED THIS PHASE: [AuthenticationCheck], [ListeningPortsCheck],
/// [SshConfigCheck] — three real, fully-working checks. The brief's
/// full catalog (file-change diffing, user/UID-0 audit, cron/persistence,
/// process analysis, package activity, web log analysis, custom checks)
/// is architecturally supported by [SecurityCheck] but NOT implemented
/// yet — adding one is exactly "write a class implementing SecurityCheck,
/// register it below," no UI changes needed. See the phase report for
/// why this subset was prioritized over shallow coverage of all ten.
class SecurityService {
  SecurityService(SshService sshService) : _sshService = sshService {
    _checks = [
      AuthenticationCheck(),
      ListeningPortsCheck(),
      SshConfigCheck(),
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
