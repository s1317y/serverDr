import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// One trusted (or previously-trusted) host key record.
@immutable
class TrustedHostKey {
  const TrustedHostKey({
    required this.host,
    required this.port,
    required this.keyType,
    required this.fingerprint,
    required this.firstSeenAt,
  });

  final String host;
  final int port;
  final String keyType;
  final String fingerprint;
  final DateTime firstSeenAt;

  String get hostPortLabel => '$host:$port';

  Map<String, dynamic> _toJson() => {
        'host': host,
        'port': port,
        'keyType': keyType,
        'fingerprint': fingerprint,
        'firstSeenAt': firstSeenAt.toIso8601String(),
      };

  static TrustedHostKey _fromJson(Map<String, dynamic> json) => TrustedHostKey(
        host: json['host'] as String,
        port: json['port'] as int,
        keyType: json['keyType'] as String,
        fingerprint: json['fingerprint'] as String,
        firstSeenAt: DateTime.parse(json['firstSeenAt'] as String),
      );
}

/// Persists which SSH host keys this device has explicitly trusted — the
/// Flutter/mobile equivalent of `~/.ssh/known_hosts`.
///
/// Backed by secure, platform-encrypted storage (never SharedPreferences
/// or a plain database column) since a tampered known-hosts store is a
/// direct path to a silent MITM downgrade. Every real connect goes
/// through [lookup] before trusting a server, and [trust] is only ever
/// called after the user has explicitly approved a fingerprint in the UI
/// — this class itself never decides to trust anything.
abstract interface class HostKeyStore {
  /// Returns the trusted record for `host:port`, or null if never seen.
  Future<TrustedHostKey?> lookup(String host, int port);

  /// Records explicit trust. Overwrites any prior record for the same
  /// host:port — callers must have already confirmed with the user that
  /// this is intentional (e.g. after a Host Key Changed screen), never as
  /// a side effect of a normal connect.
  Future<void> trust(TrustedHostKey key);

  /// Removes a trust record — the "Remove Trust" action in Known SSH
  /// Hosts. The next connection to that host will require verification
  /// again.
  Future<void> removeTrust(String host, int port);

  Future<List<TrustedHostKey>> listAll();
}

class SecureHostKeyStore implements HostKeyStore {
  SecureHostKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  final FlutterSecureStorage _storage;

  static String _key(String host, int port) => 'hostkey::$host::$port';
  static const _prefix = 'hostkey::';

  @override
  Future<TrustedHostKey?> lookup(String host, int port) async {
    final raw = await _storage.read(key: _key(host, port));
    if (raw == null) return null;
    try {
      return TrustedHostKey._fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt record — treat as unknown host rather than crashing.
      // Deliberately not logged with content: it's untrusted local data.
      return null;
    }
  }

  @override
  Future<void> trust(TrustedHostKey key) async {
    await _storage.write(
      key: _key(key.host, key.port),
      value: jsonEncode(key._toJson()),
    );
  }

  @override
  Future<void> removeTrust(String host, int port) async {
    await _storage.delete(key: _key(host, port));
  }

  @override
  Future<List<TrustedHostKey>> listAll() async {
    final all = await _storage.readAll();
    final result = <TrustedHostKey>[];
    for (final entry in all.entries) {
      if (!entry.key.startsWith(_prefix)) continue;
      try {
        result.add(TrustedHostKey._fromJson(jsonDecode(entry.value) as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupt entries.
      }
    }
    return result;
  }
}
