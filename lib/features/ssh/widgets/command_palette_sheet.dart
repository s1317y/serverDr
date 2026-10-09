import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../commands/data/default_commands.dart';
import '../../commands/models/command_shortcut.dart';
import '../../commands/services/command_library_store.dart';

/// The "Fast Command Palette" bottom sheet: search, category filter
/// chips, a Favorites section, a Recent section, and the full library —
/// now 146+ commands across 26 categories. Tapping a command:
///  - if it's parameterized (`{placeholder}` tokens), prompts for each
///    value first, then returns the resolved command text;
///  - otherwise returns the command text directly.
/// The caller (terminal screen) is responsible for actually running it
/// and for recording it as "recent" once it's actually been used.
Future<String?> showCommandPaletteSheet(BuildContext context) async {
  final picked = await showModalBottomSheet<CommandShortcut>(
    context: context,
    backgroundColor: AppColors.surfaceContainerHigh,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const _CommandPaletteSheet(),
  );
  if (picked == null) return null;
  if (!context.mounted) return picked.command;

  String resolved = picked.command;
  if (picked.isParameterized) {
    final values = await _promptForPlaceholders(context, picked);
    if (values == null) return null; // user cancelled the parameter prompt
    resolved = picked.resolve(values);
  }

  if (context.mounted) {
    await context.read<CommandLibraryStore>().recordRecent(resolved);
  }
  return resolved;
}

Future<Map<String, String>?> _promptForPlaceholders(BuildContext context, CommandShortcut cmd) async {
  final controllers = {for (final p in cmd.placeholders) p: TextEditingController()};
  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(cmd.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cmd.command, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          for (final p in cmd.placeholders) ...[
            TextField(
              controller: controllers[p],
              autofocus: p == cmd.placeholders.first,
              decoration: InputDecoration(labelText: p),
              style: const TextStyle(fontFamily: 'JetBrains Mono'),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, {for (final p in cmd.placeholders) p: controllers[p]!.text.trim()}),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  for (final c in controllers.values) {
    c.dispose();
  }
  return result;
}

class _CommandPaletteSheet extends StatefulWidget {
  const _CommandPaletteSheet();

  @override
  State<_CommandPaletteSheet> createState() => _CommandPaletteSheetState();
}

class _CommandPaletteSheetState extends State<_CommandPaletteSheet> {
  CommandCategory? _filter;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<CommandLibraryStore>();
    final favoriteIds = library.favoriteIds;
    final recentCommands = library.recentCommands;
    final query = _searchController.text.trim().toLowerCase();

    Iterable<CommandShortcut> pool = kDefaultCommands;
    if (_filter != null) pool = pool.where((c) => c.category == _filter);
    if (query.isNotEmpty) {
      pool = pool.where((c) =>
          c.name.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query) ||
          c.category.label.toLowerCase().contains(query) ||
          c.command.toLowerCase().contains(query));
    }
    final commands = pool.toList();
    final favorites = query.isEmpty && _filter == null
        ? kDefaultCommands.where((c) => favoriteIds.contains(c.id)).toList()
        : <CommandShortcut>[];

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
                  decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.terminal, size: 18, color: AppColors.onPrimaryContainer),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Fast Command Palette (${kDefaultCommands.length})',
                      style: const TextStyle(fontFamily: 'Geist', fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search ${kDefaultCommands.length} commands...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                    : null,
              ),
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
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (favorites.isNotEmpty) ...[
                    _sectionLabel('FAVORITES'),
                    for (final cmd in favorites) _commandTile(context, cmd, favoriteIds, isFavorite: true),
                    const SizedBox(height: 8),
                  ],
                  if (recentCommands.isNotEmpty && query.isEmpty && _filter == null) ...[
                    _sectionLabel('RECENT'),
                    for (final text in recentCommands.take(5)) _recentTile(context, text),
                    const SizedBox(height: 8),
                  ],
                  _sectionLabel(query.isEmpty && _filter == null ? 'ALL COMMANDS' : '${commands.length} RESULTS'),
                  for (final cmd in commands) _commandTile(context, cmd, favoriteIds, isFavorite: favoriteIds.contains(cmd.id)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text,
            style: const TextStyle(
                fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.primary)),
      );

  Widget _recentTile(BuildContext context, String commandText) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => Navigator.pop(
        context,
        CommandShortcut(name: commandText, command: commandText, description: 'Recently run', category: CommandCategory.system),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
        child: Row(
          children: [
            const Icon(Icons.history, size: 14, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(commandText,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.onSurface)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commandTile(BuildContext context, CommandShortcut cmd, Set<String> favoriteIds, {required bool isFavorite}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => Navigator.pop(context, cmd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          cmd.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Geist', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        ),
                      ),
                      if (cmd.dangerous) ...[const SizedBox(width: 4), const Icon(Icons.warning_amber, size: 12, color: AppColors.error)],
                      if (cmd.isParameterized) ...[const SizedBox(width: 4), const Icon(Icons.tune, size: 12, color: AppColors.primary)],
                    ],
                  ),
                  Text(
                    cmd.command,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(3)),
            child: Text(cmd.category.label.toUpperCase(),
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 9, color: AppColors.onSurfaceVariant)),
          ),
          IconButton(
            icon: Icon(isFavorite ? Icons.star : Icons.star_border, size: 18, color: isFavorite ? AppColors.tertiary : AppColors.onSurfaceVariant),
            onPressed: () => context.read<CommandLibraryStore>().toggleFavorite(cmd.id),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
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
