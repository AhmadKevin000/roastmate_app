import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Klien Supabase untuk auth & sync (D-29).
///
/// Konfigurasi dari `.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). Bila `.env`
/// tidak ada atau kredensial kosong, layanan bersifat no-op ([available] =
/// false) — alur inti aplikasi tetap berjalan offline-first.
class SupabaseService {
  SupabaseService._({this.client});

  final SupabaseClient? client;

  /// True bila Supabase ter-inisialisasi dengan kredensial lengkap.
  bool get available => client != null;

  /// Inisialisasi Supabase dari `.env`. Aman dipanggil meski kredensial
  /// tidak lengkap — mengembalikan instance no-op.
  static Future<SupabaseService> ensureInitialized() async {
    final url = _envOrNull('SUPABASE_URL');
    final key = _envOrNull('SUPABASE_ANON_KEY');
    if (url == null || key == null) {
      debugPrint('[Supabase] kredensial tidak lengkap — auth/sync nonaktif.');
      return SupabaseService._();
    }
    try {
      await Supabase.initialize(url: url, publishableKey: key);
      return SupabaseService._(client: Supabase.instance.client);
    } catch (e) {
      debugPrint('[Supabase] inisialisasi gagal: $e — auth/sync nonaktif.');
      return SupabaseService._();
    }
  }

  static String? _envOrNull(String key) {
    try {
      final v = dotenv.env[key];
      if (v == null || v.isEmpty || v.startsWith('your_')) return null;
      return v;
    } catch (_) {
      // dotenv tidak di-load (file .env tidak ada).
      return null;
    }
  }
}

/// Instance layanan untuk injeksi dependensi (Riverpod).
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  throw UnimplementedError(
    'SupabaseService di-override di main.dart setelah ensureInitialized().',
  );
});
