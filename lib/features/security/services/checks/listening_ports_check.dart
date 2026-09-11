import '../../../connections/models/connection_profile.dart';
import '../../../ssh/models/host_key_verification.dart';
import '../../../ssh/services/ssh_service.dart';
import '../../models/security_check_result.dart';
import '../security_check.dart';

/// Lists listening TCP/UDP sockets via `ss` and classifies each by bind
/// address only (Local vs Public) — per the brief, an open/public port is
/// NOT automatically flagged as a vulnerability, just labeled so the
/// admin can judge whether it's intentional.
class ListeningPortsCheck implements SecurityCheck {
  @override
  String get id => 'listening_ports';
  @override
  String get title => 'Listening Sockets';
  @override
  SecurityCategory get category => SecurityCategory.network;

  static const _sensitivePorts = {
    3306: 'MySQL',
    5432: 'PostgreSQL',
    6379: 'Redis',
    27017: 'MongoDB',
    9200: 'Elasticsearch',
    2379: 'etcd',
  };

  @override
  Future<List<SecurityCheckResult>> run(
    ConnectionProfile profile,
    SshService sshService,
    HostKeyDecisionHandler onHostKeyVerification,
  ) async {
    final raw = await runReadOnly(profile, sshService, onHostKeyVerification, 'ss -tulpn 2>/dev/null');
    final now = DateTime.now();

    if (raw == null || raw.trim().isEmpty) {
      return [
        SecurityCheckResult(
          id: id,
          title: title,
          category: category,
          severity: SecuritySeverity.info,
          description: "Couldn't enumerate listening sockets (ss unavailable or permission denied).",
          evidence: const [],
          timestamp: now,
        ),
      ];
    }

    final evidence = <String>[];
    var publicSensitiveCount = 0;
    for (final line in raw.split('\n').skip(1)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final cols = trimmed.split(RegExp(r'\s+'));
      if (cols.length < 5) continue;
      final localAddr = cols[4];
      final portMatch = RegExp(r':(\d+)$').firstMatch(localAddr);
      final port = portMatch != null ? int.tryParse(portMatch.group(1)!) : null;
      final isPublicBind = localAddr.startsWith('0.0.0.0') || localAddr.startsWith('*') || localAddr.startsWith(':::');

      if (port != null && _sensitivePorts.containsKey(port) && isPublicBind) {
        publicSensitiveCount++;
        evidence.add('$localAddr (${_sensitivePorts[port]}) — bound to all interfaces');
      } else {
        evidence.add(localAddr);
      }
    }

    return [
      SecurityCheckResult(
        id: id,
        title: title,
        category: category,
        severity: publicSensitiveCount > 0 ? SecuritySeverity.review : SecuritySeverity.info,
        description: publicSensitiveCount > 0
            ? 'One or more data-service ports (database/cache) are bound to all interfaces rather than '
                'localhost. This is common in containerized/internal-network setups and is not automatically '
                'a vulnerability — verify this port is reachable only from trusted networks.'
            : 'Listening sockets enumerated. No data-service ports were found bound to all interfaces.',
        evidence: evidence.take(20).toList(),
        timestamp: now,
        metadata: {'total': '${evidence.length}'},
      ),
    ];
  }
}
