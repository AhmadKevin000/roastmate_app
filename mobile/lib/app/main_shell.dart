import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/roastmate_colors.dart';
import '../core/widgets/roastmate_bottom_nav.dart';
import '../features/home/presentation/viewmodels/home_view_model.dart';

/// Shell navigasi bawah (3 tab) untuk route di dalam `ShellRoute`.
///
/// Bottom bar memakai komponen bersama [RoastmateBottomNav] (core) agar
/// konsisten dengan tema; pemilihan tab mengikuti lokasi GoRouter.
class MainShell extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _indexFor(context);
    final isBrewCatalog = GoRouterState.of(context).uri.path == '/brewing';

    return Scaffold(
      backgroundColor: RoastmateColors.background,
      body: child,
      // FAB tambah resep — hanya katalog Seduh (di atas bottom nav).
      floatingActionButton: isBrewCatalog
          ? FloatingActionButton(
              tooltip: 'Tambah resep',
              onPressed: () => context.push('/brewing/new'),
              backgroundColor: RoastmateColors.primary,
              foregroundColor: RoastmateColors.surface,
              elevation: 2,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: RoastmateColors.borderDefault, width: 1.0),
          ),
        ),
        child: RoastmateBottomNav(
          currentIndex: selectedIndex,
          onTap: (index) {
            // Beranda selalu membaca ulang ringkasan (skor & bintang
            // penilaian pribadi bisa berubah dari tab lain).
            if (index == 0) ref.invalidate(homeViewModelProvider);
            context.go(_tabLocations[index]);
          },
        ),
      ),
    );
  }
}
