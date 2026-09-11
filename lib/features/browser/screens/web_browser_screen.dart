import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/server_connection_sheet.dart';
import '../../connections/services/connection_repository.dart';
import '../services/web_view_service.dart';

class WebBrowserScreen extends StatefulWidget {
  const WebBrowserScreen({super.key});

  @override
  State<WebBrowserScreen> createState() => _WebBrowserScreenState();
}

class _WebBrowserScreenState extends State<WebBrowserScreen> {
  final _urlController = TextEditingController();
  bool _loadedInitial = false;

  @override
  Widget build(BuildContext context) {
    final connections = context.watch<ConnectionRepository>();
    final active = connections.activeConnection;
    final web = context.watch<WebViewService>();

    if (!_loadedInitial && active?.websiteUrl != null) {
      _loadedInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        web.load(active!.websiteUrl!);
        _urlController.text = active.websiteUrl!;
      });
    }

    return Scaffold(
      appBar: AppTopBar(
        sectionLabel: 'Web',
        activeConnection: active,
        onTapConnectionPill: () => showServerConnectionSheet(context, active),
        onTapConnections: () => context.push('/connections'),
        onTapProfile: () => context.push('/settings'),
        onTapTransfers: () => context.push('/transfers'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: AppColors.surfaceContainer,
            child: Row(
              children: [
                IconButton(
                  onPressed: web.canGoBack ? web.goBack : null,
                  icon: const Icon(Icons.arrow_back, size: 18),
                ),
                IconButton(
                  onPressed: web.canGoForward ? web.goForward : null,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                ),
                IconButton(onPressed: web.reload, icon: const Icon(Icons.refresh, size: 18)),
                Expanded(
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          web.currentUrl.startsWith('https') ? Icons.lock : Icons.lock_open,
                          size: 13,
                          color: web.currentUrl.startsWith('https') ? AppColors.secondary : AppColors.tertiary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Enter URL'),
                            onSubmitted: web.load,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (value) {
                    switch (value) {
                      case 'fresh':
                        web.hardReload();
                      case 'share':
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Share sheet not wired up in Phase 1.')));
                      case 'desktop':
                        web.setDesktopMode(!web.desktopMode);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'fresh', child: Text('Fresh load (bypass cache)')),
                    const PopupMenuItem(value: 'share', child: Text('Share')),
                    PopupMenuItem(value: 'desktop', child: Text(web.desktopMode ? 'Switch to mobile mode' : 'Switch to desktop mode')),
                  ],
                ),
              ],
            ),
          ),
          if (web.isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: Container(
              color: AppColors.surfaceContainerLowest,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public, size: 40, color: AppColors.outline),
                  const SizedBox(height: 12),
                  Text(
                    web.currentUrl.isEmpty ? 'No page loaded' : web.currentUrl,
                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Android WebView rendering arrives in Phase 8. This screen wires up '
                    'the full navigation UI/UX against a stub service today.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.outline),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
