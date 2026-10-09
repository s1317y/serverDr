import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/connection_status.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/server_connection_sheet.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/text_prompt_dialog.dart';
import '../../connections/models/connection_profile.dart';
import '../../connections/models/server_connection_state.dart';
import '../../connections/services/connection_repository.dart';
import '../../connections/services/server_connection_manager.dart';
import '../../ftp/widgets/unencrypted_ftp_warning.dart';
import '../../ssh/widgets/host_key_verification_dialog.dart';
import '../../transfers/models/transfer_item.dart';
import '../../transfers/services/transfer_manager.dart';
import '../models/remote_file.dart';
import '../services/sftp_service.dart';
import '../widgets/breadcrumb_bar.dart';
import '../widgets/file_action_sheet.dart';
import '../widgets/file_row.dart';
import '../widgets/sftp_toolbar.dart';
import '../widgets/storage_gauge.dart';

class SftpScreen extends StatefulWidget {
  const SftpScreen({super.key});

  @override
  State<SftpScreen> createState() => _SftpScreenState();
}

class _SftpScreenState extends State<SftpScreen> {
  final _filterController = TextEditingController();
  String _currentPath = '/var/www/html';
  RemoteDirectory? _directory;
  AppFailure? _failure;
  bool _loading = false;
  bool _selectMode = false;
  String? _loadedForConnectionId;
  bool _ftpWarningShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = context.watch<ConnectionRepository>().activeConnection;
    if (active != null && active.id != _loadedForConnectionId) {
      _loadedForConnectionId = active.id;
      // Reattach silently if this profile's SFTP connection is already
      // live (e.g. left connected from a previous visit) — otherwise
      // show the explicit Connect prompt. Never auto-connect just from
      // opening this tab — see ServerConnectionManager's doc.
      final sftp = context.read<SftpService>();
      if (sftp.status == ConnectionStatus.connected) {
        _load(_currentPath);
      } else {
        setState(() {
          _directory = null;
          _failure = null;
        });
      }
    }
  }

  Future<void> _connectAndLoad(ConnectionProfile profile) async {
    if (profile.protocol == ConnectionProtocol.ftp && !_ftpWarningShown) {
      _ftpWarningShown = true;
      final proceed = await showUnencryptedFtpWarning(context, host: profile.host);
      if (!proceed) return;
    }
    final service = context.read<SftpService>();
    final manager = context.read<ServerConnectionManager>();
    setState(() {
      _loading = true;
      _failure = null;
    });
    manager.reportExternalState(profile.id, ServerConnectionState.connecting);
    try {
      await service.connect(profile, onHostKeyVerification: (request) => showHostKeyVerificationDialog(context, request));
      manager.reportExternalState(profile.id, ServerConnectionState.connected);
      await _load(_currentPath);
    } on AppFailure catch (f) {
      manager.reportExternalState(profile.id, ServerConnectionState.connectionFailed, error: f);
      setState(() {
        _failure = f;
        _loading = false;
      });
    }
  }

  Future<void> _load(String path) async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final dir = await context.read<SftpService>().list(path);
      setState(() {
        _directory = dir;
        _currentPath = path;
        _loading = false;
      });
    } on AppFailure catch (f) {
      setState(() {
        _failure = f;
        _loading = false;
      });
    }
  }

  void _goUp() {
    if (_currentPath == '/') return;
    final segments = _currentPath.split('/').where((s) => s.isNotEmpty).toList();
    segments.removeLast();
    _load(segments.isEmpty ? '/' : '/${segments.join('/')}');
  }

  void _goToSegment(int index) {
    final segments = _directory?.pathSegments ?? [];
    if (index == 0) {
      _load('/');
      return;
    }
    final target = segments.sublist(0, index).join('/');
    _load('/$target');
  }

  /// Row tap: navigate into directories, show the file action sheet for
  /// files. Kept separate from [_onRowMore] — see that method's doc for
  /// why (this was the source of the three-dot bug).
  Future<void> _openEntry(RemoteFile entry) async {
    if (entry.isDirectory) {
      _load(entry.path);
      return;
    }
    final action = await showFileActionSheet(context, entry);
    if (action == null || !mounted) return;
    await _handleFileAction(entry, action);
  }

  /// Three-dot button: ALWAYS shows an action menu, for both files and
  /// directories — it must never navigate into a directory. This was the
  /// actual bug: the three-dot button was previously wired to the same
  /// handler as the row tap ([_openEntry]), which for a directory just
  /// called `_load(entry.path)` and skipped the menu entirely.
  Future<void> _onRowMore(RemoteFile entry) async {
    if (entry.isDirectory) {
      final action = await showDirectoryActionSheet(context, entry);
      if (action == null || !mounted) return;
      await _handleDirectoryAction(entry, action);
    } else {
      final action = await showFileActionSheet(context, entry);
      if (action == null || !mounted) return;
      await _handleFileAction(entry, action);
    }
  }

  Future<void> _handleFileAction(RemoteFile entry, FileAction action) async {
    switch (action) {
      case FileAction.edit:
        context.push('/editor', extra: entry);
      case FileAction.download:
        await _downloadFile(entry);
      case FileAction.upload:
        _showMockTransferNote();
      case FileAction.rename:
        final name = await showTextPromptDialog(context, title: 'Rename', initialValue: entry.name, confirmLabel: 'Rename');
        if (name != null) {
          await context.read<SftpService>().rename(entry.path, name);
          _load(_currentPath);
        }
      case FileAction.delete:
        final confirmed = await _confirmDelete(entry.name);
        if (confirmed) {
          await context.read<SftpService>().delete(entry.path);
          _load(_currentPath);
        }
      case FileAction.copyPath:
        await Clipboard.setData(ClipboardData(text: entry.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied: ${entry.path}')));
        }
      case FileAction.properties:
        _showProperties(entry);
      case FileAction.permissions:
      case FileAction.newFolder:
      case FileAction.newFile:
      case FileAction.refresh:
      case FileAction.open:
        break;
    }
  }

  Future<void> _handleDirectoryAction(RemoteFile entry, FileAction action) async {
    switch (action) {
      case FileAction.open:
        _load(entry.path);
      case FileAction.newFolder:
        final name = await showTextPromptDialog(context, title: 'New Folder');
        if (name != null) {
          await context.read<SftpService>().createFolder(entry.path, name);
          if (_currentPath == entry.path) _load(_currentPath);
        }
      case FileAction.upload:
        await _uploadFile(targetDirectory: entry.path);
      case FileAction.rename:
        final name = await showTextPromptDialog(context, title: 'Rename', initialValue: entry.name, confirmLabel: 'Rename');
        if (name != null) {
          await context.read<SftpService>().rename(entry.path, name);
          _load(_currentPath);
        }
      case FileAction.copyPath:
        await Clipboard.setData(ClipboardData(text: entry.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied: ${entry.path}')));
        }
      case FileAction.properties:
        _showProperties(entry);
      case FileAction.delete:
        final confirmed = await _confirmDelete(entry.name);
        if (confirmed) {
          await context.read<SftpService>().delete(entry.path);
          _load(_currentPath);
        }
      case FileAction.edit:
      case FileAction.download:
      case FileAction.permissions:
      case FileAction.newFile:
      case FileAction.refresh:
        break;
    }
  }

  void _showProperties(RemoteFile entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _propertyRow('Path', entry.path),
            _propertyRow('Type', entry.isDirectory ? 'Directory' : 'File'),
            _propertyRow('Permissions', entry.permissions),
            if (!entry.isDirectory) _propertyRow('Size', '${entry.sizeBytes ?? 0} bytes'),
            if (entry.isDirectory && entry.itemCount != null) _propertyRow('Items', '${entry.itemCount}'),
            _propertyRow('Modified', entry.modifiedAt.toLocal().toString().split('.').first),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _propertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.onSurfaceVariant))),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12))),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text('This will permanently remove "$name". This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorContainer, foregroundColor: AppColors.onErrorContainer),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showMockTransferNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transfers are simulated in this build — see the Transfers tab.')),
    );
  }

  Future<void> _downloadFile(RemoteFile entry) async {
    if (!mounted) return;

    final transferManager = context.read<TransferManager>();
    final id = transferManager.registerExternalTransfer(
      filename: entry.name,
      direction: TransferDirection.download,
      totalBytes: entry.sizeBytes ?? 0,
    );
    try {
      final bytes = await context.read<SftpService>().download(
            entry.path,
            onProgress: (transferred, total) => transferManager.updateProgress(id, transferred),
          );
      final savedUri = await FilePicker.saveFile(fileName: entry.name, bytes: bytes);
      if (savedUri == null) {
        transferManager.failTransfer(id, 'Download cancelled');
        return;
      }
      transferManager.completeTransfer(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded to $savedUri')));
      }
    } on AppFailure catch (f) {
      transferManager.failTransfer(id, f.title);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: ${f.title}')));
      }
    } catch (e) {
      transferManager.failTransfer(id, 'Download failed');
    }
  }

  Future<void> _uploadFile({String? targetDirectory}) async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty || !mounted) return;
    final file = files.first;
    final bytes = await file.readAsBytes();

    final destination = targetDirectory ?? _currentPath;
    final remotePath = destination == '/' ? '/${file.name}' : '$destination/${file.name}';
    final transferManager = context.read<TransferManager>();
    final id = transferManager.registerExternalTransfer(
      filename: file.name,
      direction: TransferDirection.upload,
      totalBytes: bytes.length,
    );
    try {
      await context.read<SftpService>().upload(
            remotePath,
            bytes,
            onProgress: (transferred, total) => transferManager.updateProgress(id, transferred),
          );
      transferManager.completeTransfer(id);
      if (destination == _currentPath) _load(_currentPath);
    } on AppFailure catch (f) {
      transferManager.failTransfer(id, f.title);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${f.title}')));
      }
    } catch (e) {
      transferManager.failTransfer(id, 'Upload failed');
    }
  }

  Future<void> _newFolder() async {
    final name = await showTextPromptDialog(context, title: 'New Folder');
    if (name == null) return;
    await context.read<SftpService>().createFolder(_currentPath, name);
    _load(_currentPath);
  }

  Future<void> _newFile() async {
    final name = await showTextPromptDialog(context, title: 'New File');
    if (name == null) return;
    await context.read<SftpService>().createFile(_currentPath, name);
    _load(_currentPath);
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ConnectionRepository>().activeConnection;
    return Scaffold(
      appBar: AppTopBar(
        sectionLabel: 'Files',
        activeConnection: active,
        onTapConnectionPill: () => showServerConnectionSheet(context, active),
        onTapConnections: () => context.push('/connections'),
        onTapProfile: () => context.push('/settings'),
        onTapTransfers: () => context.push('/transfers'),
      ),
      body: _buildBody(active),
    );
  }

  Widget _buildBody(ConnectionProfile? active) {
    if (active == null) {
      return const EmptyStateView(
        icon: Icons.dns_outlined,
        title: 'No server selected',
        subtitle: 'Pick a saved connection to browse its files.',
      );
    }
    if (_failure != null) {
      return ErrorStateView(
        failure: _failure!,
        actions: [
          RecoveryAction(label: 'Retry', isPrimary: true, onPressed: () => _connectAndLoad(active)),
          RecoveryAction(label: 'Edit Connection', onPressed: () => context.push('/connections/${active.id}/edit')),
        ],
      );
    }
    if (_loading && _directory == null) {
      return const LoadingStateView(label: 'Loading directory...');
    }
    final dir = _directory;
    if (dir == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_outlined, size: 40, color: AppColors.outline),
              const SizedBox(height: 12),
              const Text('Not connected', style: TextStyle(fontFamily: 'Geist', fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                '${active.username}@${active.host}:${active.port}',
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _connectAndLoad(active),
                icon: const Icon(Icons.power_settings_new, size: 18),
                label: const Text('Connect'),
              ),
            ],
          ),
        ),
      );
    }

    final entries = _filterController.text.isEmpty
        ? dir.entries
        : dir.entries.where((e) => e.name.toLowerCase().contains(_filterController.text.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: BreadcrumbBar(
            segments: dir.pathSegments,
            onTapUp: _goUp,
            onTapSegment: _goToSegment,
            protocolLabel: active.protocol.label,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: StorageGauge(usedBytes: dir.usedBytes, totalBytes: dir.totalBytes),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SftpToolbar(
            controller: _filterController,
            onNewFolder: _newFolder,
            onNewFile: _newFile,
            onUpload: _uploadFile,
            onRefresh: () => _load(_currentPath),
            onToggleSelect: () => setState(() => _selectMode = !_selectMode),
            selectMode: _selectMode,
          ),
        ),
        const SizedBox(height: 6),
        const Divider(height: 1),
        Expanded(
          child: entries.isEmpty
              ? const EmptyStateView(icon: Icons.folder_open, title: 'This folder is empty')
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return FileRow(
                      entry: entry,
                      selected: false,
                      onTap: () => _openEntry(entry),
                      onMore: () => _onRowMore(entry),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
