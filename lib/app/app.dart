import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class ServerKitApp extends StatelessWidget {
  const ServerKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Global status-bar / nav-bar icon contrast. Dark-first design today —
    // `SystemUiOverlayStyle.light` means LIGHT icons (for a dark background).
    // Wrapped in AnnotatedRegion (not a one-shot SystemChrome call) so this
    // correctly reasserts itself as the user navigates between screens/routes,
    // and so a future light theme can swap this per-theme instead of
    // per-screen.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // iOS
        systemNavigationBarColor: Color(0xFF0B141C), // AppColors.surface
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MaterialApp.router(
        title: 'ServerKit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: appRouter,
      ),
    );
  }
}
