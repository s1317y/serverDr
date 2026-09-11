import '../../../connections/models/connection_profile.dart';
import '../../../ssh/models/host_key_verification.dart';
import '../../../ssh/services/ssh_service.dart';
import '../../models/security_check_result.dart';
import '../security_check.dart';

/// Analyzes available authentication logs for failed/successful SSH
/// attempts, invalid users, and root logins.
///
/// Detects the log source rather than assuming one distro: tries
/// `/var/log/auth.log` (Debian/Ubuntu) then `/var/log/secure`
/// (RHEL/CentOS/Alma/Rocky) then falls back to `journalctl` (any systemd
/// host with no on-disk auth log, e.g. journald-only setups).
///
/// Severity policy: this NEVER emits [SecuritySeverity.critical] on its
/// own — "many failed attempts" is exactly the kind of finding the brief
/// says must stay at REVIEW/WARNING with a hedged description ("multiple
/// failed authentication attempts were observed"), not an upgraded claim
/// like "brute-force attack confirmed."
class AuthenticationCheck implements SecurityCheck {
  @override
  String get id => 'authentication';
  @override
  String get title => 'Authentication & Access';
  @override
  SecurityCategory get category => SecurityCategory.authentication;

  @override
  Future<List<SecurityCheckResult>> run(
    ConnectionProfile profile,
    SshService sshService,
    HostKeyDecisionHandler onHostKeyVerification,
  ) async {
    Future<String?> read(String cmd) => runReadOnly(profile, sshService, onHostKeyVerification, cmd);

    String? raw = await read('tail -n 2000 /var/log/auth.log 2>/dev/null');
    if (raw == null || raw.trim().isEmpty) {
      raw = await read('tail -n 2000 /var/log/secure 2>/dev/null');
    }
    if (raw == null || raw.trim().isEmpty) {
      raw = await read('journalctl -u sshd -n 2000 --no-pager 2>/dev/null');
    }

    final now = DateTime.now();
    if (raw == null || raw.trim().isEmpty) {
      return [
        SecurityCheckResult(
          id: id,
          title: title,
          category: category,
          severity: SecuritySeverity.info,
          description: 'No readable authentication log source was found '
              '(checked /var/log/auth.log, /var/log/secure, and the sshd journal).',
          evidence: const [],
          timestamp: now,
        ),
      ];
    }

    final lines = raw.split('\n');
    final failed = lines.where((l) => l.contains('Failed password') || l.contains('authentication failure')).toList();
    final invalidUsers = lines.where((l) => l.contains('Invalid user')).toList();
    final accepted = lines.where((l) => l.contains('Accepted password') || l.contains('Accepted publickey')).toList();
    final rootLogins = accepted.where((l) => l.contains(' root ')).toList();
    final sudoActivity = lines.where((l) => l.contains('sudo:') && l.contains('COMMAND=')).toList();

    final results = <SecurityCheckResult>[];

    results.add(SecurityCheckResult(
      id: '$id.failed',
      title: 'Failed SSH attempts',
      category: category,
      severity: failed.length > 20
          ? SecuritySeverity.warning
          : failed.isNotEmpty
              ? SecuritySeverity.review
              : SecuritySeverity.pass,
      description: failed.isEmpty
          ? 'No failed SSH authentication attempts found in the sampled log window.'
          : 'Multiple failed authentication attempts were observed in the sampled log window. '
              'This alone does not confirm an attack — review the source IPs and timing.',
      evidence: failed.take(10).toList(),
      timestamp: now,
      metadata: {'count': '${failed.length}'},
    ));

    if (invalidUsers.isNotEmpty) {
      results.add(SecurityCheckResult(
        id: '$id.invalidUsers',
        title: 'Login attempts for non-existent users',
        category: category,
        severity: SecuritySeverity.review,
        description: 'Attempts to log in as usernames that do not exist on this server were observed. '
            'Common with automated scanning; review source IPs if frequent.',
        evidence: invalidUsers.take(10).toList(),
        timestamp: now,
        metadata: {'count': '${invalidUsers.length}'},
      ));
    }

    if (rootLogins.isNotEmpty) {
      results.add(SecurityCheckResult(
        id: '$id.rootLogins',
        title: 'Direct root logins',
        category: category,
        severity: SecuritySeverity.review,
        description: 'One or more successful direct logins as root were observed. '
            'Many teams prefer login as a normal user plus sudo — review whether this is expected.',
        evidence: rootLogins.take(10).toList(),
        timestamp: now,
        metadata: {'count': '${rootLogins.length}'},
      ));
    }

    if (sudoActivity.isNotEmpty) {
      results.add(SecurityCheckResult(
        id: '$id.sudo',
        title: 'Sudo activity',
        category: category,
        severity: SecuritySeverity.info,
        description: 'Recent sudo command usage in the sampled log window.',
        evidence: sudoActivity.take(10).toList(),
        timestamp: now,
        metadata: {'count': '${sudoActivity.length}'},
      ));
    }

    return results;
  }
}
