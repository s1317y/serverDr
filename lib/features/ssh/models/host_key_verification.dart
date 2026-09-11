import 'package:flutter/foundation.dart';

/// What the user decided when asked to verify a host key.
enum HostKeyDecision {
  /// Persist trust for this host:port going forward (writes to
  /// [HostKeyStore]).
  trust,

  /// Connect this one time only, without persisting trust. Matches the
  /// Stitch "Connect Once (Ephemeral)" option.
  trustOnce,

  /// Abort the connection.
  reject,
}

/// Raised by [SshService]/[SftpService] when a host's key needs a user
/// decision — either never seen before, or changed since it was last
/// trusted. The caller (a screen) shows the appropriate UI and resolves
/// with a [HostKeyDecision]; the service itself never decides.
@immutable
class HostKeyVerificationRequest {
  const HostKeyVerificationRequest({
    required this.host,
    required this.port,
    required this.keyType,
    required this.fingerprint,
    this.previousFingerprint,
  });

  final String host;
  final int port;
  final String keyType;
  final String fingerprint;

  /// Non-null only when this is a CHANGED key, not a first-sighting.
  final String? previousFingerprint;

  bool get isChanged => previousFingerprint != null;
}

/// Supplied by the UI layer to any service call that might need to pause
/// for host-key verification.
typedef HostKeyDecisionHandler = Future<HostKeyDecision> Function(HostKeyVerificationRequest request);
