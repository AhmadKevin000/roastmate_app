import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/auth/auth_controller.dart';
import 'core/network/supabase_service.dart';
import 'app/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env tidak ada (mis. mesin tanpa file): upload Cloudinary & auth/sync
    // nonaktif (no-op) — DB & alur aplikasi tetap jalan (offline-first).
    debugPrint('[dotenv] .env gagal dimuat: $e — layanan cloud dinonaktifkan.');
  }

  // Supabase (D-29): no-op bila kredensial tidak lengkap.
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

  runApp(
    ProviderScope(
      overrides: [supabaseServiceProvider.overrideWithValue(supabase)],
      child: const RoastmateApp(),
    ),
  );
}
