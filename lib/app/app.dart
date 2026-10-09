import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_controller.dart';
import '../features/settings/services/ui_preferences_controller.dart';

class ServerDrApp extends StatelessWidget {
  const ServerDrApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeModeController>();
    final uiScale = context.watch<UiPreferencesController>().uiScale;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Status-bar icon contrast now genuinely follows the resolved
      // brightness (dark theme → light icons, light theme → dark icons),
      // not a single hardcoded style — see ThemeModeController.
      value: _statusBarStyleFor(themeController.mode, MediaQuery.platformBrightnessOf(context)),
      child: MaterialApp.router(
        title: 'ServerDr',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeController.mode,
        routerConfig: appRouter,
        builder: (context, child) {
          // Real, app-wide UI scale (Settings > Appearance > UI Scale) —
          // applied as a text scale factor over whatever the platform's
          // own accessibility text-scale setting already is, rather than
          // replacing it.
          final mediaQuery = MediaQuery.of(context);
          final combined = mediaQuery.textScaler.scale(1.0) * uiScale.factor;
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: TextScaler.linear(combined)),
            child: child!,
          );
        },
      ),
    );
  }

  SystemUiOverlayStyle _statusBarStyleFor(ThemeMode mode, Brightness platformBrightness) {
    final isDark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light, // iOS
      systemNavigationBarColor: isDark ? const Color(0xFF0B141C) : const Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );
  }
}
