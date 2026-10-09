import '../../../connections/models/connection_profile.dart';
import '../../../ssh/models/host_key_verification.dart';
import '../../../ssh/services/ssh_service.dart';
import '../../models/security_check_result.dart';
import '../security_check.dart';

/// Inspects the EFFECTIVE sshd configuration via `sshd -T` (which
/// resolves includes and defaults, unlike grepping the raw config file)
/// where the connected user has permission to run it, falling back to a
/// direct read of `/etc/ssh/sshd_config` otherwise.
///
/// Every setting here is reported as PASS or REVIEW with the literal
/// config line as evidence — never "vulnerable"/"insecure", since
/// whether e.g. password auth should be disabled depends on context this
/// tool doesn't have.
class SshConfigCheck implements SecurityCheck {
  @override
  String get id => 'ssh_config';
  @override
  String get title => 'SSH Daemon Hardening';
  @override
  SecurityCategory get category => SecurityCategory.ssh;

  @override
  Future<List<SecurityCheckResult>> run(
    ConnectionProfile profile,
    SshService sshService,
    HostKeyDecisionHandler onHostKeyVerification,
  ) async {
    Future<String?> read(String cmd) => runReadOnly(profile, sshService, onHostKeyVerification, cmd);

    String? raw = await read('sshd -T 2>/dev/null');
    if (raw == null || raw.trim().isEmpty) {
      raw = await read(
        "grep -Ei '^(permitrootlogin|passwordauthentication|pubkeyauthentication|permitemptypasswords|protocol|x11forwarding)' "
        "/etc/ssh/sshd_config 2>/dev/null",
      );
    }

    final now = DateTime.now();
    if (raw == null || raw.trim().isEmpty) {
      return [
        SecurityCheckResult(
          id: id,
          title: title,
          category: category,
          severity: SecuritySeverity.info,
          description: "Couldn't read the SSH daemon configuration (sshd -T and sshd_config both unavailable "
              'to this account).',
          evidence: const [],
          timestamp: now,
        ),
      ];
    }

    final settings = <String, String>{};
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      settings[parts[0].toLowerCase()] = parts.sublist(1).join(' ');
    }

    final results = <SecurityCheckResult>[];

    void addCheck(String key, String friendlyName, {required bool reviewIf, String? recommendedAction}) {
      final value = settings[key];
      if (value == null) return;
      final isReview = reviewIf;
      results.add(SecurityCheckResult(
        id: '$id.$key',
        title: friendlyName,
        category: category,
        severity: isReview ? SecuritySeverity.review : SecuritySeverity.pass,
        description: isReview
            ? '$friendlyName is set to "$value". Review whether this matches your intended posture.'
            : '$friendlyName is set to "$value".',
        evidence: ['$key $value'],
        timestamp: now,
        command: 'sshd -T | grep $key',
        recommendedAction: isReview ? recommendedAction : null,
      ));
    }

    addCheck(
      'permitrootlogin',
      'Root login',
      reviewIf: settings['permitrootlogin'] != 'no',
      recommendedAction: 'Consider disabling direct root login and using sudo from a named account after confirming access.',
    );
    addCheck(
      'passwordauthentication',
      'Password authentication',
      reviewIf: settings['passwordauthentication'] == 'yes',
      recommendedAction: 'Consider disabling password authentication after confirming SSH key access works.',
    );
    addCheck(
      'pubkeyauthentication',
      'Public key authentication',
      reviewIf: settings['pubkeyauthentication'] == 'no',
      recommendedAction: 'Consider enabling public key authentication as a stronger alternative to passwords.',
    );
    addCheck(
      'permitemptypasswords',
      'Empty passwords',
      reviewIf: settings['permitemptypasswords'] != 'no',
      recommendedAction: 'Disable empty password logins unless there is a specific, understood reason to allow them.',
    );
    addCheck(
      'x11forwarding',
      'X11 forwarding',
      reviewIf: settings['x11forwarding'] == 'yes',
      recommendedAction: 'Consider disabling X11 forwarding if graphical forwarding over SSH is not needed.',
    );

    if (results.isEmpty) {
      results.add(SecurityCheckResult(
        id: id,
        title: title,
        category: category,
        severity: SecuritySeverity.info,
        description: 'SSH configuration was read but none of the inspected directives were present/parseable.',
        evidence: [raw.trim()],
        timestamp: now,
      ));
    }

    return results;
  }
}
