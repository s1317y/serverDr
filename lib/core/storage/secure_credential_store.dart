import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure credential storage, keyed by [ConnectionProfile.id] — never by
/// embedding the secret in the profile object itself, so a profile can be
/// freely passed around, serialized for backup, or logged without risk.
///
/// Backed by `flutter_secure_storage`: Android Keystore-backed encrypted
/// storage (EncryptedSharedPreferences) on Android, Keychain on iOS.
/// Nothing here is ever written to SharedPreferences, a plain database
/// column, or a log line — see the "never" list in each method's call
/// sites for what must never happen instead.
abstract interface class SecureCredentialStore {
  Future<void> savePassword(String connectionId, String password);
  Future<String?> readPassword(String connectionId);
  Future<void> deletePassword(String connectionId);

  /// [privateKey] is raw PEM/OpenSSH key text, read once from the file
  /// the user picked via the Android document picker — never a
  /// filesystem path (SAF paths aren't guaranteed stable across reboots,
  /// and re-reading an arbitrary path later would require broad storage
  /// permissions this app deliberately doesn't request).
  Future<void> savePrivateKey(String connectionId, {required String privateKey, String? passphrase});
  Future<String?> readPrivateKey(String connectionId);
  Future<String?> readPassphrase(String connectionId);
  Future<void> deletePrivateKey(String connectionId);

  /// Wipes everything this store holds for [connectionId] — used by
  /// "Clear Session Data" in Settings and when a profile is deleted.
  Future<void> clearAll(String connectionId);
}

class SecureCredentialStoreImpl implements SecureCredentialStore {
  SecureCredentialStoreImpl({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  final FlutterSecureStorage _storage;

  static String _passwordKey(String id) => 'cred::$id::password';
  static String _keyKey(String id) => 'cred::$id::privatekey';
  static String _passphraseKey(String id) => 'cred::$id::passphrase';

  @override
  Future<void> savePassword(String connectionId, String password) =>
      _storage.write(key: _passwordKey(connectionId), value: password);

  @override
  Future<String?> readPassword(String connectionId) => _storage.read(key: _passwordKey(connectionId));

  @override
  Future<void> deletePassword(String connectionId) => _storage.delete(key: _passwordKey(connectionId));

  @override
  Future<void> savePrivateKey(String connectionId, {required String privateKey, String? passphrase}) async {
    await _storage.write(key: _keyKey(connectionId), value: privateKey);
    if (passphrase != null && passphrase.isNotEmpty) {
      await _storage.write(key: _passphraseKey(connectionId), value: passphrase);
    } else {
      await _storage.delete(key: _passphraseKey(connectionId));
    }
  }

  @override
  Future<String?> readPrivateKey(String connectionId) => _storage.read(key: _keyKey(connectionId));

  @override
  Future<String?> readPassphrase(String connectionId) => _storage.read(key: _passphraseKey(connectionId));

  @override
  Future<void> deletePrivateKey(String connectionId) async {
    await _storage.delete(key: _keyKey(connectionId));
    await _storage.delete(key: _passphraseKey(connectionId));
  }

  @override
  Future<void> clearAll(String connectionId) async {
    await deletePassword(connectionId);
    await deletePrivateKey(connectionId);
  }
}
