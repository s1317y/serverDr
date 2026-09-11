import 'package:flutter/widgets.dart';

/// Color tokens transcribed 1:1 from the Stitch `DESIGN.md` export
/// (`terminal_utility_archetype/DESIGN.md`).
///
/// Two palettes are present in the Stitch package and they don't fully
/// agree with each other:
///  - The YAML frontmatter (Material-3-style token names) — used by the
///    actual `code.html` prototypes via the Tailwind config.
///  - The prose "Colors" section — a GitHub-Dimmed-flavoured palette used
///    to *describe* the system.
///
/// The rendered screens (`screen.png`) and the Tailwind config in the HTML
/// match the YAML frontmatter, so that's the source of truth here. Kept as
/// `AppColors` (from the frontmatter) is primary; the prose palette is
/// reproduced as `AppColorsProse` only for reference/future reconciliation.
abstract final class AppColors {
  // Surfaces
  static const surface = Color(0xFF0B141C);
  static const surfaceDim = Color(0xFF0B141C);
  static const surfaceBright = Color(0xFF313A43);
  static const surfaceContainerLowest = Color(0xFF060F16);
  static const surfaceContainerLow = Color(0xFF141C24);
  static const surfaceContainer = Color(0xFF182028);
  static const surfaceContainerHigh = Color(0xFF222B33);
  static const surfaceContainerHighest = Color(0xFF2D363E);
  static const surfaceVariant = Color(0xFF2D363E);

  // Text
  static const onSurface = Color(0xFFDAE3EE);
  static const onSurfaceVariant = Color(0xFFC0C7D4);
  static const inverseSurface = Color(0xFFDAE3EE);
  static const inverseOnSurface = Color(0xFF29313A);
  static const outline = Color(0xFF8B919D);
  static const outlineVariant = Color(0xFF414752);

  // Primary (blue) — links, active tokens, focus rings
  static const primary = Color(0xFFA2C9FF);
  static const onPrimary = Color(0xFF00315C);
  static const primaryContainer = Color(0xFF58A6FF);
  static const onPrimaryContainer = Color(0xFF003A6B);
  static const primaryFixed = Color(0xFFD3E4FF);
  static const primaryFixedDim = Color(0xFFA2C9FF);
  static const inversePrimary = Color(0xFF0060AA);
  static const surfaceTint = Color(0xFFA2C9FF);

  // Secondary (green) — healthy / success / connected
  static const secondary = Color(0xFF67DF70);
  static const onSecondary = Color(0xFF00390D);
  static const secondaryContainer = Color(0xFF27A640);
  static const onSecondaryContainer = Color(0xFF00320A);
  static const secondaryFixed = Color(0xFF83FC89);
  static const secondaryFixedDim = Color(0xFF67DF70);

  // Tertiary (amber) — warnings, folders, degraded states
  static const tertiary = Color(0xFFFABC45);
  static const onTertiary = Color(0xFF422C00);
  static const tertiaryContainer = Color(0xFFD29922);
  static const onTertiaryContainer = Color(0xFF4D3500);
  static const tertiaryFixed = Color(0xFFFFDEAA);
  static const tertiaryFixedDim = Color(0xFFFABC45);

  // Error (red) — destructive / failed / critical
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);

  // Backdrop scrim for modal sheets ("#010409" at 70%)
  static const scrim = Color(0xB3010409);
}
