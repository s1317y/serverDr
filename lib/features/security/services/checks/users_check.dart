import '../../../connections/models/connection_profile.dart';
import '../../../ssh/models/host_key_verification.dart';
import '../../../ssh/services/ssh_service.dart';
import '../../models/security_check_result.dart';
import '../security_check.dart';

/// Audits local user accounts: UID 0 accounts, sudo-capable users, and
/// locked accounts. Never assumes an unfamiliar account is malicious —
/// unusual findings (e.g. a second UID 0 account) are REVIEW with the
/// evidence shown, not an accusation.
class UsersCheck implements SecurityCheck {
  @override
  String get id => 'users';
  @override
  String get title => 'User Accounts';
  @override
  SecurityCategory get category => SecurityCategory.users;

  @override
  Future<List<SecurityCheckResult>> run(
    ConnectionProfile profile,
    SshService sshService,
    HostKeyDecisionHandler onHostKeyVerification,
  ) async {
    Future<String?> read(String cmd) => runReadOnly(profile, sshService, onHostKeyVerification, cmd);
    final now = DateTime.now();
    final results = <SecurityCheckResult>[];

    final passwd = await read('getent passwd');
    if (passwd == null || passwd.trim().isEmpty) {
      return [
        SecurityCheckResult(
          id: id,
          title: title,
          category: category,
          severity: SecuritySeverity.info,
          description: "Couldn't read the local account list (getent unavailable or permission denied).",
          evidence: const [],
          timestamp: now,
        ),
      ];
    }

    final uidZero = <String>[];
    final loginCapable = <String>[];
    for (final line in passwd.split('\n')) {
      final cols = line.split(':');
      if (cols.length < 7) continue;
      final username = cols[0];
      final uid = cols[2];
      final shell = cols[6];
      final noLoginShells = {'/usr/sbin/nologin', '/sbin/nologin', '/bin/false', '/usr/bin/false'};
      if (uid == '0') uidZero.add('$username (uid 0, shell $shell)');
      if (!noLoginShells.contains(shell.trim())) loginCapable.add('$username ($shell)');
    }

    results.add(SecurityCheckResult(
      id: '$id.uid0',
      title: 'UID 0 accounts',
      category: category,
      severity: uidZero.length > 1 ? SecuritySeverity.review : SecuritySeverity.pass,
      description: uidZero.length > 1
          ? 'More than one account has UID 0 (root-equivalent privileges). Confirm this is intentional.'
          : 'Only the expected root account has UID 0.',
      evidence: uidZero,
      timestamp: now,
    ));

    results.add(SecurityCheckResult(
      id: '$id.logincapable',
      title: 'Login-capable accounts',
      category: category,
      severity: SecuritySeverity.info,
      description: 'Accounts with an interactive shell (can potentially log in).',
      evidence: loginCapable.take(20).toList(),
      timestamp: now,
      metadata: {'count': '${loginCapable.length}'},
    ));

    final sudoers = await read('getent group sudo wheel 2>/dev/null');
    if (sudoers != null && sudoers.trim().isNotEmpty) {
      results.add(SecurityCheckResult(
        id: '$id.sudo',
        title: 'Sudo-capable groups',
        category: category,
        severity: SecuritySeverity.info,
        description: 'Members of the sudo/wheel administrative groups.',
        evidence: sudoers.split('\n').where((l) => l.trim().isNotEmpty).toList(),
        timestamp: now,
      ));
    }

    final locked = await read(
      r"awk -F: '($2 ~ /^!/ || $2 ~ /^\*/) {print $1}' /etc/shadow 2>/dev/null",
    );
    if (locked != null && locked.trim().isNotEmpty) {
      results.add(SecurityCheckResult(
        id: '$id.locked',
        title: 'Locked accounts',
        category: category,
        severity: SecuritySeverity.info,
        description: 'Accounts with a locked/disabled password.',
        evidence: locked.split('\n').where((l) => l.trim().isNotEmpty).toList(),
        timestamp: now,
      ));
    }

    return results;
  }
}
