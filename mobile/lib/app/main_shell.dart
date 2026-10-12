import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shell navigasi bawah (3 tab) untuk route di dalam `ShellRoute`.
///
/// Tampilan bottom bar dipertahankan sama seperti sebelumnya; yang berubah
/// hanya sumber pemilihan tab (dari lokasi GoRouter, bukan state lokal).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  /// Konten route aktif dari [ShellRoute].
  final Widget child;

  static const List<String> _tabLocations = <String>[
    '/home',
    '/history',
    '/brewing',
  ];

  int _indexFor(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/brewing')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _indexFor(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0EB),
          border: const Border(
            top: BorderSide(color: Color(0xFFE8E0D8), width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A382C).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Analisis',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.coffee_outlined),
              activeIcon: Icon(Icons.coffee),
              label: 'Seduh',
            ),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: const Color(0xFF5A382C),
          unselectedItemColor: const Color(0xFF796E66),
          onTap: (index) => context.go(_tabLocations[index]),
          backgroundColor: const Color(0xFFF5F0EB),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
