import 'package:flutter/material.dart';

import '../core/theme/roastmate_theme.dart';
import 'router/app_router.dart';

/// Root widget aplikasi Roastmate.
///
/// Menyediakan [MaterialApp] + tema; navigasi ditangani [appRouter] (GoRouter).
class RoastmateApp extends StatelessWidget {
  const RoastmateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Roastmate',
      theme: roastmateTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
