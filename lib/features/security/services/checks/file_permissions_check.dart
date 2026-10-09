import '../../../connections/models/connection_profile.dart';
import '../../../ssh/models/host_key_verification.dart';
import '../../../ssh/services/ssh_service.dart';
import '../../models/security_check_result.dart';
import '../security_check.dart';

/// Checks permissions on a small set of security-sensitive paths that
/// have well-known "expected" permission ranges (e.g. `/etc/shadow`
/// should not be world-readable). Flags deviations as REVIEW with the
/// literal `ls -l` line as evidence, never a stronger claim.
class FilePermissionsCheck implements SecurityCheck {
  @override
  String get id => 'file_permissions';
  @override
  String get title => 'Sensitive File Permissions';
  @override
  SecurityCategory get category => SecurityCategory.filesystem;

  static const _targets = ['/etc/passwd', '/etc/shadow', '/etc/ssh/sshd_config', '/etc/sudoers'];

  @override
  Future<List<SecurityCheckResult>> run(
    ConnectionProfile profile,
    SshService sshService,
    HostKeyDecisionHandler onHostKeyVerification,
  ) async {
    final raw = await runReadOnly(
      profile,
      sshService,
      onHostKeyVerification,
      'ls -l ${_targets.join(' ')} 2>/dev/null',
    );
    final now = DateTime.now();
    if (raw == null || raw.trim().isEmpty) {
      return [
        SecurityCheckResult(
          id: id,
          title: title,
          category: category,
          severity: SecuritySeverity.info,
          description: "Couldn't read permissions for the inspected paths.",
          evidence: const [],
          timestamp: now,
        ),
      ];
    }

    final results = <SecurityCheckResult>[];
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final cols = trimmed.split(RegExp(r'\s+'));
      if (cols.length < 9) continue;
      final perms = cols[0];
      final path = cols.sublist(8).join(' ');

      var severity = SecuritySeverity.pass;
      var note = 'Permissions look typical for this path.';
      if (path.endsWith('shadow') && (perms[4] != '-' || perms[7] != '-')) {
        severity = SecuritySeverity.review;
        note = '/etc/shadow is readable by group/other — this normally should be root-only.';
      } else if (path.endsWith('sshd_config') && perms[8] == 'w') {
        severity = SecuritySeverity.review;
        note = 'sshd_config is world-writable.';
      }

      results.add(SecurityCheckResult(
        id: '$id.${path.replaceAll('/', '_')}',
        title: path,
        category: category,
        severity: severity,
        description: note,
        evidence: [trimmed],
        timestamp: now,
      ));
    }
    return results;
  }
}
