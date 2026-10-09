import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/models/connection_status.dart';
import '../../../core/security/host_key_store.dart';
import '../../../core/security/ssh_fingerprint.dart';
import '../../../core/storage/secure_credential_store.dart';
import '../../connections/models/connection_profile.dart';
import '../../ssh/models/host_key_verification.dart';
import '../models/remote_file.dart';
import 'sftp_service.dart';

/// Real SFTP implementation over `dartssh2`.
///
/// Opens its own SSH connection (separate from any Terminal session for
/// the same profile — see the phase report for why sessions aren't
/// shared across features yet). Goes through the same [HostKeyStore] as
/// [RealSshService], so trusting a host from either screen trusts it for
/// both.
///
/// SFTP has no protocol-level concept of total filesystem capacity, so
/// [RemoteDirectory.totalBytes] is reported as 0 here (StorageGauge shows
/// a "not reported" note in that case) rather than inventing a number.
class RealSftpService implements SftpService {
  RealSftpService({required HostKeyStore hostKeyStore, required SecureCredentialStore credentialStore})
      : _hostKeyStore = hostKeyStore,
        _credentialStore = credentialStore;

  final HostKeyStore _hostKeyStore;
  final SecureCredentialStore _credentialStore;

  SSHClient? _client;
  SftpClient? _sftp;
  ConnectionProfile? _profile;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  ConnectionStatus _status = ConnectionStatus.disconnected;

  @override
  ConnectionStatus get status => _status;
  @override
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  void _setStatus(ConnectionStatus s) {
    _status = s;
    _statusController.add(s);
  }

  @override
  Future<void> connect(ConnectionProfile profile, {required HostKeyDecisionHandler onHostKeyVerification}) async {
    _profile = profile;
    _setStatus(ConnectionStatus.connecting);
    try {
      final socket = await SSHSocket.connect(profile.host, profile.port).timeout(const Duration(seconds: 15));

      List<SSHKeyPair>? identities;
      String Function()? onPasswordRequest;
      if (profile.authMethod == AuthMethod.password) {
        final password = await _credentialStore.readPassword(profile.id);
        onPasswordRequest = () => password ?? '';
      } else {
        final pem = await _credentialStore.readPrivateKey(profile.id);
        final passphrase = await _credentialStore.readPassphrase(profile.id);
        if (pem == null) {
          throw const AppFailure(AppFailureKind.invalidPrivateKey, message: 'No private key on file for this profile');
        }
        identities = SSHKeyPair.fromPem(pem, passphrase);
      }

      _client = SSHClient(
        socket,
        username: profile.username,
        identities: identities,
        onPasswordRequest: onPasswordRequest,
        onVerifyHostKey: (type, fingerprintBytes) async {
          final fingerprint = formatSshFingerprint(fingerprintBytes);
          final known = await _hostKeyStore.lookup(profile.host, profile.port);
          if (known != null && known.fingerprint == fingerprint) return true;

          final decision = await onHostKeyVerification(HostKeyVerificationRequest(
            host: profile.host,
            port: profile.port,
            keyType: type,
            fingerprint: fingerprint,
            previousFingerprint: known?.fingerprint,
          ));
          if (decision == HostKeyDecision.trust) {
            await _hostKeyStore.trust(TrustedHostKey(
              host: profile.host,
              port: profile.port,
              keyType: type,
              fingerprint: fingerprint,
              firstSeenAt: DateTime.now(),
            ));
            return true;
          }
          return decision == HostKeyDecision.trustOnce;
        },
      );
      await _client!.authenticated;
      _sftp = await _client!.sftp();
      _setStatus(ConnectionStatus.connected);
    } catch (e) {
      _setStatus(ConnectionStatus.error);
      if (e is AppFailure) rethrow;
      if (e is TimeoutException) throw const AppFailure(AppFailureKind.timeout);
      if (e is SocketException) throw const AppFailure(AppFailureKind.hostUnreachable);
      if (e is SSHAuthFailError || e is SSHAuthAbortError) {
        throw const AppFailure(AppFailureKind.authenticationFailed);
      }
      throw const AppFailure(AppFailureKind.unknown);
    }
  }

