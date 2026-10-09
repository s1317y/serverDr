import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/connection_profile.dart';

/// Persists and retrieves saved [ConnectionProfile]s.
///
/// The UI (connections list, editor, header selector) only ever talks to
/// this interface. Phase 2 swaps [MockConnectionRepository] for a
/// database/file-backed implementation without touching a single screen.
abstract interface class ConnectionRepository extends ChangeNotifier {
  List<ConnectionProfile> get connections;
  ConnectionProfile? get activeConnection;

  Future<void> add(ConnectionProfile connection);
  Future<void> update(ConnectionProfile connection);
  Future<void> delete(String id);
  void setActive(String? id);
}

/// In-memory mock repository, seeded with a handful of profiles so the UI
/// has something realistic to render. Nothing here touches disk — restart
/// the app and it resets to the seed data below.
class MockConnectionRepository extends ChangeNotifier implements ConnectionRepository {
  MockConnectionRepository() {
    _connections.addAll(_seed);
    _activeId = _connections.first.id;
  }

  final List<ConnectionProfile> _connections = [];
  String? _activeId;

  @override
  List<ConnectionProfile> get connections => List.unmodifiable(_connections);

  @override
  ConnectionProfile? get activeConnection {
    for (final c in _connections) {
      if (c.id == _activeId) return c;
    }
    return null;
  }

  @override
  Future<void> add(ConnectionProfile connection) async {
    _connections.add(connection);
    notifyListeners();
  }

  @override
  Future<void> update(ConnectionProfile connection) async {
    final index = _connections.indexWhere((c) => c.id == connection.id);
    if (index != -1) {
      _connections[index] = connection;
      notifyListeners();
    }
  }

  @override
  Future<void> delete(String id) async {
    _connections.removeWhere((c) => c.id == id);
    if (_activeId == id) {
      _activeId = _connections.isNotEmpty ? _connections.first.id : null;
    }
    notifyListeners();
  }

  @override
  void setActive(String? id) {
    _activeId = id;
    notifyListeners();
  }

  static final List<ConnectionProfile> _seed = [
    ConnectionProfile(
      id: 'srv-prod-api-01',
      name: 'prod-api-01',
      host: '192.168.1.105',
      port: 22,
      username: 'root',
      protocol: ConnectionProtocol.ssh,
      authMethod: AuthMethod.privateKey,
      websiteUrl: 'https://example.com',
      hasStoredPrivateKey: true,
      lastConnectedAt: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    ConnectionProfile(
      id: 'srv-staging-web',
      name: 'staging-web',
      host: '10.0.4.22',
      port: 22,
      username: 'deploy',
      protocol: ConnectionProtocol.sftp,
      authMethod: AuthMethod.password,
      hasStoredPassword: true,
      lastConnectedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    const ConnectionProfile(
      id: 'srv-legacy-ftp',
      name: 'legacy-archive',
      host: 'archive.internal',
      port: 21,
      username: 'ftpuser',
      protocol: ConnectionProtocol.ftp,
      authMethod: AuthMethod.password,
    ),
  ];
}

/// Persistent repository — saves the profile list (non-secret fields
/// only) to local device storage via `shared_preferences`, so saved
/// connections survive an app restart. Secrets are never touched here;
/// they live in `SecureCredentialStore`, keyed by the same profile [id].
///
/// Deleting a profile also asks the caller's `SecureCredentialStore` to
/// clear that id's secrets — see `ConnectionsScreen`'s delete action,
/// which is responsible for calling `SecureCredentialStore.clearAll`
/// alongside `delete` here, since this class has no direct dependency on
/// credential storage.
class PersistentConnectionRepository extends ChangeNotifier implements ConnectionRepository {
  PersistentConnectionRepository({required SharedPreferences prefs}) : _prefs = prefs {
    _load();
  }

  // NOTE (ServerKit → ServerDr rename): deliberately NOT renamed to
  // 'serverdr.*'. These are invisible SharedPreferences keys, not
  // user-facing branding — renaming them would silently wipe every
  // existing beta user's saved server list on upgrade, for zero visible
  // benefit. Same reasoning applies to every other `serverkit.*` storage
  // key in this codebase (monitoring config, command favorites/recent,
  // theme/font settings).
  static const _storageKey = 'serverkit.connections.v1';
  static const _activeIdKey = 'serverkit.connections.activeId';

  final SharedPreferences _prefs;
  final List<ConnectionProfile> _connections = [];
  String? _activeId;

  void _load() {
    final raw = _prefs.getStringList(_storageKey) ?? const [];
    _connections
      ..clear()
      ..addAll(raw.map((s) => ConnectionProfile.fromJson(jsonDecode(s) as Map<String, dynamic>)));
    _activeId = _prefs.getString(_activeIdKey) ?? (_connections.isNotEmpty ? _connections.first.id : null);
  }

  Future<void> _persist() async {
    await _prefs.setStringList(_storageKey, _connections.map((c) => jsonEncode(c.toJson())).toList());
    if (_activeId != null) {
      await _prefs.setString(_activeIdKey, _activeId!);
    }
  }

  @override
  List<ConnectionProfile> get connections => List.unmodifiable(_connections);

  @override
  ConnectionProfile? get activeConnection {
    for (final c in _connections) {
      if (c.id == _activeId) return c;
    }
    return null;
  }

  @override
  Future<void> add(ConnectionProfile connection) async {
    _connections.add(connection);
    _activeId ??= connection.id;
    await _persist();
    notifyListeners();
  }

  @override
  Future<void> update(ConnectionProfile connection) async {
    final index = _connections.indexWhere((c) => c.id == connection.id);
    if (index != -1) {
      _connections[index] = connection;
      await _persist();
      notifyListeners();
    }
  }

  @override
  Future<void> delete(String id) async {
    _connections.removeWhere((c) => c.id == id);
    if (_activeId == id) {
      _activeId = _connections.isNotEmpty ? _connections.first.id : null;
    }
    await _persist();
    notifyListeners();
  }

  @override
  void setActive(String? id) {
    _activeId = id;
    _persist();
    notifyListeners();
  }
}
