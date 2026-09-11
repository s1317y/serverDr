import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class SftpToolbar extends StatelessWidget {
  const SftpToolbar({
    super.key,
    required this.controller,
    required this.onNewFolder,
    required this.onNewFile,
    required this.onUpload,
    required this.onRefresh,
    required this.onToggleSelect,
    required this.selectMode,
  });

  final TextEditingController controller;
  final VoidCallback onNewFolder;
  final VoidCallback onNewFile;
  final VoidCallback onUpload;
  final VoidCallback onRefresh;
  final VoidCallback onToggleSelect;
  final bool selectMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.onSurface),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Filter files by name or ext...',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        _ToolbarButton(icon: Icons.create_new_folder_outlined, color: AppColors.tertiary, onTap: onNewFolder),
        _ToolbarButton(icon: Icons.note_add_outlined, color: AppColors.primary, onTap: onNewFile),
        _ToolbarButton(icon: Icons.upload_outlined, color: AppColors.secondary, onTap: onUpload),
        _ToolbarButton(icon: Icons.refresh, onTap: onRefresh),
        _ToolbarButton(
          icon: Icons.checklist_rtl,
          onTap: onToggleSelect,
          selected: selectMode,
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon, required this.onTap, this.color, this.selected = false});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: selected ? AppColors.primaryContainer : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 17, color: selected ? AppColors.onPrimaryContainer : (color ?? AppColors.onSurfaceVariant)),
          ),
        ),
      ),
    );
  }
}
