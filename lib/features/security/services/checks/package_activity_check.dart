import '../../../connections/models/connection_profile.dart';
import '../../../ssh/models/host_key_verification.dart';
import '../../../ssh/services/ssh_service.dart';
import '../../models/security_check_result.dart';
import '../security_check.dart';

/// Detects which package manager is present and shows recent package
/// activity (installs/upgrades). Purely informational (INFO), since
/// package updates are routine, not a security finding by themselves.
class PackageActivityCheck implements SecurityCheck {
  @override
  String get id => 'package_activity';
  @override
  String get title => 'Package Activity';
  @override
  SecurityCategory get category => SecurityCategory.system;

  @override
  Future<List<SecurityCheckResult>> run(
    ConnectionProfile profile,
    SshService sshService,
    HostKeyDecisionHandler onHostKeyVerification,
  ) async {
    Future<String?> read(String cmd) => runReadOnly(profile, sshService, onHostKeyVerification, cmd);
    final now = DateTime.now();

    final apt = await read('tail -n 30 /var/log/apt/history.log 2>/dev/null');
    if (apt != null && apt.trim().isNotEmpty) {
      return [
        SecurityCheckResult(
          id: id,
          title: title,
          category: category,
          severity: SecuritySeverity.info,
          description: 'Recent apt package activity (Debian/Ubuntu).',
          evidence: apt.split('\n').where((l) => l.trim().isNotEmpty).toList(),
          timestamp: now,
        ),
      ];
    }

    final dnf = await read('dnf history list 2>/dev/null | head -20');
    if (dnf != null && dnf.trim().isNotEmpty) {
      return [
        SecurityCheckResult(
          id: id,
          title: title,
          category: category,
          severity: SecuritySeverity.info,
          description: 'Recent dnf package activity (Fedora/RHEL/Rocky/Alma).',
          evidence: dnf.split('\n').where((l) => l.trim().isNotEmpty).toList(),
          timestamp: now,
        ),
      ];
    }

    final apk = await read('command -v apk >/dev/null && apk info 2>/dev/null | head -20');
    if (apk != null && apk.trim().isNotEmpty) {
      return [
        SecurityCheckResult(
          id: id,
          title: title,
          category: category,
          severity: SecuritySeverity.info,
          description: 'Installed packages (Alpine apk) — apk does not keep transaction history by default.',
          evidence: apk.split('\n').where((l) => l.trim().isNotEmpty).take(20).toList(),
          timestamp: now,
        ),
      ];
    }

    return [
      SecurityCheckResult(
        id: id,
        title: title,
        category: category,
        severity: SecuritySeverity.info,
        description: 'Package history unavailable (no supported package manager log was found).',
        evidence: const [],
        timestamp: now,
      ),
    ];
  }
}
