import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env tidak ada (mis. mesin tanpa file): upload Cloudinary nonaktif
    // (no-op) — DB & alur aplikasi tetap jalan (offline-first, AC-02).
    debugPrint('[dotenv] .env gagal dimuat: $e — upload Cloudinary dinonaktifkan.');
  }
  runApp(const ProviderScope(child: RoastmateApp()));
}
