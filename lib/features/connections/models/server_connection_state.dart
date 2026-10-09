/// Real, live connection state for one saved server — owned entirely by
/// [ServerConnectionManager], never inferred from "this profile exists in
/// the saved list" (that was the bug: a saved server is NOT a connected
/// server).
enum ServerConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  connectionFailed,
  authenticationFailed,
  hostVerificationRequired;

  String get label => switch (this) {
        ServerConnectionState.disconnected => 'Disconnected',
        ServerConnectionState.connecting => 'Connecting',
        ServerConnectionState.connected => 'Connected',
        ServerConnectionState.reconnecting => 'Reconnecting',
        ServerConnectionState.connectionFailed => 'Connection Failed',
        ServerConnectionState.authenticationFailed => 'Authentication Failed',
        ServerConnectionState.hostVerificationRequired => 'Host Verification Required',
      };

  bool get isLive => this == ServerConnectionState.connected || this == ServerConnectionState.reconnecting;
  bool get isTransient => this == ServerConnectionState.connecting || this == ServerConnectionState.reconnecting;
  bool get isFailure => this == ServerConnectionState.connectionFailed ||
      this == ServerConnectionState.authenticationFailed ||
      this == ServerConnectionState.hostVerificationRequired;
}
