import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/roastmate_colors.dart';
import '../core/widgets/roastmate_bottom_nav.dart';

/// Shell navigasi bawah (3 tab) untuk route di dalam `ShellRoute`.
///
/// Bottom bar memakai komponen bersama [RoastmateBottomNav] (core) agar
/// konsisten dengan tema; pemilihan tab mengikuti lokasi GoRouter.
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
      backgroundColor: RoastmateColors.background,
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: RoastmateColors.borderDefault, width: 1.0),
          ),
        ),
        child: RoastmateBottomNav(
          currentIndex: selectedIndex,
          onTap: (index) => context.go(_tabLocations[index]),
        ),
      ),
    );
  }
}
