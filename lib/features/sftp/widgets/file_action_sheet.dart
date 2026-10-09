import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/byte_format.dart';
import '../models/remote_file.dart';

enum FileAction { edit, download, upload, permissions, rename, copyPath, delete, newFolder, newFile, refresh, open, properties }

/// The bottom-sheet action panel shown when a file/folder row is tapped
/// in the Stitch SFTP screen: Edit in Code Editor / Download / Permissions
/// / Rename / Copy Full Path / Delete (with a red destructive treatment).
Future<FileAction?> showFileActionSheet(BuildContext context, RemoteFile entry) {
  return showModalBottomSheet<FileAction>(
    context: context,
    backgroundColor: AppColors.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.insert_drive_file_outlined, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name,
                          style: const TextStyle(
                              fontFamily: 'Geist', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                      Text(
                        '${entry.path} • ${entry.isDirectory ? '${entry.itemCount} items' : formatBytes(entry.sizeBytes ?? 0)}',
                        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.6,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                if (!entry.isDirectory)
                  _tile(context, 'Edit in Code Editor', Icons.code, FileAction.edit, tint: AppColors.primary),
                _tile(context, 'Download', Icons.download, FileAction.download, tint: AppColors.secondary),
                _tile(context, 'Permissions\nchmod ${entry.permissions}', Icons.security, FileAction.permissions,
                    tint: AppColors.tertiary),
                _tile(context, 'Rename', Icons.edit_outlined, FileAction.rename),
                _tile(context, 'Copy Full Path', Icons.copy_all_outlined, FileAction.copyPath),
                _tile(context, 'Delete (rm -f)', Icons.delete_outline, FileAction.delete,
                    tint: AppColors.error, filled: true),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _tile(BuildContext context, String label, IconData icon, FileAction action, {Color? tint, bool filled = false}) {
  final color = tint ?? AppColors.onSurface;
  return Material(
    color: filled ? AppColors.errorContainer.withValues(alpha: 0.16) : AppColors.surfaceContainer,
    borderRadius: BorderRadius.circular(6),
    child: InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => Navigator.pop(context, action),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontFamily: 'Geist', fontSize: 12, fontWeight: FontWeight.w500, color: color),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The bottom-sheet action menu for a DIRECTORY row's three-dot button —
/// distinct from tapping the row itself (which navigates into the
/// directory). This is the fix for the bug where the three-dot button
/// was wired to the same handler as the row tap, so it opened the
/// directory instead of showing a menu.
Future<FileAction?> showDirectoryActionSheet(BuildContext context, RemoteFile entry) {
  return showModalBottomSheet<FileAction>(
    context: context,
    backgroundColor: AppColors.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: AppColors.tertiary.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.folder, size: 16, color: AppColors.tertiary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name,
                          style: const TextStyle(fontFamily: 'Geist', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                      Text('${entry.path} • ${entry.itemCount ?? 0} items',
                          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 18, color: AppColors.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.6,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _tile(context, 'Open', Icons.folder_open, FileAction.open, tint: AppColors.tertiary),
                _tile(context, 'New Folder Inside', Icons.create_new_folder_outlined, FileAction.newFolder, tint: AppColors.tertiary),
                _tile(context, 'Upload Into Directory', Icons.upload_outlined, FileAction.upload, tint: AppColors.secondary),
                _tile(context, 'Rename', Icons.edit_outlined, FileAction.rename),
                _tile(context, 'Copy Full Path', Icons.copy_all_outlined, FileAction.copyPath),
                _tile(context, 'Properties', Icons.info_outline, FileAction.properties),
                _tile(context, 'Delete', Icons.delete_outline, FileAction.delete, tint: AppColors.error, filled: true),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