  @override
  Future<void> disconnect() async {
    _sftp = null;
    _client?.close();
    _client = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  SftpClient _requireSftp() {
    final sftp = _sftp;
    if (sftp == null) throw const AppFailure(AppFailureKind.disconnected);
    return sftp;
  }

  @override
  Future<RemoteDirectory> list(String path) async {
    final sftp = _requireSftp();
    late final List<SftpName> names;
    try {
      names = await sftp.listdir(path);
    } on SftpStatusError catch (e) {
      throw _mapSftpStatusError(e);
    }

    var usedBytes = 0;
    final entries = <RemoteFile>[];
    for (final n in names) {
      if (n.filename == '.' || n.filename == '..') continue;
      final attr = n.attr;
      final isDir = attr.isDirectory;
      final size = attr.size ?? 0;
      if (!isDir) usedBytes += size;
      final modified = attr.modifyTime != null
          ? DateTime.fromMillisecondsSinceEpoch(attr.modifyTime! * 1000)
          : DateTime.now();
      final fullPath = path == '/' ? '/${n.filename}' : '$path/${n.filename}';
      entries.add(RemoteFile(
        name: n.filename,
        path: fullPath,
        isDirectory: isDir,
        permissions: _formatPermissions(attr.mode, isDir),
        modifiedAt: modified,
        sizeBytes: isDir ? null : size,
        itemCount: null,
        typeLabel: _typeLabelFor(n.filename),
      ));
    }

    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    // SFTP has no "total disk size" primitive — 0 signals "not reported"
    // to StorageGauge rather than a fabricated number.
    return RemoteDirectory(path: path, entries: entries, usedBytes: usedBytes, totalBytes: 0);
  }

  String _formatPermissions(SftpFileMode? mode, bool isDir) {
    if (mode == null) return isDir ? 'drwxr-xr-x' : '-rw-r--r--';
    String triplet(bool r, bool w, bool x) => '${r ? 'r' : '-'}${w ? 'w' : '-'}${x ? 'x' : '-'}';
    final owner = triplet(mode.userRead, mode.userWrite, mode.userExecute);
    final group = triplet(mode.groupRead, mode.groupWrite, mode.groupExecute);
    final other = triplet(mode.otherRead, mode.otherWrite, mode.otherExecute);
    return '${isDir ? 'd' : '-'}$owner$group$other';
  }

  String? _typeLabelFor(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toUpperCase() : null;
    const notable = {'YML', 'YAML', 'JSON', 'GZ', 'ZIP', 'TAR', 'HTML', 'ENV'};
    return (ext != null && notable.contains(ext)) ? ext : null;
  }

  @override
  Future<String> readFile(String path) async {
    final bytes = await download(path);
    return String.fromCharCodes(bytes);
  }

  @override
  Future<void> writeFile(String path, String content) async {
    await upload(path, Uint8List.fromList(content.codeUnits));
  }

  @override
  Future<Uint8List> download(String remotePath, {void Function(int transferred, int total)? onProgress}) async {
    final sftp = _requireSftp();
    try {
      final file = await sftp.open(remotePath);
      final attr = await file.stat();
      final total = attr.size ?? 0;
      // NOTE: single-shot read (confirmed dartssh2 API: `SftpFile.readBytes()`),
      // not a chunked stream — see the interface doc for why (in-memory,
      // Phase-scoped). Progress is reported once at completion rather than
      // guessing at an unconfirmed chunked-read API surface.
      final bytes = await file.readBytes();
      onProgress?.call(bytes.length, total == 0 ? bytes.length : total);
      return bytes;
    } on SftpStatusError catch (e) {
      throw _mapSftpStatusError(e);
    }
  }

  @override
  Future<void> upload(String remotePath, Uint8List data, {void Function(int transferred, int total)? onProgress}) async {
    final sftp = _requireSftp();
    try {
      final file = await sftp.open(
        remotePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
      );
      var written = 0;
      await file.writeBytes(data);
      written = data.length;
      onProgress?.call(written, data.length);
    } on SftpStatusError catch (e) {
      throw _mapSftpStatusError(e);
    }
  }

  @override
  Future<void> rename(String path, String newName) async {
    final sftp = _requireSftp();
    final parent = path.substring(0, path.lastIndexOf('/'));
    final newPath = '$parent/$newName';
    try {
      await sftp.rename(path, newPath);
    } on SftpStatusError catch (e) {
      throw _mapSftpStatusError(e);
    }
  }

  @override
  Future<void> delete(String path) async {
    final sftp = _requireSftp();
    try {
      // SFTP's `remove` (SSH_FXP_REMOVE) only works on regular files —
      // this was the folder-delete bug: it was called unconditionally
      // for both files and directories, and silently/erroneously failed
      // for directories. Directories need `rmdir` (SSH_FXP_RMDIR), which
      // itself only works when EMPTY, so a non-empty directory must have
      // its contents removed recursively first.
      final stat = await sftp.stat(path);
      if (stat.isDirectory) {
        await _deleteDirectoryRecursive(sftp, path);
      } else {
        await sftp.remove(path);
      }
    } on SftpStatusError catch (e) {
      throw _mapSftpStatusError(e);
    }
  }

  Future<void> _deleteDirectoryRecursive(SftpClient sftp, String path) async {
    final entries = await sftp.listdir(path);
    for (final entry in entries) {
      if (entry.filename == '.' || entry.filename == '..') continue;
      final childPath = path == '/' ? '/${entry.filename}' : '$path/${entry.filename}';
      if (entry.attr.isDirectory) {
        await _deleteDirectoryRecursive(sftp, childPath);
      } else {
        await sftp.remove(childPath);
      }
    }
    await sftp.rmdir(path);
  }

  @override
  Future<void> createFolder(String parentPath, String name) async {
    final sftp = _requireSftp();
    final path = parentPath == '/' ? '/$name' : '$parentPath/$name';
    try {
      await sftp.mkdir(path);
    } on SftpStatusError catch (e) {
      throw _mapSftpStatusError(e);
    }
  }

  @override
  Future<void> createFile(String parentPath, String name) async {
    final path = parentPath == '/' ? '/$name' : '$parentPath/$name';
    await upload(path, Uint8List(0));
  }

  AppFailure _mapSftpStatusError(SftpStatusError e) {
    switch (e.code) {
      case SftpStatusCode.noSuchFile:
        return const AppFailure(AppFailureKind.fileNotFound);
      case SftpStatusCode.permissionDenied:
        return const AppFailure(AppFailureKind.permissionDenied);
      case SftpStatusCode.opUnsupported:
        return const AppFailure(AppFailureKind.unsupportedOperation);
      default:
        return AppFailure(AppFailureKind.unknown, detail: e.code.toString());
    }
  }
}
