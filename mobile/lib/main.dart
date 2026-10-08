import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/main_page.dart';
import 'core/roastmate_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RoastmateApp()));
}

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
