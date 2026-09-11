import 'package:flutter/material.dart';

/// The fixed set of error states the product brief calls out explicitly.
/// Every service (SSH/SFTP/FTP/transfers) surfaces failures through this
/// enum so the UI has one place (`ErrorStateView`) that knows how to
/// render *and* recover from each one, instead of ad hoc error widgets
/// per feature.
enum AppFailureKind {
  connectionRefused,
  authenticationFailed,
  hostUnreachable,
  permissionDenied,
  fileNotFound,
  transferFailed,
  hostKeyChanged,
  unsupportedOperation,
  disconnected,
  dnsFailure,
  timeout,
  invalidPrivateKey,
  incorrectPassphrase,
  remoteFileChanged,
  transferInterrupted,
  connectionDropped,
  unknown,
}

/// A recovery action offered on an [ErrorStateView] — e.g. "Retry",
/// "Reconnect", "Edit Connection", "Cancel". The action itself
/// (navigation, retrying a service call, ...) is supplied by the screen
/// that throws the failure; this class only carries the label + callback.
@immutable
class RecoveryAction {
  const RecoveryAction({required this.label, required this.onPressed, this.isPrimary = false});

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
}

/// A typed failure raised by any mock or (later) real service.
@immutable
class AppFailure implements Exception {
  const AppFailure(this.kind, {this.message, this.detail});

  final AppFailureKind kind;

  /// Optional human-readable override; otherwise [AppFailure.defaultTitle]
  /// is used.
  final String? message;

  /// Optional extra technical detail (e.g. the raw errno/host) shown in
  /// smaller text under the title. Callers MUST NOT put credentials or
  /// private-key material here — this can end up on screen and, if the
  /// failure is ever logged, in logs. See the sanitization helper next to
  /// each real service's exception mapping.
  final String? detail;

  String get title => message ?? defaultTitle(kind);

  static String defaultTitle(AppFailureKind kind) => switch (kind) {
        AppFailureKind.connectionRefused => 'Connection refused',
        AppFailureKind.authenticationFailed => 'Authentication failed',
        AppFailureKind.hostUnreachable => 'Host unreachable',
        AppFailureKind.permissionDenied => 'Permission denied',
        AppFailureKind.fileNotFound => 'File not found',
        AppFailureKind.transferFailed => 'Transfer failed',
        AppFailureKind.hostKeyChanged => 'Host key changed',
        AppFailureKind.unsupportedOperation => 'Unsupported operation',
        AppFailureKind.disconnected => 'Disconnected',
        AppFailureKind.dnsFailure => 'DNS lookup failed',
        AppFailureKind.timeout => 'Connection timed out',
        AppFailureKind.invalidPrivateKey => 'Invalid private key',
        AppFailureKind.incorrectPassphrase => 'Incorrect passphrase',
        AppFailureKind.remoteFileChanged => 'Remote file changed',
        AppFailureKind.transferInterrupted => 'Transfer interrupted',
        AppFailureKind.connectionDropped => 'Connection dropped',
        AppFailureKind.unknown => 'Something went wrong',
      };

  static IconData iconFor(AppFailureKind kind) => switch (kind) {
        AppFailureKind.connectionRefused => Icons.block,
        AppFailureKind.authenticationFailed => Icons.key_off,
        AppFailureKind.hostUnreachable => Icons.signal_wifi_off,
        AppFailureKind.permissionDenied => Icons.lock_outline,
        AppFailureKind.fileNotFound => Icons.search_off,
        AppFailureKind.transferFailed => Icons.sync_problem,
        AppFailureKind.hostKeyChanged => Icons.warning_amber,
        AppFailureKind.unsupportedOperation => Icons.block_flipped,
        AppFailureKind.disconnected => Icons.link_off,
        AppFailureKind.dnsFailure => Icons.dns_outlined,
        AppFailureKind.timeout => Icons.hourglass_disabled,
        AppFailureKind.invalidPrivateKey => Icons.vpn_key_off,
        AppFailureKind.incorrectPassphrase => Icons.password,
        AppFailureKind.remoteFileChanged => Icons.sync_problem,
        AppFailureKind.transferInterrupted => Icons.cloud_off,
        AppFailureKind.connectionDropped => Icons.wifi_off,
        AppFailureKind.unknown => Icons.error_outline,
      };

  @override
  String toString() => 'AppFailure(${kind.name}${detail != null ? ': $detail' : ''})';
}
