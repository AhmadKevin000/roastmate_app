import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/network/supabase_service.dart';

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

  runApp(
    ProviderScope(
      overrides: [supabaseServiceProvider.overrideWithValue(supabase)],
      child: const RoastmateApp(),
    ),
  );
}
