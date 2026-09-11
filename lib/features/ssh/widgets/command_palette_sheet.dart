import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../commands/data/default_commands.dart';
import '../../commands/models/command_shortcut.dart';

/// The "Fast Command Palette" bottom sheet from the Stitch prototype:
/// category filter chips + a scrollable list of [CommandShortcut]s. Tapping
/// one returns it to the caller to populate the command buffer.
Future<CommandShortcut?> showCommandPaletteSheet(BuildContext context) {
  return showModalBottomSheet<CommandShortcut>(
    context: context,
    backgroundColor: AppColors.surfaceContainerHigh,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const _CommandPaletteSheet(),
  );
}

class _CommandPaletteSheet extends StatefulWidget {
  const _CommandPaletteSheet();

  @override
  State<_CommandPaletteSheet> createState() => _CommandPaletteSheetState();
}

class _CommandPaletteSheetState extends State<_CommandPaletteSheet> {
  CommandCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final commands = _filter == null
        ? kDefaultCommands
        : kDefaultCommands.where((c) => c.category == _filter).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.terminal, size: 18, color: AppColors.onPrimaryContainer),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fast Command Palette',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'Instant execution snippets for triage & diagnostics',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'ALL', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                  for (final category in CommandCategory.values)
                    _FilterChip(
                      label: category.label.toUpperCase(),
                      selected: _filter == category,
                      onTap: () => setState(() => _filter = category),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: commands.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final cmd = commands[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => Navigator.pop(context, cmd),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        cmd.command,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'JetBrains Mono',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (cmd.dangerous) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.warning_amber, size: 12, color: AppColors.error),
                                    ],
                                  ],
                                ),
                                Text(
                                  cmd.description,
                                  style: const TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              cmd.category.label.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 10,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tap snippet to populate command buffer',
                  style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
                Text(
                  '${commands.length} presets',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
