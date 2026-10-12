import 'package:flutter/material.dart';

import '../core/theme/roastmate_theme.dart';
import 'main_page.dart';

/// Root widget aplikasi Roastmate.
///
/// Menyediakan [MaterialApp] + tema; shell navigasi ada di [MainPage].
class RoastmateApp extends StatelessWidget {
  const RoastmateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roastmate',
      theme: roastmateTheme,
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );
  }
}
