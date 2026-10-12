import 'package:go_router/go_router.dart';

import '../../features/analysis/presentation/views/analysis_history_screen.dart';
import '../../features/brew/presentation/views/brew_catalog_screen.dart';
import '../../features/brew/presentation/views/recipe_detail_screen.dart';
import '../../features/home/presentation/views/home_view.dart';
import '../../features/result/presentation/views/result_view.dart';
import '../../features/scan/presentation/views/scan_setup_view.dart';
import '../../features/scan/presentation/views/scan_view.dart';
import '../../shared/models/analysis_result.dart';
import '../main_shell.dart';

/// Router aplikasi (GoRouter).
///
/// Route mengikuti `docs/ARCHITECTURE_MOBILE.md` §6:
/// `/home` · `/scan` · `/result/:analysisId` · `/history` ·
/// `/history/:analysisId` · `/brewing` · `/brewing/:methodId`.
///
/// Tambahan `/scan/setup` — form nama jenis biji sebelum membuka kamera.
///
/// Tiga tab (`/home`, `/history`, `/brewing`) dibungkus [MainShell] (bottom nav).
/// Scan & detail di-push sebagai layar penuh.
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: <RouteBase>[
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) =>
              const AnalysisHistoryScreen(showBottomNav: false),
        ),
        GoRoute(
          path: '/brewing',
          builder: (context, state) => const BrewCatalogScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/scan/setup',
      builder: (context, state) => const ScanSetupView(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const CameraScreen(),
    ),
    GoRoute(
      path: '/result/:analysisId',
      builder: (context, state) => InspectionDetailScreen(
        result: state.extra as InspectionResult?,
      ),
    ),
    GoRoute(
      path: '/history/:analysisId',
      builder: (context, state) => InspectionDetailScreen(
        result: state.extra as InspectionResult?,
      ),
    ),
    GoRoute(
      path: '/brewing/:methodId',
      builder: (context, state) => RecipeDetailScreen(
        methodId: state.pathParameters['methodId']!,
      ),
    ),
  ],
);
