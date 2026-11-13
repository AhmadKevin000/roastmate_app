import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';

/// Jumlah kartu "Analisis Terakhir" di Beranda.
const int kHomeRecentLimit = 3;

/// Potret agregat tabel `analyses` untuk Beranda.
///
/// Sengaja berisi tipe primitif (bukan entity) supaya repository yang
/// memetakan ke domain dan bisa diuji tanpa SQLite.
class AnalysisSummarySnapshot {
  const AnalysisSummarySnapshot({
    required this.totalAnalyses,
    required this.averageScore,
    required this.speciesCounts,
    required this.recentRows,
  });

  final int totalAnalyses;

  /// `null` bila belum ada analisis atau skor belum terisi.
  final double? averageScore;

  /// Jumlah analisis per species dominan.
  final Map<String, int> speciesCounts;

  /// Baris terbaru: `id`, `name`, `created_at`, `species`, `visible_beans`,
  /// `quality_score`.
  final List<Map<String, Object?>> recentRows;
}

/// Sumber data Beranda. Satu-satunya tempat query SQL beranda.
abstract interface class AnalysisSummarySource {
  Future<AnalysisSummarySnapshot> fetchSummary({int recentLimit});
}

/// Implementasi SQLite: agregasi dilakukan di database, bukan di UI.
class SqliteAnalysisSummarySource implements AnalysisSummarySource {
  SqliteAnalysisSummarySource({
    AppDatabase? database,
    Future<Database> Function()? databaseOpener,
  }) : _databaseOpener = databaseOpener ?? _defaultOpener(database);

  /// Pembuka database; bisa diganti pada test (mis. database in-memory).
  final Future<Database> Function() _databaseOpener;

  static Future<Database> Function() _defaultOpener(AppDatabase? database) {
    final appDatabase = database ?? AppDatabase.instance;
    return () => appDatabase.database;
  }

  @override
  Future<AnalysisSummarySnapshot> fetchSummary({
    int recentLimit = kHomeRecentLimit,
  }) async {
    final db = await _databaseOpener();

    final total =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM analyses')) ??
            0;

    if (total == 0) {
      return const AnalysisSummarySnapshot(
        totalAnalyses: 0,
        averageScore: null,
        speciesCounts: <String, int>{},
        recentRows: <Map<String, Object?>>[],
      );
    }

    final averageRows =
        await db.rawQuery('SELECT AVG(quality_score) AS average_score FROM analyses');
    final averageScore = averageRows.isEmpty
        ? null
        : (averageRows.first['average_score'] as num?)?.toDouble();

    final speciesRows = await db.rawQuery('''
      SELECT species, COUNT(*) AS total
      FROM analyses
      WHERE species IS NOT NULL
      GROUP BY species
    ''');

    final recentRows = await db.query(
      'analyses',
      columns: <String>[
        'id',
        'name',
        'created_at',
        'species',
        'visible_beans',
        'quality_score',
      ],
      orderBy: 'created_at DESC',
      limit: recentLimit,
    );

    return AnalysisSummarySnapshot(
      totalAnalyses: total,
      averageScore: averageScore,
      speciesCounts: <String, int>{
        for (final row in speciesRows)
          row['species'] as String: (row['total'] as num).toInt(),
      },
      recentRows: recentRows,
    );
  }
}
