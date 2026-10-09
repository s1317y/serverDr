import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UiScale {
  small,
  medium,
  large;

  String get label => switch (this) {
        UiScale.small => 'Small',
        UiScale.medium => 'Medium',
        UiScale.large => 'Large',
      };

  double get factor => switch (this) {
        UiScale.small => 0.9,
        UiScale.medium => 1.0,
        UiScale.large => 1.15,
      };
}

/// Real, persisted, immediately-applied UI/font preferences — replacing
/// the Phase-1 sliders that didn't actually do anything. Terminal and
/// editor font sizes are read directly by `TerminalScreen`/`EditorScreen`
/// (each independent of general UI scale, per the brief: "Terminal and
/// code editor should use the terminal/code font independently from
/// normal UI text").
class UiPreferencesController extends ChangeNotifier {
  UiPreferencesController(this._prefs) {
    _uiScale = UiScale.values.firstWhere(
      (s) => s.name == _prefs.getString(_uiScaleKey),
      orElse: () => UiScale.medium,
    );
    _terminalFontSize = _prefs.getDouble(_terminalFontKey) ?? 13.0;
    _editorFontSize = _prefs.getDouble(_editorFontKey) ?? 12.0;
  }

  // Kept as 'serverkit.*' deliberately — see connection_repository.dart's
  // note on why storage keys aren't part of this rename.
  static const _uiScaleKey = 'serverkit.settings.uiScale';
  static const _terminalFontKey = 'serverkit.settings.terminalFontSize';
  static const _editorFontKey = 'serverkit.settings.editorFontSize';

  final SharedPreferences _prefs;
  late UiScale _uiScale;
  late double _terminalFontSize;
  late double _editorFontSize;

  UiScale get uiScale => _uiScale;
  double get terminalFontSize => _terminalFontSize;
  double get editorFontSize => _editorFontSize;

  Future<void> setUiScale(UiScale scale) async {
    _uiScale = scale;
    await _prefs.setString(_uiScaleKey, scale.name);
    notifyListeners();
  }

  Future<void> setTerminalFontSize(double size) async {
    _terminalFontSize = size;
    await _prefs.setDouble(_terminalFontKey, size);
    notifyListeners();
  }

  Future<void> setEditorFontSize(double size) async {
    _editorFontSize = size;
    await _prefs.setDouble(_editorFontKey, size);
    notifyListeners();
  }
}
