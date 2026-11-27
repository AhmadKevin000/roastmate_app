import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/repositories/onboarding_repository.dart';

/// Implementasi repositori onboarding berbasis tabel `meta` di SQLite lokal.
///
/// Menjamin status onboarding tersimpan permanen di perangkat tanpa
/// ketergantungan jaringan (offline-first).
class OnboardingRepositoryImpl implements OnboardingRepository {
  static const String _kOnboardingKey = 'onboarding_completed';
  final AppDatabase _dbProvider;

  OnboardingRepositoryImpl({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  @override
  Future<bool> isOnboardingCompleted() async {
    try {
      final db = await _dbProvider.database;
      final rows = await db.query(
        'meta',
        where: 'key = ?',
        whereArgs: [_kOnboardingKey],
        limit: 1,
      );
      if (rows.isEmpty) return false;
      return rows.first['value'] == '1';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    try {
      final db = await _dbProvider.database;
      await db.insert(
        'meta',
        <String, Object?>{
          'key': _kOnboardingKey,
          'value': completed ? '1' : '0',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // Fallback defensif jika database belum siap
    }
  }
}
