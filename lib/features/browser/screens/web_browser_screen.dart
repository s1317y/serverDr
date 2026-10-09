import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/server_connection_sheet.dart';
import '../../connections/services/connection_repository.dart';

enum _CacheMode { normal, bypass }

/// Real in-app browser for the connected server's website, backed by
/// the official `webview_flutter` (Android WebView / iOS WKWebView).
///
/// "Hard Reload / No Cache" is a REAL cache bypass, not a UI toggle:
/// it calls `WebViewController.clearCache()` (HTTP cache + cache API +
/// application cache + local storage — see that method's platform docs)
/// and additionally appends a cache-busting query parameter before
/// reloading, since some CDNs/proxies ignore cache-control headers
/// entirely. It does NOT clear cookies — that's a separate, explicit
/// "Clear Cookies" action, per the brief's "don't destroy cookies
/// automatically" requirement.
class WebBrowserScreen extends StatefulWidget {
  const WebBrowserScreen({super.key});

  @override
  State<WebBrowserScreen> createState() => _WebBrowserScreenState();
}

class _WebBrowserScreenState extends State<WebBrowserScreen> {
  late final WebViewController _controller;
  final _urlController = TextEditingController();
  bool _loadedInitial = false;
  bool _isLoading = false;
  double _progress = 0;
  String? _errorMessage;
  bool _canGoBack = false;
  bool _canGoForward = false;
  _CacheMode _cacheMode = _CacheMode.normal;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
              _urlController.text = url;
            });
          },
          onProgress: (progress) => setState(() => _progress = progress / 100),
          onPageFinished: (url) async {
            final back = await _controller.canGoBack();
            final fwd = await _controller.canGoForward();
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _canGoBack = back;
              _canGoForward = fwd;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
              _errorMessage = '${error.description} (${error.errorCode})';
            });
          },
        ),
      );
  }

  void _load(String input) {
    var url = input.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    _controller.loadRequest(Uri.parse(url));
  }

  Future<void> _reload() async {
    setState(() => _cacheMode = _CacheMode.normal);
    await _controller.reload();
  }

  /// The real hard-reload/no-cache action — see class doc.
  Future<void> _hardReload() async {
    setState(() {
      _cacheMode = _CacheMode.bypass;
      _isLoading = true;
    });
    final currentUrl = await _controller.currentUrl();
    // clearCache() clears HTTP cache, cache API, application cache, and
    // local storage, and triggers its own reload — but we still want the
    // cache-busting query param for servers/CDNs that ignore standard
    // cache headers entirely, so load explicitly afterward instead of
    // relying on clearCache()'s implicit reload of the un-modified URL.
    await _controller.clearCache();
    if (currentUrl != null) {
      final uri = Uri.parse(currentUrl);
      final busted = uri.replace(queryParameters: {
        ...uri.queryParameters,
        '_skcachebust': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      await _controller.loadRequest(busted);
    }
  }

  Future<void> _clearCookies() async {
    await WebViewCookieManager().clearCookies();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cookies cleared for this WebView.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final connections = context.watch<ConnectionRepository>();
    final active = connections.activeConnection;

    if (!_loadedInitial && active?.websiteUrl != null) {
      _loadedInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(active!.websiteUrl!));
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
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(onPressed: _canGoBack ? _controller.goBack : null, icon: const Icon(Icons.arrow_back, size: 18)),
                    IconButton(onPressed: _canGoForward ? _controller.goForward : null, icon: const Icon(Icons.arrow_forward, size: 18)),
                    IconButton(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: 'Reload',
                    ),
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
                              _urlController.text.startsWith('https') ? Icons.lock : Icons.lock_open,
                              size: 13,
                              color: _urlController.text.startsWith('https') ? AppColors.secondary : AppColors.tertiary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                controller: _urlController,
                                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Enter URL'),
                                onSubmitted: _load,
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
                          case 'hard':
                            _hardReload();
                          case 'cookies':
                            _clearCookies();
                          case 'share':
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Share sheet not wired up yet.')));
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'hard', child: Text('Hard Reload (No Cache)')),
                        PopupMenuItem(value: 'cookies', child: Text('Clear Cookies')),
                        PopupMenuItem(value: 'share', child: Text('Share')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _cacheMode == _CacheMode.bypass
                            ? AppColors.tertiaryContainer.withOpacity(0.2)
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        _cacheMode == _CacheMode.bypass ? 'CACHE: BYPASS' : 'CACHE: NORMAL',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _cacheMode == _CacheMode.bypass ? AppColors.tertiary : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading) LinearProgressIndicator(value: _progress > 0 ? _progress : null, minHeight: 2),
          Expanded(
            child: _errorMessage != null
                ? _errorView(active?.websiteUrl)
                : (active?.websiteUrl == null && _urlController.text.isEmpty)
                    ? _emptyState()
                    : WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.public, size: 40, color: AppColors.outline),
            const SizedBox(height: 12),
            const Text('No URL loaded', style: TextStyle(fontFamily: 'Geist', fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Enter a URL above, or set a Website URL on this connection profile.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(String? fallbackUrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('Failed to load page', style: TextStyle(fontFamily: 'Geist', fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_errorMessage ?? '', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _reload, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
