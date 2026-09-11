import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../features/connections/models/connection_profile.dart';
import '../../features/sftp/services/sftp_service.dart';
import '../../features/ssh/services/ssh_service.dart';

/// Bottom sheet for the active-connection pill in the top bar: shows which
/// server is active and offers "Switch Server" and — the thing that was
/// missing — an explicit "Disconnect" action that tears down any live
/// SSH/SFTP sessions for this profile without deleting the saved profile
/// itself. Reopening Terminal/Files afterward reconnects fresh (including
/// host-key verification again if the session had gone stale).
Future<void> showServerConnectionSheet(BuildContext context, ConnectionProfile? profile) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => _ServerConnectionSheet(profile: profile),
  );
}

class _ServerConnectionSheet extends StatefulWidget {
  const _ServerConnectionSheet({required this.profile});

  final ConnectionProfile? profile;

  @override
  State<_ServerConnectionSheet> createState() => _ServerConnectionSheetState();
}

class _ServerConnectionSheetState extends State<_ServerConnectionSheet> {
  bool _disconnecting = false;

  Future<void> _disconnect() async {
    final profile = widget.profile;
    if (profile == null) return;
    setState(() => _disconnecting = true);
    try {
      await context.read<SshService>().disconnect(profile.id);
      await context.read<SftpService>().disconnect();
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile == null) ...[
              const Text('No server selected', style: TextStyle(fontFamily: 'Geist', fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
            ] else ...[
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(profile.name,
                        style: const TextStyle(fontFamily: 'Geist', fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${profile.username}@${profile.host}:${profile.port}',
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dns_outlined, color: AppColors.onSurfaceVariant),
              title: const Text('Switch Server'),
              subtitle: const Text('Choose a different saved connection'),
              onTap: () {
                Navigator.pop(context);
                context.push('/connections');
              },
            ),
            if (profile != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _disconnecting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.link_off, color: AppColors.error),
                title: const Text('Disconnect', style: TextStyle(color: AppColors.error)),
                subtitle: const Text('Ends the active SSH/SFTP sessions for this server'),
                onTap: _disconnecting ? null : _disconnect,
              ),
          ],
        ),
      ),
    );
  }
}
