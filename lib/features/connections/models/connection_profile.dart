import 'package:flutter/foundation.dart';

/// Transport protocol a saved connection uses.
enum ConnectionProtocol {
  ssh,
  sftp,
  ftp,
  ftps;

  String get label => switch (this) {
        ConnectionProtocol.ssh => 'SSH',
        ConnectionProtocol.sftp => 'SFTP',
        ConnectionProtocol.ftp => 'FTP',
        ConnectionProtocol.ftps => 'FTPS',
      };

  /// Traditional FTP is unencrypted — every code path that connects over
  /// plain [ftp] must show the "Unencrypted FTP" warning before proceeding.
  bool get isEncrypted => this != ConnectionProtocol.ftp;

  int get defaultPort => switch (this) {
        ConnectionProtocol.ssh => 22,
        ConnectionProtocol.sftp => 22,
        ConnectionProtocol.ftp => 21,
        ConnectionProtocol.ftps => 990,
      };
}

/// How a connection authenticates.
enum AuthMethod {
  password,
  privateKey;

  String get label => switch (this) {
        AuthMethod.password => 'Password',
        AuthMethod.privateKey => 'SSH Private Key',
      };
}

/// A saved server connection profile.
///
/// This class models the *shape* of a connection only — the actual
/// secret (password / private key text / passphrase) never lives here.
/// It's stored separately, keyed by [id], in [SecureCredentialStore]
/// (Android Keystore-backed). That separation means a `ConnectionProfile`
/// can be freely passed around, serialized, or logged without ever
/// risking a leaked secret — see that class's doc for the storage
/// details.
@immutable
class ConnectionProfile {
  const ConnectionProfile({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.protocol,
    required this.authMethod,
    this.websiteUrl,
    this.hasStoredPassword = false,
    this.hasStoredPrivateKey = false,
    this.privateKeyFileName,
    this.lastConnectedAt,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final ConnectionProtocol protocol;
  final AuthMethod authMethod;

  /// Optional site URL for the Web tab (independent of the SSH/SFTP host,
  /// since a box's public site may sit behind a different domain/CDN).
  final String? websiteUrl;

  /// Whether a secret is on file for this profile. Deliberately a bool,
  /// not the secret itself — see the class doc.
  final bool hasStoredPassword;
  final bool hasStoredPrivateKey;

  /// Display-only filename of the selected private key (e.g.
  /// `id_ed25519`) — never a filesystem path. SAF-picked file paths
  /// aren't guaranteed stable across reboots, so the key's *content* is
  /// what's persisted (via [SecureCredentialStore]), not a path to
  /// re-read later.
  final String? privateKeyFileName;

  final DateTime? lastConnectedAt;

  ConnectionProfile copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    ConnectionProtocol? protocol,
    AuthMethod? authMethod,
    String? websiteUrl,
    bool? hasStoredPassword,
    bool? hasStoredPrivateKey,
    String? privateKeyFileName,
    DateTime? lastConnectedAt,
  }) {
    return ConnectionProfile(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      protocol: protocol ?? this.protocol,
      authMethod: authMethod ?? this.authMethod,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      hasStoredPassword: hasStoredPassword ?? this.hasStoredPassword,
      hasStoredPrivateKey: hasStoredPrivateKey ?? this.hasStoredPrivateKey,
      privateKeyFileName: privateKeyFileName ?? this.privateKeyFileName,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  /// Non-secret fields only — no password/key/passphrase ever appears
  /// here. Used by `PersistentConnectionRepository` to save the profile
  /// LIST (via shared_preferences); the secrets themselves live in
  /// `SecureCredentialStore`, keyed by [id].
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'protocol': protocol.name,
        'authMethod': authMethod.name,
        'websiteUrl': websiteUrl,
        'hasStoredPassword': hasStoredPassword,
        'hasStoredPrivateKey': hasStoredPrivateKey,
        'privateKeyFileName': privateKeyFileName,
        'lastConnectedAt': lastConnectedAt?.toIso8601String(),
      };

  factory ConnectionProfile.fromJson(Map<String, dynamic> json) => ConnectionProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        host: json['host'] as String,
        port: json['port'] as int,
        username: json['username'] as String,
        protocol: ConnectionProtocol.values.byName(json['protocol'] as String),
        authMethod: AuthMethod.values.byName(json['authMethod'] as String),
        websiteUrl: json['websiteUrl'] as String?,
        hasStoredPassword: json['hasStoredPassword'] as bool? ?? false,
        hasStoredPrivateKey: json['hasStoredPrivateKey'] as bool? ?? false,
        privateKeyFileName: json['privateKeyFileName'] as String?,
        lastConnectedAt:
            json['lastConnectedAt'] != null ? DateTime.parse(json['lastConnectedAt'] as String) : null,
      );
}
