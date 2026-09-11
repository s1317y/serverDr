import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../models/command_shortcut.dart';

/// Confirmation gate for [CommandShortcut.dangerous] commands, or any
/// free-typed command the palette/terminal decides looks destructive.
/// Returns `true` if the user confirmed.
Future<bool> showDangerousCommandDialog(BuildContext context, String command) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          SizedBox(width: 8),
          Text('Confirm command'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This command is flagged as potentially destructive:'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Text(
              command,
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.error),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.errorContainer, foregroundColor: AppColors.onErrorContainer),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Run anyway'),
        ),
      ],
    ),
  );
  return result ?? false;
}
