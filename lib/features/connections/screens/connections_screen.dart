import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/storage/secure_credential_store.dart';
import '../../../core/utils/relative_time.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../ssh/widgets/host_key_verification_dialog.dart';
import '../models/connection_profile.dart';
import '../models/server_connection_state.dart';
import '../services/connection_repository.dart';
import '../services/server_connection_manager.dart';

/// Saved Connections list.
///
/// IMPORTANT: the connection-status dot here reflects REAL live state
/// from [ServerConnectionManager] — never "this profile is the selected
/// one" (that was the bug: a saved/selected server is not a connected
/// server). Opening this screen never connects anything by itself.
class ConnectionsScreen extends StatelessWidget {
  const ConnectionsScreen({super.key});

  void _openTab(BuildContext context, ConnectionRepository repo, ConnectionProfile c, String route) {
    repo.setActive(c.id);
    context.go(route);
  }

  Future<void> _connect(BuildContext context, ConnectionProfile c) async {
    try {
      await context.read<ServerConnectionManager>().connect(
            c,
            onHostKeyVerification: (r) => showHostKeyVerificationDialog(context, r),
          );
    } catch (_) {
      // Failure state is already recorded by the manager and shown via
      // the status dot/label; nothing else to do here.
    }
  }

  Future<void> _disconnect(BuildContext context, ConnectionProfile c) async {
    await context.read<ServerConnectionManager>().disconnect(c.id);
  }

  Future<void> _delete(BuildContext context, ConnectionProfile c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete connection?'),
        content: Text('This removes "${c.name}" and any stored credentials for it. This cannot be undone.'),
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
    if (confirmed != true || !context.mounted) return;
    await context.read<ServerConnectionManager>().disconnect(c.id);
    await context.read<SecureCredentialStore>().clearAll(c.id);
    if (context.mounted) await context.read<ConnectionRepository>().delete(c.id);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ConnectionRepository>();
    final manager = context.watch<ServerConnectionManager>();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Connections')),
      body: repo.connections.isEmpty
          ? const EmptyStateView(
              icon: Icons.dns_outlined,
              title: 'No saved connections',
              subtitle: 'Add a server to start an SSH, SFTP, or FTP session.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: repo.connections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final c = repo.connections[index];
                final state = manager.stateFor(c.id);
                final isSelected = repo.activeConnection?.id == c.id;
                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.surfaceContainerHigh : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _statusDot(state),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(c.name,
                                  style: const TextStyle(fontFamily: 'Geist', fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                c.protocol.label,
                                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 9, color: AppColors.onSurfaceVariant),
                              ),
                            ),
                            if (!c.protocol.isEncrypted) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.lock_open, size: 12, color: AppColors.error),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${c.username}@${c.host}:${c.port}',
                                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant),
                              ),
                            ),
                            Text(
                              state.label,
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(state),
                              ),
                            ),
                          ],
                        ),
                        if (c.lastConnectedAt != null)
                          Text(
                            'Last connected ${formatRelativeTime(c.lastConnectedAt!)}',
                            style: const TextStyle(fontFamily: 'Geist', fontSize: 10, color: AppColors.outline),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (state.isTransient)
                              const SizedBox(width: 78, height: 28, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))))
                            else if (state == ServerConnectionState.connected)
                              _actionChip(context, icon: Icons.link_off, label: 'Disconnect', tint: AppColors.error, onTap: () => _disconnect(context, c))
                            else
                              _actionChip(context, icon: Icons.power_settings_new, label: 'Connect', tint: AppColors.secondary, onTap: () => _connect(context, c)),
                            const SizedBox(width: 6),
                            _actionChip(context, icon: Icons.terminal, label: 'SSH', onTap: () => _openTab(context, repo, c, '/terminal')),
                            const SizedBox(width: 6),
                            _actionChip(context, icon: Icons.folder_outlined, label: 'Files', onTap: () => _openTab(context, repo, c, '/files')),
                            const SizedBox(width: 6),
                            _actionChip(context, icon: Icons.monitor_heart_outlined, label: 'Health', onTap: () => context.push('/health/${c.id}')),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _actionChip(context, icon: Icons.shield_outlined, label: 'Security', onTap: () => _openTab(context, repo, c, '/security')),
                            const SizedBox(width: 6),
                            _actionChip(
                              context,
                              icon: Icons.public,
                              label: 'Web',
                              enabled: c.websiteUrl != null,
                              onTap: () => _openTab(context, repo, c, '/web'),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => context.push('/connections/${c.id}/edit'),
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.onSurfaceVariant),
                            ),
                            IconButton(
                              onPressed: () => _delete(context, c),
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/connections/new/edit'),
        icon: const Icon(Icons.add),
        label: const Text('New connection'),
      ),
    );
  }

  Color _statusColor(ServerConnectionState state) => switch (state) {
        ServerConnectionState.connected => AppColors.secondary,
        ServerConnectionState.connecting || ServerConnectionState.reconnecting => AppColors.tertiary,
        ServerConnectionState.connectionFailed ||
        ServerConnectionState.authenticationFailed ||
        ServerConnectionState.hostVerificationRequired =>
          AppColors.error,
        ServerConnectionState.disconnected => AppColors.outline,
      };

  Widget _statusDot(ServerConnectionState state) {
    final color = _statusColor(state);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: state == ServerConnectionState.connected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)] : null,
      ),
    );
  }

  Widget _actionChip(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap, bool enabled = true, Color? tint}) {
    return Material(
      color: AppColors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: tint ?? AppColors.onSurface),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: tint ?? AppColors.onSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
