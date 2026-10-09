import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's Dark/Light/System theme choice and exposes it as
/// a real, working [ThemeMode] for `MaterialApp.router`. See
/// `AppColorsLight`'s doc for the current scope/limits of what actually
/// repaints in light mode.
class ThemeModeController extends ChangeNotifier {
  ThemeModeController(this._prefs) {
    final saved = _prefs.getString(_key);
    _mode = ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.dark);
  }

  // Kept as 'serverkit.*' deliberately — see connection_repository.dart's
  // identical note. Not user-facing; renaming risks silently resetting
  // existing users' saved theme choice for no visible benefit.
  static const _key = 'serverkit.settings.themeMode';
  final SharedPreferences _prefs;
  late ThemeMode _mode;

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    await _prefs.setString(_key, mode.name);
    notifyListeners();
  }
}
