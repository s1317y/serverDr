import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../services/ui_preferences_controller.dart';

/// Real, functional Settings. Every control here either genuinely works
/// (and is wired to a controller/persisted value) or is explicitly
/// labeled "Coming soon" — per the brief, no fake toggles that look
/// functional but silently do nothing.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeModeController>();
    final uiPrefs = context.watch<UiPreferencesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(themeController.mode)),
            trailing: DropdownButton<ThemeMode>(
              value: themeController.mode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              ],
              onChanged: (mode) => themeController.setMode(mode!),
            ),
          ),
          ListTile(
            title: const Text('UI Scale'),
            subtitle: Text(uiPrefs.uiScale.label),
            trailing: DropdownButton<UiScale>(
              value: uiPrefs.uiScale,
              underline: const SizedBox.shrink(),
              items: UiScale.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
              onChanged: (s) => uiPrefs.setUiScale(s!),
            ),
          ),
          ListTile(
            title: const Text('Terminal Font Size'),
            subtitle: Slider(
              value: uiPrefs.terminalFontSize,
              min: 10,
              max: 20,
              divisions: 10,
              label: uiPrefs.terminalFontSize.round().toString(),
              onChanged: (v) => uiPrefs.setTerminalFontSize(v),
            ),
          ),
          ListTile(
            title: const Text('Editor Font Size'),
            subtitle: Slider(
              value: uiPrefs.editorFontSize,
              min: 10,
              max: 20,
              divisions: 10,
              label: uiPrefs.editorFontSize.round().toString(),
              onChanged: (v) => uiPrefs.setEditorFontSize(v),
            ),
          ),
          const _ComingSoonTile(title: 'Font Family', subtitle: 'Geist (UI) / JetBrains Mono (terminal & code) — bundled fonts not yet included in this build; system fallback is used'),

          _SectionHeader('Connections'),
          const _ComingSoonTile(title: 'SSH / SFTP Defaults', subtitle: 'Default port, keepalive interval'),
          const _ComingSoonTile(title: 'Connection Timeout', subtitle: 'Currently fixed at 15 seconds'),

          _SectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: const Text('Known SSH Hosts'),
            subtitle: const Text('Manage trusted host key fingerprints'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/known-hosts'),
          ),
          const _ComingSoonTile(title: 'Confirmation Behavior', subtitle: 'Dangerous commands always require confirmation — not yet configurable'),

          _SectionHeader('Monitoring'),
          const _ComingSoonTile(title: 'Default Monitoring Interval', subtitle: 'Configure per-server from that server\'s Health screen for now'),
          const _ComingSoonTile(title: 'Stale Threshold', subtitle: 'Currently fixed at 10 minutes'),

          _SectionHeader('Storage'),
          const _ComingSoonTile(title: 'Command History Retention', subtitle: 'Currently fixed at the last 20 commands'),

          _SectionHeader('Support'),
          ListTile(
            leading: const Icon(Icons.favorite_border, color: AppColors.error),
            title: const Text('Support ServerDr'),
            onTap: () => context.push('/about/donate'),
          ),

          _SectionHeader('About'),
          ListTile(title: const Text('About ServerDr'), onTap: () => context.push('/about')),
          ListTile(title: const Text('Credits'), onTap: () => context.push('/about/credits')),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.dark => 'Dark',
        ThemeMode.light => 'Light',
        ThemeMode.system => 'System',
      };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// A setting the brief calls for that isn't implemented yet — shown
/// disabled with an explicit "Coming soon" label rather than as a toggle
/// that looks functional but does nothing.
class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(3)),
          child: const Text('COMING SOON',
              style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 9, color: AppColors.onSurfaceVariant)),
        ),
      ),
    );
  }
}
