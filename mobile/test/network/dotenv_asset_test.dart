// Verifikasi kredensial TIDAK ikut ter-bundle sebagai aset APK.
//
// Sebelumnya `.env` didaftarkan di pubspec assets dan dibaca flutter_dotenv.
// Sekarang nilainya disuntikkan lewat `--dart-define-from-file=.env` saat
// build, jadi file tidak boleh masuk daftar aset.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/core/config/app_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pubspec tidak mendaftarkan .env sebagai aset', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('- .env'), isFalse);
  });

  test('tanpa dart-define, AppEnv kosong & layanan cloud nonaktif', () {
    expect(AppEnv.hasSupabase, isFalse);
    expect(AppEnv.hasCloudinary, isFalse);
  });
}
