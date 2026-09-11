import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class CommandInputBar extends StatelessWidget {
  const CommandInputBar({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.onHistoryPrev,
    required this.enabled,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onHistoryPrev;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            onPressed: onHistoryPrev,
            tooltip: 'Previous command',
            icon: const Icon(Icons.history, size: 18, color: AppColors.onSurfaceVariant),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Text(
                    r'$ ',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: enabled,
                      autocorrect: false,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 13,
                        color: AppColors.onSurface,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Type Linux command or snippet...',
                      ),
                      onSubmitted: (_) => onSubmit(),
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    InkWell(
                      onTap: () => controller.clear(),
                      child: const Icon(Icons.cancel, size: 16, color: AppColors.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.secondaryContainer,
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: enabled ? onSubmit : null,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EXEC',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSecondaryContainer,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_return, size: 16, color: AppColors.onSecondaryContainer),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
