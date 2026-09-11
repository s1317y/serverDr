import '../../connections/models/connection_profile.dart';
import '../models/host_key_verification.dart';
import '../models/ssh_session_state.dart';

/// One live (or previously live) SSH connection to a single server.
///
/// The terminal screen depends only on this interface — never on a
/// specific SSH library. [RealSshService]/`RealSshSession` (dartssh2)
/// fulfil it for Android/iOS/desktop today.
///
/// NOTE ON SHAPE: unlike the Phase 1 mock, [output] is a raw byte stream,
/// not a list of structured "entries". A real interactive shell's output
/// contains ANSI/VT100 escape sequences (cursor movement, color, screen
/// clearing, ...) that only make sense interpreted by a real terminal
/// emulator — see the `xterm` package usage in `TerminalScreen`. Trying
/// to model that as discrete "lines" (as the old mock did) cannot
/// correctly represent a real shell.
abstract interface class SshSession {
  ConnectionProfile get profile;

  SshSessionState get state;
  Stream<SshSessionState> get stateStream;

  /// Merged stdout+stderr byte stream from the remote pty.
  Stream<List<int>> get output;

  /// Writes a line to the remote shell's stdin, ending with `\n` — used
  /// by the command input bar's EXEC action.
  Future<void> sendLine(String line);

  /// Writes raw bytes directly to stdin — used by the terminal key bar
  /// for control sequences (^C, ^D, arrow keys, ...) that must not be
  /// line-buffered.
  Future<void> sendRaw(List<int> bytes);

  /// Informs the remote pty of the current terminal size so full-screen
  /// programs (vim, htop, ...) render correctly.
  Future<void> resize(int columns, int rows, [int pixelWidth = 0, int pixelHeight = 0]);

  Future<void> close();
}

/// Opens and tracks [SshSession]s. The connections list / header selector
/// asks this for a session when the user picks "Terminal" for a server.
abstract interface class SshService {
  /// Returns an existing live session for [profile] if one is open,
  /// otherwise opens a new one. [onHostKeyVerification] is invoked if (and
  /// only if) the host's key is unknown or has changed — the caller
  /// supplies the UI for that and returns the user's decision.
  Future<SshSession> connect(
    ConnectionProfile profile, {
    required HostKeyDecisionHandler onHostKeyVerification,
  });

  SshSession? sessionFor(String connectionId);

  Future<void> disconnect(String connectionId);

  /// One-shot connect-and-authenticate check with no interactive shell —
  /// backs the "Test Connection" action in the Add/Edit Server screen.
  /// Completes normally on success; throws an [AppFailure] on any of the
  /// documented failure kinds. Optional overrides let the editor test
  /// credentials the user just typed before they're saved anywhere.
  Future<void> testConnection(
    ConnectionProfile profile, {
    required HostKeyDecisionHandler onHostKeyVerification,
    String? passwordOverride,
    String? privateKeyOverride,
    String? passphraseOverride,
  });

  /// Runs a single read-only (or explicitly confirmed) command over its
  /// OWN exec channel on the SAME underlying SSH connection as the
  /// interactive terminal for this profile, if one is open — a real SSH
  /// connection multiplexes independent channels, so this never blocks
  /// or interleaves with the terminal's shell channel. If no session is
  /// open yet, a background (shell-less) connection is opened and kept
  /// alive for reuse by subsequent Health/Security calls, rather than
  /// reconnecting on every check. Used by `HealthService`/`SecurityService`
  /// — never called directly from widgets.
  Future<String> runCommand(
    ConnectionProfile profile,
    String command, {
    required HostKeyDecisionHandler onHostKeyVerification,
    Duration timeout = const Duration(seconds: 12),
  });
}
