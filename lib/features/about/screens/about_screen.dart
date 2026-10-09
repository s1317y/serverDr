import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/serverdr_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About ServerDr')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: ServerDrLogo(size: 64)),
          const SizedBox(height: 12),
          const Center(
            child: Text('ServerDr',
                style: TextStyle(fontFamily: 'Geist', fontSize: 20, fontWeight: FontWeight.w600)),
          ),
          const Center(
            child: Text('Your server doctor.',
                style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.onSurfaceVariant)),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('Android Beta',
                style: TextStyle(
                    fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.onSurfaceVariant)),
          ),
          const SizedBox(height: 20),
          const Text(
            'A professional IT support and server administration app. Real SSH terminal, '
            'real SFTP file management, remote editing, a server website browser, live '
            'health monitoring, and a security audit workspace — connecting directly from '
            'your device to your infrastructure, with no mandatory account, login, or backend.',
            style: TextStyle(
                fontFamily: 'Geist', fontSize: 13, height: 1.5, color: AppColors.onSurfaceVariant),
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
              'SSH, SFTP, host-key verification, credential storage, health collection, and '
              'security checks connect to and run against your real, authenticated server. '
              'FTP/FTPS and the Web SaaS dashboard are not implemented in this build.',
              style: TextStyle(
                  fontFamily: 'Geist', fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Credits — the creator, plus a single link out to the auto-generated
/// open-source license page (kept short and separate rather than a
/// hand-maintained package-by-package list).
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credits')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ServerDr',
                    style:
                        TextStyle(fontFamily: 'Geist', fontSize: 18, fontWeight: FontWeight.w600)),
                Text('Your server doctor.',
                    style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const Divider(height: 24),
          const ListTile(
            title: Text('Muhammad Sibily P. S.'),
            subtitle: Text('Creator / Developer'),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Open Source Licenses'),
            subtitle: const Text('Third-party packages this app depends on'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => showLicensePage(context: context, applicationName: 'ServerDr'),
          ),
        ],
      ),
    );
  }
}

/// Support / donation placeholder.
///
/// Intentionally non-functional for this beta: no payment or billing SDK
/// is integrated, and no official support URL exists yet. The button is
/// deliberately disabled and labeled "Coming Soon" rather than being a
/// working-looking dead link.
class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support ServerDr')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, size: 40, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'If ServerDr is useful to you, you can support its continued development.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Geist', fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: null,
              icon: Icon(Icons.favorite_border, size: 16),
              label: Text('Coming Soon'),
            ),
          ],
        ),
      ),
    );
  }
}