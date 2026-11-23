import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';

/// Klien Supabase untuk auth & sync (D-29).
///
/// Kredensial dibaca dari [AppEnv] (dart-define saat build). Bila kosong,
/// layanan bersifat no-op ([available] = false) — alur inti aplikasi tetap
/// berjalan offline-first.
class SupabaseService {
  SupabaseService._({this.client});

  final SupabaseClient? client;

  /// True bila Supabase ter-inisialisasi dengan kredensial lengkap.
  bool get available => client != null;

  /// Inisialisasi Supabase dari dart-define. Aman dipanggil meski kredensial
  /// tidak lengkap — mengembalikan instance no-op.
  static Future<SupabaseService> ensureInitialized() async {
    if (!AppEnv.hasSupabase) {
      debugPrint('[Supabase] kredensial tidak lengkap — auth/sync nonaktif.');
      return SupabaseService._();
    }
    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        publishableKey: AppEnv.supabaseAnonKey,
      );
      return SupabaseService._(client: Supabase.instance.client);
    } catch (e) {
      debugPrint('[Supabase] inisialisasi gagal: $e — auth/sync nonaktif.');
      return SupabaseService._();
    }
  }
}

/// Instance layanan untuk injeksi dependensi (Riverpod).
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  throw UnimplementedError(
    'SupabaseService di-override di main.dart setelah ensureInitialized().',
  );
});
