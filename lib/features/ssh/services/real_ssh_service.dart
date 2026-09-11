import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/security/host_key_store.dart';
import '../../../core/security/ssh_fingerprint.dart';
import '../../../core/storage/secure_credential_store.dart';
import '../../connections/models/connection_profile.dart';
import '../models/host_key_verification.dart';
import '../models/ssh_session_state.dart';
import 'ssh_service.dart';

/// Real Android/iOS/desktop SSH implementation, backed by `dartssh2`.
///
/// Every connect goes through [HostKeyStore] first: unknown or changed
/// host keys pause the handshake (via dartssh2's `onVerifyHostKey`
/// callback) and hand control to [HostKeyDecisionHandler] — the SSH
/// transport itself is never allowed to silently accept or silently
/// reject a key change. `disableHostkeyVerification` is never set on the
/// underlying `SSHClient`.
class RealSshService implements SshService {
  RealSshService({required HostKeyStore hostKeyStore, required SecureCredentialStore credentialStore})
      : _hostKeyStore = hostKeyStore,
        _credentialStore = credentialStore;

  final HostKeyStore _hostKeyStore;
  final SecureCredentialStore _credentialStore;
  final Map<String, _RealSshSession> _sessions = {};

  @override
  SshSession? sessionFor(String connectionId) => _sessions[connectionId];

  @override
  Future<SshSession> connect(
    ConnectionProfile profile, {
    required HostKeyDecisionHandler onHostKeyVerification,
  }) async {
    final existing = _sessions[profile.id];
    if (existing != null && existing.state == SshSessionState.connected) {
      return existing;
    }

    final session = _RealSshSession(profile);
    _sessions[profile.id] = session;

    try {
      final client = await _buildClient(
        profile,
        onHostKeyVerification: onHostKeyVerification,
        session: session,
      );
      session.attachClient(client);
      await client.authenticated;
      final shell = await client.shell(
        pty: const SSHPtyConfig(width: 80, height: 24),
      );
      session.attachShell(shell);
    } catch (e) {
      _sessions.remove(profile.id);
      session.dispose();
      throw _mapConnectError(e);
    }
    return session;
  }

  @override
  Future<void> disconnect(String connectionId) async {
    final session = _sessions.remove(connectionId);
    await session?.close();
  }

  @override
  Future<void> testConnection(
    ConnectionProfile profile, {
    required HostKeyDecisionHandler onHostKeyVerification,
    String? passwordOverride,
    String? privateKeyOverride,
    String? passphraseOverride,
  }) async {
    SSHClient? client;
    try {
      client = await _buildClient(
        profile,
        onHostKeyVerification: onHostKeyVerification,
        passwordOverride: passwordOverride,
        privateKeyOverride: privateKeyOverride,
        passphraseOverride: passphraseOverride,
      );
      await client.authenticated;
      // Confirm the session is actually usable, not just authenticated —
      // a cheap round trip.
      await client.run('true');
    } catch (e) {
      throw _mapConnectError(e);
    } finally {
      client?.close();
    }
  }

  Future<SSHClient> _buildClient(
    ConnectionProfile profile, {
    required HostKeyDecisionHandler onHostKeyVerification,
    _RealSshSession? session,
    String? passwordOverride,
    String? privateKeyOverride,
    String? passphraseOverride,
  }) async {
    session?.setState(SshSessionState.connecting);

    final socket = await SSHSocket.connect(profile.host, profile.port)
        .timeout(const Duration(seconds: 15));

    List<SSHKeyPair>? identities;
    String Function()? onPasswordRequest;

    if (profile.authMethod == AuthMethod.password) {
      final password = passwordOverride ?? await _credentialStore.readPassword(profile.id);
      onPasswordRequest = () => password ?? '';
    } else {
      final pem = privateKeyOverride ?? await _credentialStore.readPrivateKey(profile.id);
      final passphrase = passphraseOverride ?? await _credentialStore.readPassphrase(profile.id);
      if (pem == null) {
        throw const AppFailure(AppFailureKind.invalidPrivateKey, message: 'No private key on file for this profile');
      }
      try {
        identities = SSHKeyPair.fromPem(pem, passphrase);
      } on SSHKeyDecryptError {
        throw const AppFailure(AppFailureKind.incorrectPassphrase);
      } catch (_) {
        throw const AppFailure(AppFailureKind.invalidPrivateKey);
      }
    }

    session?.setState(SshSessionState.authenticating);

    return SSHClient(
      socket,
      username: profile.username,
      identities: identities,
      onPasswordRequest: onPasswordRequest,
      keepAliveInterval: const Duration(seconds: 15),
      onVerifyHostKey: (type, fingerprintBytes) async {
        session?.setState(SshSessionState.hostVerificationRequired);
        final fingerprint = formatSshFingerprint(fingerprintBytes);
        final known = await _hostKeyStore.lookup(profile.host, profile.port);

        final request = HostKeyVerificationRequest(
          host: profile.host,
          port: profile.port,
          keyType: type,
          fingerprint: fingerprint,
          previousFingerprint: (known != null && known.fingerprint != fingerprint) ? known.fingerprint : null,
        );

        // Already trusted with a matching fingerprint — nothing to ask.
        if (known != null && known.fingerprint == fingerprint) {
          return true;
        }

        final decision = await onHostKeyVerification(request);
        switch (decision) {
          case HostKeyDecision.trust:
            await _hostKeyStore.trust(TrustedHostKey(
              host: profile.host,
              port: profile.port,
              keyType: type,
              fingerprint: fingerprint,
              firstSeenAt: DateTime.now(),
            ));
            return true;
          case HostKeyDecision.trustOnce:
            return true;
          case HostKeyDecision.reject:
            return false;
        }
      },
    );
  }

