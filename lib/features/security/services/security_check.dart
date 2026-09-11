import '../../connections/models/connection_profile.dart';
import '../../ssh/models/host_key_verification.dart';
import '../../ssh/services/ssh_service.dart';
import '../models/security_check_result.dart';

/// One independent, self-contained security check. Each implementation
/// owns its own command(s) and parsing — the brief's "UI should never
/// need to parse shell output" boundary lives here, not in the service.
///
/// Every check is read-only. None of the checks implemented so far
/// require confirmation to RUN (they don't change server state) — that
/// requirement applies to remediation actions a future phase might add
/// (e.g. "disable password auth"), not to running the check itself.
abstract interface class SecurityCheck {
  String get id;
  String get title;
  SecurityCategory get category;

  Future<List<SecurityCheckResult>> run(
    ConnectionProfile profile,
    SshService sshService,
    HostKeyDecisionHandler onHostKeyVerification,
  );
}

/// Shared helper so every check fails the same safe way (a REVIEW finding
/// explaining the command didn't run) instead of throwing and aborting
/// the whole scan.
Future<String?> runReadOnly(
  ConnectionProfile profile,
  SshService sshService,
  HostKeyDecisionHandler onHostKeyVerification,
  String command,
) async {
  try {
    return await sshService.runCommand(profile, command, onHostKeyVerification: onHostKeyVerification);
  } catch (_) {
    return null;
  }
}
