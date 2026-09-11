import 'dart:typed_data';

import '../../../core/models/connection_status.dart';
import '../../connections/models/connection_profile.dart';
import '../../ssh/models/host_key_verification.dart';
import '../models/remote_file.dart';

/// Remote file browsing/editing operations for one server.
///
/// The Files screen depends only on this interface. [RealSftpService]
/// (dartssh2) is the real Android/iOS/desktop implementation;
/// [MockSftpService] remains for the no-server demo path.
abstract interface class SftpService {
  Stream<ConnectionStatus> get statusStream;
  ConnectionStatus get status;

  /// SFTP runs over SSH, so connecting requires the same host-key
  /// verification as the terminal — see [SshService.connect].
  Future<void> connect(ConnectionProfile profile, {required HostKeyDecisionHandler onHostKeyVerification});
  Future<void> disconnect();

  Future<RemoteDirectory> list(String path);
  Future<String> readFile(String path);

  /// Real implementations upload the new content and must not report
  /// success unless the remote write actually completed.
  Future<void> writeFile(String path, String content);

  Future<void> rename(String path, String newName);
  Future<void> delete(String path);
  Future<void> createFolder(String parentPath, String name);
  Future<void> createFile(String parentPath, String name);

  /// Downloads [remotePath] to memory, reporting bytes-so-far via
  /// [onProgress]. Kept in-memory (not streamed to a local file) for
  /// Phase scope — fine for the config/log-sized files this app expects;
  /// very large files should go through [downloadToFile] instead once a
  /// platform save-location picker is wired up.
  Future<Uint8List> download(String remotePath, {void Function(int transferred, int total)? onProgress});

  /// Uploads [data] to [remotePath], reporting bytes-so-far.
  Future<void> upload(String remotePath, Uint8List data, {void Function(int transferred, int total)? onProgress});
}
