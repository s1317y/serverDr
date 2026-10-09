import '../../../connections/models/connection_profile.dart';
import '../../../ssh/models/host_key_verification.dart';
import '../../../ssh/services/ssh_service.dart';
import '../../models/security_check_result.dart';
import '../security_check.dart';

/// Basic Docker security posture check. Never requires Docker to be
/// installed — reports "Not available" rather than erroring when it
/// isn't found, per the brief.
class DockerCheck implements SecurityCheck {
  @override
  String get id => 'docker';
  @override
  String get title => 'Docker';
  @override
  SecurityCategory get category => SecurityCategory.docker;

  @override
  Future<List<SecurityCheckResult>> run(
    ConnectionProfile profile,
    SshService sshService,
    HostKeyDecisionHandler onHostKeyVerification,
  ) async {
    Future<String?> read(String cmd) => runReadOnly(profile, sshService, onHostKeyVerification, cmd);
    final now = DateTime.now();

    final dockerPresent = await read('command -v docker');
    if (dockerPresent == null || dockerPresent.trim().isEmpty) {
      return [
        SecurityCheckResult(
          id: id,
          title: title,
          category: category,
          severity: SecuritySeverity.info,
          description: 'Docker is not installed on this server.',
          evidence: const [],
          timestamp: now,
        ),
      ];
    }

    final results = <SecurityCheckResult>[];
    final containers = await read('docker ps --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null');
    results.add(SecurityCheckResult(
      id: '$id.containers',
      title: 'Running containers',
      category: category,
      severity: SecuritySeverity.info,
      description: containers == null || containers.trim().isEmpty
          ? 'Docker is installed but no containers are currently running.'
          : 'Currently running containers and their published ports.',
      evidence: (containers ?? '').split('\n').where((l) => l.trim().isNotEmpty).toList(),
      timestamp: now,
    ));

    // A container running with `--privileged` has effectively no
    // isolation from the host — this is worth surfacing but is often
    // intentional (e.g. some monitoring/CI containers), so REVIEW not
    // WARNING.
    final privileged = await read(
      r'''for c in $(docker ps -q 2>/dev/null); do docker inspect --format '{{.Name}}: Privileged={{.HostConfig.Privileged}}' "$c" 2>/dev/null; done''',
    );
    if (privileged != null && privileged.contains('Privileged=true')) {
      results.add(SecurityCheckResult(
        id: '$id.privileged',
        title: 'Privileged containers',
        category: category,
        severity: SecuritySeverity.review,
        description: 'One or more running containers have `--privileged` set, which removes most container '
            'isolation from the host. Confirm this is intentional for that workload.',
        evidence: privileged.split('\n').where((l) => l.contains('Privileged=true')).toList(),
        timestamp: now,
      ));
    }

    return results;
  }
}
