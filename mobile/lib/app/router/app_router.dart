import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/auth/presentation/views/profile_screen.dart';
import '../../features/auth/presentation/views/register_screen.dart';
import '../../features/analysis/presentation/views/analysis_history_screen.dart';
import '../../features/brew/presentation/views/brew_catalog_screen.dart';
import '../../features/brew/presentation/views/recipe_detail_screen.dart';
import '../../features/brew/presentation/views/user_recipe_detail_screen.dart';
import '../../features/brew/presentation/views/user_recipe_form_screen.dart';
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
/// `/history/:analysisId` · `/brewing` · `/brewing/new` ·
/// `/brewing/user/:recipeId` · `/brewing/:methodId`.
///
/// Tambahan `/scan/setup` — form nama jenis biji sebelum membuka kamera.
///
/// Tiga tab (`/home`, `/history`, `/brewing`) dibungkus [MainShell] (bottom nav).
/// Scan & detail di-push sebagai layar penuh.
///
/// **Auth gate (D-30):** tanpa sesi login, semua route fitur dialihkan ke
/// `/login`; `/login` & `/register` hanya bisa diakses tanpa sesi. Sesi Supabase
/// dipersistensi SDK, jadi gate hanya aktif saat first-run/logout.
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  refreshListenable: AuthGateListenable.instance,
  redirect: (context, state) {
    final auth = AuthGateListenable.instance.authState;
    final loggedIn = auth?.loggedIn ?? false;
    final unavailable = auth?.unavailable ?? false;
    final goingToAuth =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    // Supabase tidak dikonfigurasi (.env kosong) → tanpa gate, app jalan
    // offline penuh (fallback defensif; di production tidak terjadi).
    if (unavailable) return goingToAuth ? '/home' : null;

    if (!loggedIn && !goingToAuth) return '/login';
    if (loggedIn && goingToAuth) return '/home';
    return null;
  },
  routes: <RouteBase>[
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: <RouteBase>[
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/history',
          builder: (context, state) => const AnalysisHistoryScreen(),
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
    GoRoute(path: '/scan', builder: (context, state) => const CameraScreen()),
    GoRoute(
      path: '/result/:analysisId',
      builder: (context, state) => InspectionDetailScreen(
        // Int → id baris `analyses` (baca DB). Non-int (`draft`, `scan-*`)
        // → analysisId null → fallback `state.extra` (alur scan, Plan 3).
        analysisId: int.tryParse(state.pathParameters['analysisId'] ?? ''),
        fallback: state.extra as InspectionResult?,
      ),
    ),
    GoRoute(
      path: '/history/:analysisId',
      builder: (context, state) => InspectionDetailScreen(
        analysisId: int.tryParse(state.pathParameters['analysisId'] ?? ''),
        fallback: state.extra as InspectionResult?,
      ),
    ),
    GoRoute(
      path: '/brewing/new',
      builder: (context, state) => const UserRecipeFormScreen(),
    ),
    GoRoute(
      // Detail resep user — harus sebelum `/brewing/:methodId`.
      path: '/brewing/user/:recipeId',
      builder: (context, state) =>
          UserRecipeDetailScreen(recipeId: state.pathParameters['recipeId']!),
    ),
    GoRoute(
      path: '/brewing/:methodId',
      builder: (context, state) =>
          RecipeDetailScreen(methodId: state.pathParameters['methodId']!),
    ),
    // Auth (D-29): layar penuh, bukan tab.
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

/// Jembatan Riverpod ↔ GoRouter untuk auth gate (D-30).
///
/// [RoastmateApp] (ConsumerWidget) memanggil [update] tiap
/// `authControllerProvider` berubah; router membaca [authState] di redirect
/// dan mendengarkan notify agar re-navigate saat login/logout.
class AuthGateListenable extends ChangeNotifier {
  AuthGateListenable._();
  static final AuthGateListenable instance = AuthGateListenable._();

  AuthState? _authState;
  AuthState? get authState => _authState;

  void update(AuthState state) {
    if (_authState == state) return;
    _authState = state;
    notifyListeners();
  }
}
