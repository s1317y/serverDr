/// Full SSH connection lifecycle, as specified by the brief — richer than
/// the coarse [ConnectionStatus] shared with SFTP, because SSH alone has
/// a host-verification step that can pause the connect flow waiting on
/// the user.
enum SshSessionState {
  idle,
  connecting,
  hostVerificationRequired,
  authenticating,
  connected,
  disconnecting,
  disconnected,
  authenticationFailed,
  connectionFailed,
  hostKeyChanged;

  bool get isTerminalFailure =>
      this == authenticationFailed || this == connectionFailed || this == hostKeyChanged;
}
