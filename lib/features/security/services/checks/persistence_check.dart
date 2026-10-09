import '../../../connections/models/connection_profile.dart';
import '../../../ssh/models/host_key_verification.dart';
import '../../../ssh/services/ssh_service.dart';
import '../../models/security_check_result.dart';
import '../security_check.dart';

/// Inspects common persistence/startup mechanisms: cron, systemd timers,
/// and SSH authorized_keys. A cron job or timer running from an unusual
/// location (e.g. /tmp) is flagged REVIEW — never labeled malware — per
/// the brief's explicit instruction.
class PersistenceCheck implements SecurityCheck {
  @override
  String get id => 'persistence';
  @override
  String get title => 'Persistence & Startup';
  @override
  SecurityCategory get category => SecurityCategory.persistence;

  static const _suspiciousPathHints = ['/tmp/', '/dev/shm/', '/var/tmp/'];

  @override
  Future<List<SecurityCheckResult>> run(
    ConnectionProfile profile,
    SshService sshService,
    HostKeyDecisionHandler onHostKeyVerification,
  ) async {
    Future<String?> read(String cmd) => runReadOnly(profile, sshService, onHostKeyVerification, cmd);
    final now = DateTime.now();
    final results = <SecurityCheckResult>[];

    final cron = await read(
      r'for u in $(cut -f1 -d: /etc/passwd); do crontab -l -u $u 2>/dev/null | sed "s/^/$u: /"; done; '
      'cat /etc/crontab 2>/dev/null; ls /etc/cron.d/ 2>/dev/null',
    );
    if (cron != null && cron.trim().isNotEmpty) {
      final lines = cron.split('\n').where((l) => l.trim().isNotEmpty && !l.trim().startsWith('#')).toList();
      final suspicious = lines.where((l) => _suspiciousPathHints.any((p) => l.contains(p))).toList();
      results.add(SecurityCheckResult(
        id: '$id.cron',
        title: 'Cron jobs',
        category: category,
        severity: suspicious.isNotEmpty ? SecuritySeverity.review : SecuritySeverity.info,
        description: suspicious.isNotEmpty
            ? 'One or more cron entries reference a temporary/world-writable directory. Review the '
                'command and confirm it is expected — this is not automatically malicious.'
            : 'Cron jobs enumerated for all local users plus system crontab.',
        evidence: (suspicious.isNotEmpty ? suspicious : lines).take(20).toList(),
        timestamp: now,
      ));
    }

    final timers = await read('systemctl list-timers --all --no-legend --plain 2>/dev/null');
    if (timers != null && timers.trim().isNotEmpty) {
      results.add(SecurityCheckResult(
        id: '$id.timers',
        title: 'Systemd timers',
        category: category,
        severity: SecuritySeverity.info,
        description: 'Systemd timer units, a common cron alternative.',
        evidence: timers.split('\n').where((l) => l.trim().isNotEmpty).take(20).toList(),
        timestamp: now,
      ));
    }

    final authorizedKeys = await read(
      r"for f in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do "
      r'[ -f "$f" ] && echo "== $f ==" && cat "$f"; done 2>/dev/null',
    );
    if (authorizedKeys != null && authorizedKeys.trim().isNotEmpty) {
      final keyLines = <String>[];
      for (final line in authorizedKeys.split('\n')) {
        if (line.startsWith('==')) {
          keyLines.add(line);
        } else if (line.trim().isNotEmpty) {
          final parts = line.trim().split(' ');
          final type = parts.isNotEmpty ? parts[0] : 'unknown';
          final comment = parts.length > 2 ? parts.sublist(2).join(' ') : '(no comment)';
          keyLines.add('  $type ... $comment');
        }
      }
      results.add(SecurityCheckResult(
        id: '$id.authorizedkeys',
        title: 'SSH authorized_keys',
        category: category,
        severity: SecuritySeverity.info,
        description: 'Public keys authorized to log in as each user (private key material is never read or shown).',
        evidence: keyLines.take(30).toList(),
        timestamp: now,
      ));
    }

    if (results.isEmpty) {
      results.add(SecurityCheckResult(
        id: id,
        title: title,
        category: category,
        severity: SecuritySeverity.info,
        description: 'No cron, timer, or authorized_keys data could be read.',
        evidence: const [],
        timestamp: now,
      ));
    }

    return results;
  }
}
