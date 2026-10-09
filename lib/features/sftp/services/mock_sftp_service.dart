import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../../core/errors/app_failure.dart';
import '../../../core/models/connection_status.dart';
import '../../connections/models/connection_profile.dart';
import '../../ssh/models/host_key_verification.dart';
import '../models/remote_file.dart';
import 'sftp_service.dart';

/// Mock [SftpService]. Reproduces the exact `/var/www/html` listing from
/// the Stitch `sftp_file_manager` prototype, plus a couple of extra
/// directories so drilling into `assets/` or `config/` doesn't dead-end.
///
/// [writeFile] only ever updates [_fileContents] — an in-memory map. It
/// never touches a real server, by design (see the interface doc). The
/// editor screen is responsible for making that limitation visible to the
/// user rather than claiming a real save.
///
/// Kept around (not deleted) as the no-server demo path — see
/// `main.dart` for how a debug flag or build flavor could pick this
/// instead of [RealSftpService].
class MockSftpService implements SftpService {
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionProfile? _profile;

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
    await Future.delayed(const Duration(milliseconds: 500));
    if (profile.host.contains('unreachable')) {
      _setStatus(ConnectionStatus.error);
      throw const AppFailure(AppFailureKind.hostUnreachable);
    }
    _setStatus(ConnectionStatus.connected);
  }

  @override
  Future<Uint8List> download(String remotePath, {void Function(int transferred, int total)? onProgress}) async {
    final content = _fileContents[remotePath] ?? '';
    final bytes = Uint8List.fromList(utf8.encode(content));
    onProgress?.call(bytes.length, bytes.length);
    return bytes;
  }

  @override
  Future<void> upload(String remotePath, Uint8List data, {void Function(int transferred, int total)? onProgress}) async {
    _fileContents[remotePath] = utf8.decode(data);
    onProgress?.call(data.length, data.length);
  }

  @override
  Future<void> disconnect() async {
    _setStatus(ConnectionStatus.disconnected);
  }

  // Mock filesystem tree — path -> list of entries directly inside it.
  static final Map<String, List<RemoteFile>> _tree = {
    '/var/www/html': [
      RemoteFile(
        name: 'assets',
        path: '/var/www/html/assets',
        isDirectory: true,
        permissions: 'drwxr-xr-x',
        modifiedAt: DateTime(2025, 2, 14, 11, 20),
        itemCount: 42,
      ),
      RemoteFile(
        name: 'config',
        path: '/var/www/html/config',
        isDirectory: true,
        permissions: 'drwx------',
        modifiedAt: DateTime(2025, 2, 20, 9, 15),
        itemCount: 6,
      ),
      RemoteFile(
        name: 'logs',
        path: '/var/www/html/logs',
        isDirectory: true,
        permissions: 'drwxr-xr-x',
        modifiedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        itemCount: 18,
        badge: RemoteEntryBadge.live,
      ),
      RemoteFile(
        name: 'docker-compose.yml',
        path: '/var/www/html/docker-compose.yml',
        isDirectory: false,
        permissions: '0644',
        modifiedAt: DateTime.now().subtract(const Duration(days: 2)),
        sizeBytes: 3481,
        typeLabel: 'YML',
      ),
      RemoteFile(
        name: 'index.html',
        path: '/var/www/html/index.html',
        isDirectory: false,
        permissions: '0755',
        modifiedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        sizeBytes: 15155,
      ),
      RemoteFile(
        name: 'nginx.conf',
        path: '/var/www/html/nginx.conf',
        isDirectory: false,
        permissions: '0644',
        modifiedAt: DateTime.now().subtract(const Duration(days: 3)),
        sizeBytes: 2150,
        badge: RemoteEntryBadge.active,
      ),
      RemoteFile(
        name: '.env.production',
        path: '/var/www/html/.env.production',
        isDirectory: false,
        permissions: '0600',
        modifiedAt: DateTime.now().subtract(const Duration(days: 5)),
        sizeBytes: 890,
        badge: RemoteEntryBadge.secure,
      ),
      RemoteFile(
        name: 'backup_20250218.tar.gz',
        path: '/var/www/html/backup_20250218.tar.gz',
        isDirectory: false,
        permissions: '0644',
        modifiedAt: DateTime.now().subtract(const Duration(days: 6)),
        sizeBytes: 245800000,
        typeLabel: 'GZ',
      ),
    ],
    '/var/www/html/assets': [
      RemoteFile(
        name: 'logo.svg',
        path: '/var/www/html/assets/logo.svg',
        isDirectory: false,
        permissions: '0644',
        modifiedAt: DateTime(2025, 2, 1),
        sizeBytes: 4096,
      ),
    ],
    '/var/www/html/config': [
      RemoteFile(
        name: 'app.ini',
        path: '/var/www/html/config/app.ini',
        isDirectory: false,
        permissions: '0640',
        modifiedAt: DateTime(2025, 2, 18),
        sizeBytes: 1024,
      ),
    ],
    '/var/www/html/logs': [
      RemoteFile(
        name: 'access.log',
        path: '/var/www/html/logs/access.log',
        isDirectory: false,
        permissions: '0644',
        modifiedAt: DateTime.now().subtract(const Duration(minutes: 1)),
        sizeBytes: 8912000,
        badge: RemoteEntryBadge.live,
      ),
    ],
  };

  static final Map<String, String> _fileContents = {
    '/var/www/html/nginx.conf': '''
server {
    listen 443 ssl;
    server_name example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
    }
}
''',
    '/var/www/html/docker-compose.yml': '''
version: "3.9"
services:
  api-gateway:
    image: serverdr/api-gateway:latest
    ports:
      - "443:443"
''',
  };

  @override
  Future<RemoteDirectory> list(String path) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final entries = _tree[path];
    if (entries == null) {
      throw const AppFailure(AppFailureKind.fileNotFound);
    }
    return RemoteDirectory(
      path: path,
      entries: entries,
      usedBytes: (38.4 * 1024 * 1024 * 1024).round(),
      totalBytes: 120 * 1024 * 1024 * 1024,
    );
  }

  @override
  Future<String> readFile(String path) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _fileContents[path] ?? '// (empty mock file — no content seeded for $path)\n';
  }

  @override
  Future<void> writeFile(String path, String content) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fileContents[path] = content;
    // Deliberately does NOT touch _tree's modifiedAt/size — this is a
    // mock-only edit, not a real remote save.
  }

  @override
  Future<void> rename(String path, String newName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock-only: real rename lands in Phase 4.
  }

  @override
  Future<void> delete(String path) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock-only: real delete lands in Phase 4.
  }

  @override
  Future<void> createFolder(String parentPath, String name) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> createFile(String parentPath, String name) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
