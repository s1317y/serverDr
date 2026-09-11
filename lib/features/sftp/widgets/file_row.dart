import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/byte_format.dart';
import '../../../core/utils/relative_time.dart';
import '../models/remote_file.dart';

/// One dense file/folder row: icon, name + badges, permissions, size,
/// modified time, overflow menu — matching the Stitch SFTP screen rows.
class FileRow extends StatelessWidget {
  const FileRow({
    super.key,
    required this.entry,
    required this.selected,
    required this.onTap,
    required this.onMore,
  });

  final RemoteFile entry;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceContainerHigh : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _leadingIcon(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: entry.badge == RemoteEntryBadge.secure
                                  ? AppColors.error
                                  : AppColors.onSurface,
                            ),
                          ),
                        ),
                        if (entry.typeLabel != null) ...[
                          const SizedBox(width: 6),
                          _chip(entry.typeLabel!, AppColors.onSurfaceVariant, AppColors.surfaceContainerHigh),
                        ],
                        if (entry.badge == RemoteEntryBadge.live) ...[
                          const SizedBox(width: 6),
                          _chip('LIVE', AppColors.onSecondaryContainer, AppColors.secondaryContainer),
                        ],
                        if (entry.badge == RemoteEntryBadge.active) ...[
                          const SizedBox(width: 6),
                          _chip('ACTIVE', AppColors.onPrimaryContainer, AppColors.primaryContainer),
                        ],
                        if (entry.badge == RemoteEntryBadge.secure) ...[
                          const SizedBox(width: 6),
                          _chip('SECURE', AppColors.onErrorContainer, AppColors.errorContainer, icon: Icons.lock),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.isDirectory ? '${entry.permissions} · ${entry.itemCount} items' : entry.permissions,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!entry.isDirectory)
                    Text(
                      formatBytes(entry.sizeBytes ?? 0),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    formatRelativeTime(entry.modifiedAt),
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      color: entry.badge == RemoteEntryBadge.live ? AppColors.secondary : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: onMore,
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.onSurfaceVariant),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leadingIcon() {
    final Color color;
    final IconData icon;
    if (entry.isDirectory) {
      color = AppColors.tertiary;
      icon = Icons.folder;
    } else if (entry.typeLabel == 'YML') {
      color = AppColors.primary;
      icon = Icons.data_object;
    } else if (entry.typeLabel == 'GZ') {
      color = AppColors.tertiary;
      icon = Icons.archive;
    } else if (entry.name.endsWith('.html')) {
      color = AppColors.error;
      icon = Icons.html;
    } else if (entry.badge == RemoteEntryBadge.active) {
      color = AppColors.primary;
      icon = Icons.settings;
    } else if (entry.badge == RemoteEntryBadge.secure) {
      color = AppColors.error;
      icon = Icons.key;
    } else {
      color = AppColors.onSurfaceVariant;
      icon = Icons.insert_drive_file_outlined;
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _chip(String label, Color fg, Color bg, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 9, color: fg), const SizedBox(width: 2)],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
