// Uji widget LoginScreen (FR-10): validasi form & navigasi ke daftar.
//
// AuthController di-fake — jaringan Supabase tidak diuji di sini.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pbl_sem5/core/auth/auth_controller.dart';
import 'package:pbl_sem5/features/auth/presentation/views/login_screen.dart';

class FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState();

  @override
  Future<void> signIn(String email, String password) async {
    // Simulasi kredensial salah untuk menguji pesan error.
    throw StateError('invalid_credentials');
  }
}

Widget _wrap() => ProviderScope(
  overrides: [authControllerProvider.overrideWith(FakeAuthController.new)],
  child: MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(
          path: '/register',
          builder: (_, __) => const Scaffold(body: Text('REGISTER')),
        ),
      ],
    ),
  ),
);

void main() {
  testWidgets('submit kosong → validasi email & sandi tampil', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
  });

  testWidgets('email tanpa @ → pesan tidak valid', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextFormField).at(0), 'bukan-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'rahasia123');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Email tidak valid'), findsOneWidget);
  });

  testWidgets('kredensial ditolak → pesan error tampil', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'rahasia123');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // Pesan generik lama menyembunyikan penyebab; sekarang penyebabnya tampil.
    expect(find.textContaining('Login gagal'), findsOneWidget);
    expect(find.textContaining('invalid_credentials'), findsOneWidget);
  });

  testWidgets('tautan daftar → layar register', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('REGISTER'), findsOneWidget);
  });
}
