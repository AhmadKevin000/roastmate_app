import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app/app.dart';
import 'core/auth/auth_controller.dart';
import 'core/network/supabase_service.dart';
import 'app/router/app_router.dart';
import 'features/onboarding/data/repositories/onboarding_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi databaseFactory untuk platform Web dan Desktop
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Supabase (D-29): no-op bila kredensial dart-define tidak lengkap.
  final supabase = await SupabaseService.ensureInitialized();

  // Auth gate (D-30): set state awal SEKARANG (sinkron dari session tersimpan)
  // agar first navigation sudah tahu sesi — tidak ada flash layar login.
  final client = supabase.client;
  if (client != null) {
    final session = client.auth.currentSession;
    AuthGateListenable.instance.update(
      AuthState(userId: session?.user.id, email: session?.user.email),
    );
  } else {
    // Supabase tidak terkonfigurasi → tanpa gate (fallback offline penuh).
    AuthGateListenable.instance.update(const AuthState(unavailable: true));
  }

  // Onboarding status: muat dari SQLite lokal (meta)
  final onboardingRepo = OnboardingRepositoryImpl();
  final onboardingCompleted = await onboardingRepo.isOnboardingCompleted();
  AuthGateListenable.instance.updateOnboarding(onboardingCompleted);

  runApp(
    ProviderScope(
      overrides: [supabaseServiceProvider.overrideWithValue(supabase)],
      child: const RoastmateApp(),
    ),
  );
}
