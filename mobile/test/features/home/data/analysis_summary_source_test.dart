// Uji query SQL sumber data Beranda terhadap SQLite sungguhan (in-memory),
// memakai DDL kanonik dari `core/database/schema.dart`.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pbl_sem5/core/database/schema.dart';
import 'package:pbl_sem5/features/home/data/sources/analysis_summary_source.dart';

Future<Database> _openInMemoryDatabase() {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: kSchemaVersion,
      onCreate: (db, version) async {
        for (final stmt in kCreateTableStatements) {
          await db.execute(stmt);
        }
        for (final stmt in kCreateIndexStatements) {
          await db.execute(stmt);
        }
      },
    ),
  );
}

Future<void> _insertAnalysis(
  Database db, {
  String? name = 'Batch A',
  String createdAt = '2026-03-12T10:24:00',
  String? species = 'Arabica',
  int? visibleBeans = 24,
  int? qualityScore = 82,
}) async {
  await db.insert('analyses', <String, Object?>{
    'created_at': createdAt,
    'name': name,
    'species': species,
    'visible_beans': visibleBeans,
    'quality_score': qualityScore,
  });
}

void main() {
  sqfliteFfiInit();

  late Database db;
  late SqliteAnalysisSummarySource source;

  setUp(() async {
    db = await _openInMemoryDatabase();
    source = SqliteAnalysisSummarySource(databaseOpener: () async => db);
  });

  tearDown(() async {
    await db.close();
  });

  test('database kosong: total 0, rata-rata dan kartu terakhir kosong', () async {
    final snapshot = await source.fetchSummary();

    expect(snapshot.totalAnalyses, 0);
    expect(snapshot.averageScore, isNull);
    expect(snapshot.speciesCounts, isEmpty);
    expect(snapshot.recentRows, isEmpty);
  });

  test('menghitung total, rata-rata skor, dan komposisi species', () async {
    await _insertAnalysis(db, species: 'Arabica', qualityScore: 88);
    await _insertAnalysis(db, species: 'Arabica', qualityScore: 74);
    await _insertAnalysis(db, species: 'Robusta', qualityScore: 60);
    await _insertAnalysis(db, species: 'Mixed', qualityScore: 82);

    final snapshot = await source.fetchSummary();

    expect(snapshot.totalAnalyses, 4);
    expect(snapshot.averageScore, closeTo(76.0, 0.0001));
    expect(snapshot.speciesCounts, <String, int>{
      'Arabica': 2,
      'Robusta': 1,
      'Mixed': 1,
    });
  });

  test('species NULL tidak dihitung ke komposisi', () async {
    await _insertAnalysis(db, species: 'Arabica');
    await _insertAnalysis(db, species: null);

    final snapshot = await source.fetchSummary();

    expect(snapshot.totalAnalyses, 2);
    expect(snapshot.speciesCounts, <String, int>{'Arabica': 1});
  });

  test('rata-rata mengabaikan skor NULL, bukan menghitungnya 0', () async {
    await _insertAnalysis(db, qualityScore: 90);
    await _insertAnalysis(db, qualityScore: null);

    final snapshot = await source.fetchSummary();

    expect(snapshot.totalAnalyses, 2);
    expect(snapshot.averageScore, 90);
  });

  test('kartu terakhir terurut terbaru dan dibatasi recentLimit', () async {
    await _insertAnalysis(db, name: 'Paling lama', createdAt: '2026-03-01T08:00:00');
    await _insertAnalysis(db, name: 'Terbaru', createdAt: '2026-03-20T09:30:00');
    await _insertAnalysis(db, name: 'Tengah', createdAt: '2026-03-10T14:00:00');

    final snapshot = await source.fetchSummary(recentLimit: 2);

    expect(snapshot.recentRows, hasLength(2));
    expect(
      snapshot.recentRows.map((row) => row['name']),
      <String>['Terbaru', 'Tengah'],
    );
    expect(snapshot.recentRows.first['created_at'], '2026-03-20T09:30:00');
    // Total tetap seluruh riwayat, bukan hanya yang tampil.
    expect(snapshot.totalAnalyses, 3);
  });
}
