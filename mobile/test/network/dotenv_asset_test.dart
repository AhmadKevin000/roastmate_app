// Verifikasi `.env` sebagai dotfile-asset dapat dibaca `rootBundle` di
// lingkungan test — dotfile kadang tidak ikut bundle di sebagian versi
// Flutter. Bila test ini merah, fallback: rename aset ke
// `assets/env/roastmate.env` (keputusan tercatat di docs/plans Plan 2).

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rootBundle bisa memuat .env (dotfile sebagai asset)', () async {
    final raw = await rootBundle.loadString('.env');
    expect(raw, isNotEmpty);
  });

  test('dotenv.load memuat variabel .env', () async {
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: '.env');
    }
    expect(dotenv.env.keys, isNotEmpty);
    expect(dotenv.env.containsKey('CLOUD_NAME'), isTrue);
  });
}
