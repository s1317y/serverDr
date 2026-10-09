import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles the Stitch design tokens into [ThemeData] for both
/// brightnesses. See [AppColorsLight]'s doc for the real scope of what
/// `light` currently affects (standard Material component chrome) versus
/// what it doesn't yet (custom-styled surfaces hardcoded to [AppColors]).
/// `Settings > Appearance > Theme` (Dark/Light/System) is wired to these
/// via `ThemeModeController`.
abstract final class AppTheme {
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      surfaceTint: AppColors.surfaceTint,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      scrim: AppColors.scrim,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      canvasColor: AppColors.surface,
      fontFamily: kUiFontFamily,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: AppColors.outlineVariant,
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineMedium: AppTypography.headlineLg,
        headlineSmall: AppTypography.headlineMd,
        titleMedium: AppTypography.headlineSm,
        bodyLarge: AppTypography.bodyLg,
        bodyMedium: AppTypography.bodyMd,
        bodySmall: AppTypography.bodySm,
        labelMedium: AppTypography.labelMd,
        labelSmall: AppTypography.labelSm,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainer,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      // AppShell uses the Material 3 `NavigationBar` widget (not the
      // legacy `BottomNavigationBar` above) — it reads THIS theme, not
      // bottomNavigationBarTheme. Both are configured since some other
      // part of the app could still reference the legacy widget.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainer,
        indicatorColor: AppColors.primary.withOpacity(0.16),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        hintStyle: AppTypography.codeMd.copyWith(color: AppColors.outline),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          minimumSize: const Size(0, 36),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.outlineVariant),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryContainer;
          }
          return AppColors.surfaceContainerHigh;
        }),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
      ),
    );
  }

  /// Public light theme accessor.
  ///
  /// TEMPORARILY returns [dark] rather than the fully-built light palette
  /// below. The real light `ColorScheme`/component themes ARE built (see
  /// `_builtLightTheme`) and DO correctly repaint standard Material
  /// chrome (AppBar, Card, Dialog, NavigationBar, inputs) — but the large
  /// majority of ServerDr's custom-styled surfaces (file rows, terminal
  /// chrome, section cards, status strips, ...) reference the dark
  /// [AppColors] palette as hardcoded `static const` values directly,
  /// bypassing the theme entirely. Shipping the real light theme as-is
  /// produced exactly the reported bug: Scaffold/AppBar/NavigationBar
  /// genuinely turn white, but all the custom text/container colors stay
  /// dark-palette, so text and elements become unreadable or look
  /// "inverted." Converting every such call site to read from
  /// `Theme.of(context)` instead is a large, dedicated pass across ~90
  /// files — not a targeted fix — so until that's done, Light and System
  /// intentionally render identically to Dark. The Dark/Light/System
  /// setting itself still works and persists; it just doesn't visually
  /// differ yet. Switch this back to `_builtLightTheme` once that pass
  /// is complete.
  static ThemeData get light => dark;

  static ThemeData get _builtLightTheme {
    const colorScheme = ColorScheme.light(
      surface: AppColorsLight.surface,
      onSurface: AppColorsLight.onSurface,
      onSurfaceVariant: AppColorsLight.onSurfaceVariant,
      primary: AppColorsLight.primary,
      onPrimary: AppColorsLight.onPrimary,
      primaryContainer: AppColorsLight.primaryContainer,
      onPrimaryContainer: AppColorsLight.onPrimaryContainer,
      secondary: AppColorsLight.secondary,
      onSecondary: AppColorsLight.onSecondary,
      secondaryContainer: AppColorsLight.secondaryContainer,
      onSecondaryContainer: AppColorsLight.onSecondaryContainer,
      tertiary: AppColorsLight.tertiary,
      onTertiary: AppColorsLight.onTertiary,
      tertiaryContainer: AppColorsLight.tertiaryContainer,
      onTertiaryContainer: AppColorsLight.onTertiaryContainer,
      error: AppColorsLight.error,
      onError: AppColorsLight.onError,
      errorContainer: AppColorsLight.errorContainer,
      onErrorContainer: AppColorsLight.onErrorContainer,
      outline: AppColorsLight.outline,
      outlineVariant: AppColorsLight.outlineVariant,
      scrim: AppColorsLight.scrim,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColorsLight.surface,
      canvasColor: AppColorsLight.surface,
      fontFamily: kUiFontFamily,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: AppColorsLight.outlineVariant,
      dividerTheme: const DividerThemeData(
        color: AppColorsLight.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      textTheme: TextTheme(
        headlineMedium: AppTypography.headlineLg.copyWith(color: AppColorsLight.onSurface),
        headlineSmall: AppTypography.headlineMd.copyWith(color: AppColorsLight.onSurface),
        titleMedium: AppTypography.headlineSm.copyWith(color: AppColorsLight.onSurface),
        bodyLarge: AppTypography.bodyLg.copyWith(color: AppColorsLight.onSurface),
        bodyMedium: AppTypography.bodyMd.copyWith(color: AppColorsLight.onSurface),
        bodySmall: AppTypography.bodySm.copyWith(color: AppColorsLight.onSurfaceVariant),
        labelMedium: AppTypography.labelMd.copyWith(color: AppColorsLight.onSurface),
        labelSmall: AppTypography.labelSm.copyWith(color: AppColorsLight.onSurfaceVariant),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsLight.surfaceContainer,
        foregroundColor: AppColorsLight.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColorsLight.surfaceContainer,
        indicatorColor: AppColorsLight.primary.withOpacity(0.16),
      ),
      cardTheme: CardThemeData(
        color: AppColorsLight.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          side: const BorderSide(color: AppColorsLight.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsLight.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColorsLight.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLight.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: const BorderSide(color: AppColorsLight.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: const BorderSide(color: AppColorsLight.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: const BorderSide(color: AppColorsLight.primary),
        ),
        hintStyle: AppTypography.codeMd.copyWith(color: AppColorsLight.outline),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLight.primaryContainer,
          foregroundColor: AppColorsLight.onPrimaryContainer,
          minimumSize: const Size(0, 36),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsLight.onSurface,
          side: const BorderSide(color: AppColorsLight.outlineVariant),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsLight.primary,
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColorsLight.secondaryContainer;
          return AppColorsLight.surfaceContainerHigh;
        }),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
      ),
    );
  }
}
