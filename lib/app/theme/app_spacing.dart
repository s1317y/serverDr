/// 4px-baseline spacing tokens, from `DESIGN.md`.
abstract final class AppSpacing {
  static const xs2 = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xl2 = 24.0;
  static const xl3 = 32.0;

  /// Fixed screen edge gutter (`gutter-screen`).
  static const gutterScreen = 12.0;

  /// Tighter gutter used inside terminal viewports (`gutter-terminal`).
  static const gutterTerminal = 8.0;
}

/// Corner radii, from `DESIGN.md` → "Shapes".
abstract final class AppRadius {
  /// Metric bars, status dots, inline code tags.
  static const micro = 2.0;

  /// Standard buttons, inputs, terminal keys, protocol badges.
  static const small = 4.0;

  /// Server list cards, telemetry blocks, bottom sheets.
  static const base = 6.0;

  /// Larger sheet corners (bottom-sheet top radius in the prototypes).
  static const large = 8.0;

  /// Status dots / pill badges.
  static const full = 9999.0;
}
