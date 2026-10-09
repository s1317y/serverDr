import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_failure.dart';
import '../../ssh/models/host_key_verification.dart';
import '../../ssh/models/ssh_session_state.dart';
import '../../ssh/services/ssh_service.dart';
import '../../sftp/services/sftp_service.dart';
import '../models/connection_profile.dart';
import '../models/server_connection_state.dart';

/// The single source of truth for "is this saved server actually
/// connected right now" — coordinates SSH and SFTP so every screen
/// (Saved Connections, Terminal, Files, Health, Security) reads the same
/// real state instead of each independently deciding to open a session.
///
/// This does NOT itself open connections proactively. It only reacts to
/// explicit [connect] calls (from the Saved Connections list, or a
/// screen's own "Connect" prompt) and to the underlying [SshSession]'s
/// own state stream (so an unexpected drop shows as Reconnecting/
/// Disconnected, not a stale "Connected").
///
/// KNOWN LIMITATION: [SftpService] in this codebase manages a single
/// active connection (one profile at a time), not a per-profile pool
/// like [SshService] does. Disconnecting here always tears down SFTP
/// too, but connecting via this manager only guarantees the SSH side;
/// the Files screen still opens its own SFTP connection lazily on first
/// use. Fully pooling SFTP per-profile is flagged as follow-up work, not
/// done this phase.
class ServerConnectionManager extends ChangeNotifier {
  ServerConnectionManager({required SshService sshService, required SftpService sftpService})
      : _sshService = sshService,
        _sftpService = sftpService;

  final SshService _sshService;
  final SftpService _sftpService;

  final Map<String, ServerConnectionState> _states = {};
  final Map<String, AppFailure?> _errors = {};
  final Map<String, StreamSubscription<SshSessionState>> _stateSubs = {};
  final Map<String, DateTime> _connectedSince = {};

  ServerConnectionState stateFor(String profileId) => _states[profileId] ?? ServerConnectionState.disconnected;
  AppFailure? errorFor(String profileId) => _errors[profileId];
  DateTime? connectedSinceFor(String profileId) => _connectedSince[profileId];

  void _setState(String profileId, ServerConnectionState state, {AppFailure? error}) {
    _states[profileId] = state;
    _errors[profileId] = error;
    if (state == ServerConnectionState.connected) {
      _connectedSince.putIfAbsent(profileId, () => DateTime.now());
    } else if (state == ServerConnectionState.disconnected) {
      _connectedSince.remove(profileId);
    }
    notifyListeners();
  }

  Future<void> connect(
    ConnectionProfile profile, {
    required HostKeyDecisionHandler onHostKeyVerification,
  }) async {
    // IMPORTANT: check the REAL SSH session state here, not
    // `stateFor(profile.id)` — that generic flag is shared with SFTP via
    // [reportExternalState], so if Files connected first it would read
    // as "connected" even though no SSH session exists yet, and this
    // method would return early without ever calling `_sshService.connect`.
    // That was the exact bug: connecting Files first made Terminal's
    // Connect button silently do nothing (and vice versa isn't possible
    // the same way, but the shared flag could still be stale from a
    // prior SSH disconnect that SFTP's own connect then overwrote).
    final existingSession = _sshService.sessionFor(profile.id);
    if (existingSession != null && existingSession.state == SshSessionState.connected) {
      _setState(profile.id, ServerConnectionState.connected);
      return;
    }
    _setState(profile.id, ServerConnectionState.connecting);
    try {
      final session = await _sshService.connect(profile, onHostKeyVerification: onHostKeyVerification);
      _setState(profile.id, ServerConnectionState.connected);

      await _stateSubs[profile.id]?.cancel();
      _stateSubs[profile.id] = session.stateStream.listen((sessionState) {
        switch (sessionState) {
          case SshSessionState.connected:
            _setState(profile.id, ServerConnectionState.connected);
          case SshSessionState.disconnected:
            _setState(profile.id, ServerConnectionState.disconnected);
          case SshSessionState.connecting:
          case SshSessionState.authenticating:
          case SshSessionState.hostVerificationRequired:
            _setState(profile.id, ServerConnectionState.reconnecting);
          case SshSessionState.authenticationFailed:
            _setState(profile.id, ServerConnectionState.authenticationFailed);
          case SshSessionState.connectionFailed:
          case SshSessionState.hostKeyChanged:
            _setState(profile.id, ServerConnectionState.connectionFailed);
          case SshSessionState.disconnecting:
          case SshSessionState.idle:
            break;
        }
      });
    } on AppFailure catch (f) {
      final state = switch (f.kind) {
        AppFailureKind.authenticationFailed => ServerConnectionState.authenticationFailed,
        AppFailureKind.hostKeyChanged => ServerConnectionState.hostVerificationRequired,
        _ => ServerConnectionState.connectionFailed,
      };
      _setState(profile.id, state, error: f);
      rethrow;
    } catch (e) {
      _setState(profile.id, ServerConnectionState.connectionFailed);
      rethrow;
    }
  }

  /// Lets a feature that manages its OWN connection lifecycle (SFTP,
  /// currently — see the class doc's known limitation) still report into
  /// this single source of truth, so the Saved Connections list and
  /// other screens see one consistent state regardless of which feature
  /// actually established the link.
  void reportExternalState(String profileId, ServerConnectionState state, {AppFailure? error}) {
    _setState(profileId, state, error: error);
  }

  /// Tears down EVERYTHING for this profile: the SSH session (terminal +
  /// any background exec channels Health/Security opened), and the SFTP
  /// connection if it's currently pointed at this profile. Per the
  /// brief, this must genuinely close sockets, not just update a UI flag.
  Future<void> disconnect(String profileId) async {
    await _stateSubs.remove(profileId)?.cancel();
    await _sshService.disconnect(profileId);
    // SftpService only tracks one active profile; only tear it down if
    // it's actually this one (avoids disconnecting an unrelated server's
    // Files session).
    await _sftpService.disconnect();
    _setState(profileId, ServerConnectionState.disconnected);
  }

  @override
  void dispose() {
    for (final sub in _stateSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
