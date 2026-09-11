import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// UI text family — Geist, per `DESIGN.md`. Falls back to the platform
/// default automatically if `assets/fonts/Geist-*.ttf` haven't been added.
const String kUiFontFamily = 'Geist';

/// Technical/code family — JetBrains Mono, per `DESIGN.md`. Used for
/// terminal output, IPs, ports, hashes, timestamps, file metadata.
const String kCodeFontFamily = 'JetBrains Mono';

/// Text style scale transcribed from `DESIGN.md` → "typography".
///
/// Naming mirrors the Stitch tokens (`headline-lg`, `body-md`, `code-sm`,
/// `label-sm`, ...) so a style in the prototype maps 1:1 to a style here.
abstract final class AppTypography {
  static const headlineLg = TextStyle(
    fontFamily: kUiFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    letterSpacing: -0.02 * 24,
    color: AppColors.onSurface,
  );

  static const headlineMd = TextStyle(
    fontFamily: kUiFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    letterSpacing: -0.015 * 20,
    color: AppColors.onSurface,
  );

  static const headlineSm = TextStyle(
    fontFamily: kUiFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    letterSpacing: -0.01 * 16,
    color: AppColors.onSurface,
  );

  static const bodyLg = TextStyle(
    fontFamily: kUiFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
    color: AppColors.onSurface,
  );

  static const bodyMd = TextStyle(
    fontFamily: kUiFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    color: AppColors.onSurface,
  );

  static const bodySm = TextStyle(
    fontFamily: kUiFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: AppColors.onSurfaceVariant,
  );

  static const codeLg = TextStyle(
    fontFamily: kCodeFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 18 / 13,
    letterSpacing: -0.01 * 13,
    color: AppColors.onSurface,
  );

  static const codeMd = TextStyle(
    fontFamily: kCodeFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: AppColors.onSurface,
  );

  static const codeSm = TextStyle(
    fontFamily: kCodeFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 14 / 11,
    color: AppColors.onSurfaceVariant,
  );

  static const labelMd = TextStyle(
    fontFamily: kUiFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.01 * 12,
    color: AppColors.onSurface,
  );

  static const labelSm = TextStyle(
    fontFamily: kCodeFontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 12 / 10,
    letterSpacing: 0.05 * 10,
    color: AppColors.onSurfaceVariant,
  );
}
