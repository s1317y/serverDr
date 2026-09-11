import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true; // Dark-first design; no light theme exists yet.
  double _fontSize = 13;
  String _terminalFont = 'JetBrains Mono';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('ServerKit is dark-first; a light theme isn\'t built yet'),
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          const _SectionHeader('Terminal'),
          ListTile(
            title: const Text('Font Size'),
            subtitle: Slider(
              value: _fontSize,
              min: 10,
              max: 18,
              divisions: 8,
              label: _fontSize.round().toString(),
              onChanged: (v) => setState(() => _fontSize = v),
            ),
          ),
          ListTile(
            title: const Text('Terminal Font'),
            trailing: DropdownButton<String>(
              value: _terminalFont,
              items: const [
                DropdownMenuItem(value: 'JetBrains Mono', child: Text('JetBrains Mono')),
                DropdownMenuItem(value: 'Fira Code', child: Text('Fira Code')),
                DropdownMenuItem(value: 'System Monospace', child: Text('System Monospace')),
              ],
              onChanged: (v) => setState(() => _terminalFont = v!),
            ),
          ),
          const _SectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: const Text('Known SSH Hosts'),
            subtitle: const Text('Manage trusted host key fingerprints'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/known-hosts'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
            title: const Text('Clear Session Data'),
            subtitle: const Text('Removes cached sessions and mock credentials on this device'),
            onTap: () => _confirmClearSession(context),
          ),
          const _SectionHeader('Application'),
          const ListTile(title: Text('Check for Updates'), trailing: Icon(Icons.chevron_right)),
          const ListTile(title: Text('Version'), trailing: Text('0.1.0 (Phase 1)')),
          const _SectionHeader('Support'),
          ListTile(
            leading: const Icon(Icons.favorite_border, color: AppColors.error),
            title: const Text('Donate'),
            onTap: () => context.push('/about/donate'),
          ),
          const _SectionHeader('About'),
          ListTile(title: const Text('About ServerKit'), onTap: () => context.push('/about')),
          ListTile(title: const Text('Credits'), onTap: () => context.push('/about/credits')),
          ListTile(
            title: const Text('Open Source Licenses'),
            onTap: () => showLicensePage(context: context, applicationName: 'ServerKit'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _confirmClearSession(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear session data?'),
        content: const Text('This clears cached mock sessions on this device. It does not affect any real server.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Clear')),
        ],
      ),
    );
  }
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
