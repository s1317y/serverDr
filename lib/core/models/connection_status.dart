import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Shared connection lifecycle used by SSH, SFTP and FTP session state.
///
/// This is intentionally coarse — individual services (e.g. [SshService])
/// may layer more specific states on top, but everything the UI needs to
/// pick a status dot color / label collapses to one of these.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  authenticationFailed,
  error;

  Color get dotColor => switch (this) {
        ConnectionStatus.connected => AppColors.secondary,
        ConnectionStatus.connecting => AppColors.tertiary,
        ConnectionStatus.disconnected => AppColors.outline,
        ConnectionStatus.authenticationFailed => AppColors.error,
        ConnectionStatus.error => AppColors.error,
      };

  String get label => switch (this) {
        ConnectionStatus.connected => 'Connected',
        ConnectionStatus.connecting => 'Connecting',
        ConnectionStatus.disconnected => 'Disconnected',
        ConnectionStatus.authenticationFailed => 'Authentication Failed',
        ConnectionStatus.error => 'Connection Error',
      };
}
