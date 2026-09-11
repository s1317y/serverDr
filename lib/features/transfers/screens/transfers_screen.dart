import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/byte_format.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/server_connection_sheet.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../connections/services/connection_repository.dart';
import '../models/transfer_item.dart';
import '../services/transfer_manager.dart';

class TransfersScreen extends StatelessWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<TransferManager>();
    final active = context.watch<ConnectionRepository>().activeConnection;

    return Scaffold(
      appBar: AppTopBar(
        sectionLabel: 'Transfers',
        activeConnection: active,
        onTapConnectionPill: () => showServerConnectionSheet(context, active),
        onTapConnections: () => context.push('/connections'),
        onTapProfile: () => context.push('/settings'),
        onTapTransfers: () {},
        pendingTransfers: manager.activeCount,
      ),
      body: manager.transfers.isEmpty
          ? const EmptyStateView(icon: Icons.sync_alt, title: 'No transfers', subtitle: 'Uploads and downloads will appear here.')
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: manager.transfers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _TransferTile(
                item: manager.transfers[index],
                onPause: () => manager.pause(manager.transfers[index].id),
                onResume: () => manager.resume(manager.transfers[index].id),
                onCancel: () => manager.cancel(manager.transfers[index].id),
                onRetry: () => manager.retry(manager.transfers[index].id),
              ),
            ),
      floatingActionButton: manager.transfers.any((t) => t.status == TransferStatus.completed || t.status == TransferStatus.cancelled)
          ? FloatingActionButton.extended(
              onPressed: manager.clearCompleted,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear completed'),
            )
          : null,
    );
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({
    required this.item,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetry,
  });

  final TransferItem item;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status) {
      TransferStatus.completed => AppColors.secondary,
      TransferStatus.failed => AppColors.error,
      TransferStatus.cancelled => AppColors.outline,
      TransferStatus.paused => AppColors.tertiary,
      _ => AppColors.primary,
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.direction == TransferDirection.upload ? Icons.upload : Icons.download,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.filename,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Geist', fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                item.status.name.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 5,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${formatBytes(item.transferredBytes)} / ${formatBytes(item.totalBytes)}'
                '${item.status == TransferStatus.running ? ' · ${formatBytes(item.speedBytesPerSec.round())}/s' : ''}',
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
              Row(
                children: [
                  if (item.status == TransferStatus.running)
                    _actionButton('Pause', onPause)
                  else if (item.status == TransferStatus.paused)
                    _actionButton('Resume', onResume),
                  if (item.status == TransferStatus.failed) _actionButton('Retry', onRetry),
                  if (item.status == TransferStatus.running || item.status == TransferStatus.queued || item.status == TransferStatus.paused)
                    _actionButton('Cancel', onCancel),
                ],
              ),
            ],
          ),
          if (item.error != null) ...[
            const SizedBox(height: 4),
            Text(item.error!, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.error)),
          ],
        ],
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 6)),
      child: Text(label, style: const TextStyle(fontFamily: 'Geist', fontSize: 11)),
    );
  }
}
