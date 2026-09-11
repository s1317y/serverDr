import 'dart:async';
import 'dart:convert';

import '../../../core/errors/app_failure.dart';
import '../../connections/models/connection_profile.dart';
import '../models/host_key_verification.dart';
import '../models/ssh_session_state.dart';
import 'ssh_service.dart';

/// In-memory [SshService] implementation for demos and tests.
class MockSshService implements SshService {
  final Map<String, _MockSshSession> _sessions = {};

  @override
  Future<SshSession> connect(
    ConnectionProfile profile, {
    required HostKeyDecisionHandler onHostKeyVerification,
  }) async {
    final existing = _sessions[profile.id];
    if (existing != null && existing.state == SshSessionState.connected) {
      return existing;
    }

    final session = _MockSshSession(profile);
    _sessions[profile.id] = session;
    try {
      await session.connect();
      return session;
    } catch (_) {
      _sessions.remove(profile.id);
      await session.close();
      rethrow;
    }
  }

  @override
  SshSession? sessionFor(String connectionId) => _sessions[connectionId];

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
  }) => _validate(profile);

  Future<void> _validate(ConnectionProfile profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (profile.host.contains('unreachable')) {
      throw const AppFailure(AppFailureKind.hostUnreachable);
    }
    if (profile.host.contains('badauth')) {
      throw const AppFailure(AppFailureKind.authenticationFailed);
    }
  }
}

class _MockSshSession implements SshSession {
  _MockSshSession(this.profile);

  @override
  final ConnectionProfile profile;

  final _stateController = StreamController<SshSessionState>.broadcast();
  final _outputController = StreamController<List<int>>.broadcast();
  SshSessionState _state = SshSessionState.idle;
  var _isClosed = false;

  @override
  SshSessionState get state => _state;

  @override
  Stream<SshSessionState> get stateStream => _stateController.stream;

  @override
  Stream<List<int>> get output => _outputController.stream;

  Future<void> connect() async {
    _setState(SshSessionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (profile.host.contains('unreachable')) {
      _setState(SshSessionState.connectionFailed);
      throw const AppFailure(AppFailureKind.hostUnreachable);
    }
    if (profile.host.contains('badauth')) {
      _setState(SshSessionState.authenticationFailed);
      throw const AppFailure(AppFailureKind.authenticationFailed);
    }
    _setState(SshSessionState.authenticating);
    _setState(SshSessionState.connected);
    _write('Welcome to ServerKit mock SSH for ${profile.name}\r\n');
    _write('${profile.username}@${profile.host}:~\$ ');
  }

  void _setState(SshSessionState value) {
    _state = value;
    if (!_stateController.isClosed) _stateController.add(value);
  }

  void _write(String value) {
    if (!_outputController.isClosed) _outputController.add(utf8.encode(value));
  }

  @override
  Future<void> sendLine(String line) async {
    if (_state != SshSessionState.connected) {
      throw const AppFailure(AppFailureKind.disconnected);
    }
    _write('$line\r\nCommand executed successfully.\r\n'
        '${profile.username}@${profile.host}:~\$ ');
  }

  @override
  Future<void> sendRaw(List<int> bytes) async {
    if (_state != SshSessionState.connected) {
      throw const AppFailure(AppFailureKind.disconnected);
    }
    if (bytes.isNotEmpty) _outputController.add(List<int>.from(bytes));
  }

  @override
  Future<void> resize(
    int columns,
    int rows, [
    int pixelWidth = 0,
    int pixelHeight = 0,
  ]) async {}

  @override
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    _setState(SshSessionState.disconnecting);
    _setState(SshSessionState.disconnected);
    await _stateController.close();
    await _outputController.close();
  }
}
