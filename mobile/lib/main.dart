import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/main_page.dart';

void main() {
  runApp(const RoastmateApp());
}

class RoastmateApp extends StatelessWidget {
  const RoastmateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roastmate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF5F0EB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5A382C),
          primary: const Color(0xFF5A382C),
          secondary: const Color(0xFF8B5E3C),
          tertiary: const Color(0xFF5E6B4A),
          surface: const Color(0xFFF5F0EB),
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF5F0EB),
          foregroundColor: const Color(0xFF5A382C),
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: const Color(0xFF5A382C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: const MainPage(),
    );
  }
}
