import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists favorited command-shortcut ids and a small "recently run"
/// list, using `shared_preferences` — this is user preference data, not
/// a secret, same rationale as saved connection profiles.
///
/// SENSITIVE-CONTENT GUARD: [recordRecent] refuses to store any command
/// text that looks like it carries a secret (password/token/key flags or
/// keywords) — best-effort, not a guarantee, but a real filter rather
/// than blind logging of whatever the user typed or ran.
class CommandLibraryStore {
  CommandLibraryStore(this._prefs);

  final SharedPreferences _prefs;

  // Kept as 'serverkit.*' deliberately — see connection_repository.dart's
  // note on why storage keys aren't part of this rename.
  static const _favoritesKey = 'serverkit.commands.favorites';
  static const _recentKey = 'serverkit.commands.recent';
  static const _maxRecent = 20;

  static final RegExp _sensitivePattern = RegExp(
    r'(password|passwd|passphrase|secret|token|apikey|api_key|-p\s|authorization:|bearer\s)',
    caseSensitive: false,
  );

  Set<String> get favoriteIds => _prefs.getStringList(_favoritesKey)?.toSet() ?? <String>{};

  Future<void> toggleFavorite(String commandId) async {
    final current = favoriteIds;
    if (current.contains(commandId)) {
      current.remove(commandId);
    } else {
      current.add(commandId);
    }
    await _prefs.setStringList(_favoritesKey, current.toList());
  }

  List<String> get recentCommands {
    final raw = _prefs.getStringList(_recentKey) ?? const [];
    return raw.map((s) {
      try {
        return (jsonDecode(s) as Map<String, dynamic>)['command'] as String;
      } catch (_) {
        return '';
      }
    }).where((s) => s.isNotEmpty).toList();
  }

  Future<void> recordRecent(String resolvedCommand) async {
    if (_sensitivePattern.hasMatch(resolvedCommand)) return; // never persisted
    final raw = _prefs.getStringList(_recentKey) ?? <String>[];
    raw.removeWhere((s) {
      try {
        return (jsonDecode(s) as Map<String, dynamic>)['command'] == resolvedCommand;
      } catch (_) {
        return false;
      }
    });
    raw.insert(0, jsonEncode({'command': resolvedCommand, 'ts': DateTime.now().toIso8601String()}));
    if (raw.length > _maxRecent) raw.removeRange(_maxRecent, raw.length);
    await _prefs.setStringList(_recentKey, raw);
  }
}
