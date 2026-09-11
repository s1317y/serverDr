import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/serverkit_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About ServerKit')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: ServerKitLogo(size: 64)),
          const SizedBox(height: 12),
          const Center(
            child: Text('ServerKit', style: TextStyle(fontFamily: 'Geist', fontSize: 20, fontWeight: FontWeight.w600)),
          ),
          const Center(
            child: Text('Version 0.1.0 (Phase 1)',
                style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.onSurfaceVariant)),
          ),
          const SizedBox(height: 20),
          const Text(
            'A lightweight, professional IT support and server administration app. '
            'SSH terminal, SFTP/FTP file management, remote editing, and a web '
            'browser tab — connecting directly from your device to your '
            'infrastructure, with no mandatory account, login, or backend.',
            style: TextStyle(fontFamily: 'Geist', fontSize: 13, height: 1.5, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: const Text(
              'This build is Phase 1: UI and architecture only. SSH, SFTP, and FTP '
              'sessions shown here are simulated — no data leaves this device.',
              style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credits')),
      body: ListView(
        children: const [
          ListTile(title: Text('Flutter & Dart'), subtitle: Text('Google — BSD-3-Clause')),
          ListTile(title: Text('go_router'), subtitle: Text('Flutter team — BSD-3-Clause')),
          ListTile(title: Text('provider'), subtitle: Text('Remi Rousselet — MIT')),
          ListTile(title: Text('Geist typeface'), subtitle: Text('Vercel')),
          ListTile(title: Text('JetBrains Mono typeface'), subtitle: Text('JetBrains — Apache-2.0')),
          ListTile(title: Text('UI design'), subtitle: Text('Generated with Google Stitch, adapted for Flutter')),
        ],
      ),
    );
  }
}

class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 40, color: AppColors.error),
            SizedBox(height: 16),
            Text(
              'ServerKit has no account, no login, and no ads. If it\'s useful to '
              'you, donations help keep it that way.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            SizedBox(height: 20),
            Text(
              'Donation links aren\'t wired up in Phase 1.',
              style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.outline),
            ),
          ],
        ),
      ),
    );
  }
}
