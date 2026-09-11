import 'package:flutter/foundation.dart';

/// Abstraction over "browsing a site" so the Web tab's UI never depends
/// directly on a WebView plugin.
///
/// PHASE 1 SCOPE: no real WebView is wired up yet — Android's real
/// implementation (Phase 8) will wrap `webview_flutter` or similar,
/// evaluated then. This stub only tracks navigation *state* (current URL,
/// can-go-back/forward, loading) so the Web screen's UI/UX is fully
/// buildable and testable before that dependency is added.
///
/// Also per the brief: a fresh/hard reload must be a distinct action from
/// a normal reload once a real WebView lands, because Flutter/Android
/// WebViews cannot fully bypass HTTP caching from a simple reload alone —
/// this interface reserves [hardReload] for that so the distinction isn't
/// lost when real navigation is implemented.
abstract interface class WebViewService extends ChangeNotifier {
  String get currentUrl;
  bool get isLoading;
  bool get canGoBack;
  bool get canGoForward;
  bool get desktopMode;

  void load(String url);
  void goBack();
  void goForward();
  void reload();

  /// Best-effort cache-bypassing reload. See class doc — this cannot be a
  /// guaranteed full bypass on every platform/version.
  void hardReload();

  void setDesktopMode(bool desktop);
}

/// Stub implementation: simulates loading state transitions and keeps a
/// simple back/forward stack, but renders no actual web content — that's
/// Phase 8's job for Android, and out of scope entirely for Flutter Web
/// per the brief (browsers already provide the browsing UI there).
class StubWebViewService extends ChangeNotifier implements WebViewService {
  final List<String> _stack = [];
  int _index = -1;
  bool _isLoading = false;
  bool _desktopMode = false;

  @override
  String get currentUrl => _index >= 0 ? _stack[_index] : '';
  @override
  bool get isLoading => _isLoading;
  @override
  bool get canGoBack => _index > 0;
  @override
  bool get canGoForward => _index < _stack.length - 1;
  @override
  bool get desktopMode => _desktopMode;

  @override
  void load(String url) {
    final normalized = url.startsWith('http') ? url : 'https://$url';
    _stack.removeRange(_index + 1, _stack.length);
    _stack.add(normalized);
    _index = _stack.length - 1;
    _simulateLoad();
  }

  @override
  void goBack() {
    if (!canGoBack) return;
    _index--;
    _simulateLoad();
  }

  @override
  void goForward() {
    if (!canGoForward) return;
    _index++;
    _simulateLoad();
  }

  @override
  void reload() => _simulateLoad();

  @override
  void hardReload() => _simulateLoad();

  @override
  void setDesktopMode(bool desktop) {
    _desktopMode = desktop;
    notifyListeners();
  }

  void _simulateLoad() {
    _isLoading = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 500), () {
      _isLoading = false;
      notifyListeners();
    });
  }
}