  AppFailure _mapConnectError(Object e) {
    if (e is AppFailure) return e;
    if (e is TimeoutException) return const AppFailure(AppFailureKind.timeout);
    if (e is SocketException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('refused')) return const AppFailure(AppFailureKind.connectionRefused);
      if (msg.contains('lookup') || msg.contains('resolve') || e.osError?.errorCode == 8) {
        return const AppFailure(AppFailureKind.dnsFailure);
      }
      return const AppFailure(AppFailureKind.hostUnreachable);
    }
    if (e is SSHAuthFailError || e is SSHAuthAbortError) {
      return const AppFailure(AppFailureKind.authenticationFailed);
    }
    if (e is SSHHostkeyError) {
      return const AppFailure(AppFailureKind.hostKeyChanged);
    }
    // Deliberately not including `e.toString()` verbatim in `detail` here:
    // some SSH exceptions can echo back parts of the auth exchange. Keep
    // the mapped kind only; anything genuinely useful for diagnostics
    // should go through a sanitizing log helper, not straight to the UI.
    return const AppFailure(AppFailureKind.unknown);
  }
}

class _RealSshSession implements SshSession {
  _RealSshSession(this.profile);

  @override
  final ConnectionProfile profile;

  SSHClient? _client;
  SSHSession? _shell;
  StreamSubscription<Uint8List>? _stdoutSub;
  StreamSubscription<Uint8List>? _stderrSub;

  final _stateController = StreamController<SshSessionState>.broadcast();
  final _outputController = StreamController<List<int>>.broadcast();
  SshSessionState _state = SshSessionState.idle;

  @override
  SshSessionState get state => _state;
  @override
  Stream<SshSessionState> get stateStream => _stateController.stream;
  @override
  Stream<List<int>> get output => _outputController.stream;

  void setState(SshSessionState s) {
    _state = s;
    _stateController.add(s);
  }

  void attachClient(SSHClient client) {
    _client = client;
  }

  void attachShell(SSHSession shell) {
    _shell = shell;
    setState(SshSessionState.connected);
    _stdoutSub = shell.stdout.listen(_outputController.add);
    _stderrSub = shell.stderr.listen(_outputController.add);
    shell.done.then((_) {
      if (_state != SshSessionState.disconnecting) {
        setState(SshSessionState.disconnected);
      }
    });
  }

  @override
  Future<void> sendLine(String line) async {
    _shell?.write(Uint8List.fromList(utf8.encode('$line\n')));
  }

  @override
  Future<void> sendRaw(List<int> bytes) async {
    _shell?.write(Uint8List.fromList(bytes));
  }

  @override
  Future<void> resize(int columns, int rows, [int pixelWidth = 0, int pixelHeight = 0]) async {
    _shell?.resizeTerminal(columns, rows, pixelWidth, pixelHeight);
  }

  @override
  Future<void> close() async {
    setState(SshSessionState.disconnecting);
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _shell?.close();
    _client?.close();
    setState(SshSessionState.disconnected);
    await _stateController.close();
    await _outputController.close();
  }

  void dispose() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _client?.close();
    _stateController.close();
    _outputController.close();
  }
}
