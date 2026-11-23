// Uji navigasi Profil (bugfix): layar Profil di luar ShellRoute, jadi harus
// selalu punya jalan keluar. Back → pop bila ada stack, fallback ke Beranda.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pbl_sem5/core/auth/auth_controller.dart';
import 'package:pbl_sem5/features/auth/presentation/views/profile_screen.dart';

class _LoggedInAuthController extends AuthController {
  @override
  AuthState build() =>
      const AuthState(userId: 'user-1', email: 'user@example.com');
}

Widget _wrap() => ProviderScope(
  overrides: [authControllerProvider.overrideWith(_LoggedInAuthController.new)],
  child: MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, _) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
      ],
    ),
  ),
);

void main() {
  testWidgets('Profil tanpa stack → tombol kembali tampil dan ke Beranda', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Kembali'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
  });
}
