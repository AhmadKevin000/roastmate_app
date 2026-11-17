import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_controller.dart';
import '../core/theme/roastmate_theme.dart';
import 'router/app_router.dart';

/// Root widget aplikasi Roastmate.
///
/// Menyediakan [MaterialApp] + tema; navigasi ditangani [appRouter] (GoRouter).
///
/// **Auth gate (D-30):** widget ini mendengarkan `authControllerProvider` dan
/// memompa state ke [AuthGateListenable] — redirect router membaca state itu
/// untuk memaksa login di first-run/logout.
class RoastmateApp extends ConsumerStatefulWidget {
  const RoastmateApp({super.key});

  @override
  ConsumerState<RoastmateApp> createState() => _RoastmateAppState();
}

class _RoastmateAppState extends ConsumerState<RoastmateApp> {
  @override
  void initState() {
    super.initState();
    // Pompa state auth awal sebelum frame pertama — mencegah flash Beranda
    // sesaat sebelum gate mengarahkan ke /login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthGateListenable.instance.update(ref.read(authControllerProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan sesi (login/logout/restore) → refresh router.
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      AuthGateListenable.instance.update(next);
    });

    return MaterialApp.router(
      title: 'Roastmate',
      theme: roastmateTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
