// Uji roundtrip `AnalysisRepository`: insert hasil analisis (gaya data mock
// riwayat) → baca kembali → bandingkan field per field.
//
// Ekspektasi mengacu ke `docs/DATABASE_SCHEMA.md` §6–§8 dan D-19:
// - deteksi per-biji tidak disimpan,
// - rekomendasi butuh `method_id` valid di `brew_methods` (FK),
// - grade & defectRate diturunkan, tidak disimpan.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart'
    show Database, databaseFactory, inMemoryDatabasePath, openDatabase;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import 'package:pbl_sem5/core/database/schema.dart';
import 'package:pbl_sem5/data/analysis_repository.dart';
import 'package:pbl_sem5/domain/inspection_result.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late AnalysisRepository repo;

  // Fixture meniru `mockAnalysisHistory` Batch #042.
  final fixture = InspectionResult(
    batchLabel: 'Batch #042',
    batchName: 'Mandheling Honey Anaerob',
    analyzedAgo: 'Dipindai 12 menit yang lalu',
    qualityScore: 86,
    visibleBeans: 28,
    defectCounts: const {
      DefectClass.healthy: 26,
      DefectClass.broken: 1,
      DefectClass.quaker: 1,
      DefectClass.insectDamage: 0,
      DefectClass.scorched: 0,
      DefectClass.foreignMatter: 0,
    },
    species: 'Arabica',
    roast: 'Light',
    summaryText: 'ringkasan tidak disimpan',
    alternatives: const [],
    detections: const [],
    modelVersion: 'Model CV v2.4',
  );

  setUp(() async {
    // In-memory DB dengan skema yang sama — tidak berbagi file .db dengan
    // test `AppDatabase` (yang menghapus/membuat ulang roastmate.db).
    db = await openDatabase(
      inMemoryDatabasePath,
      version: kSchemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        final batch = db.batch();
        for (final stmt in kCreateTableStatements) {
          batch.execute(stmt);
        }
        for (final stmt in kCreateIndexStatements) {
          batch.execute(stmt);
        }
        await batch.commit(noResult: true);
        await db.insert('meta', <String, Object?>{
          'key': kMetaSchemaVersion,
          'value': version.toString(),
        });
      },
    );
    repo = AnalysisRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AnalysisRepository', () {
    test('insert lalu getHistory mengembalikan field yang sama', () async {
      final createdAt = DateTime(2025, 3, 12, 10, 24);
      final id = await repo.insertResult(fixture, createdAt: createdAt);
      expect(id, greaterThan(0));

      final history = await repo.getHistory();
      expect(history, hasLength(1));

      final item = history.first;
      expect(item.detail.batchLabel, 'Batch #042');
      expect(item.detail.batchName, 'Mandheling Honey Anaerob');
      expect(item.detail.species, 'Arabica');
      expect(item.detail.roast, 'Light');
      expect(item.detail.qualityScore, 86);
      expect(item.detail.visibleBeans, 28);
      expect(item.detail.modelVersion, 'Model CV v2.4');

      // Rekap defect: kelas bernilai 0 tetap terbaca sebagai 0.
      expect(item.defectCounts[DefectClass.healthy], 26);
      expect(item.defectCounts[DefectClass.broken], 1);
      expect(item.defectCounts[DefectClass.quaker], 1);
      expect(item.defectCounts[DefectClass.insectDamage], 0);
      expect(item.defectCounts[DefectClass.scorched], 0);
      expect(item.defectCounts[DefectClass.foreignMatter], 0);

      // Turunan konsisten dengan entity (D-02): grade & defectRate dihitung.
      expect(item.detail.grade, IndicativeGrade.specialty);
      expect(item.detail.defectRate, closeTo(2 / 28, 1e-9));

      // Deteksi per-biji & rekomendasi memang tidak disimpan (D-19).
      expect(item.detail.detections, isEmpty);
      expect(item.detail.recommendation, isNull);
    });

    test('getHistory urut terbaru dulu & filter species bekerja', () async {
      await repo.insertResult(fixture, createdAt: DateTime(2025, 3, 12));
      await repo.insertResult(
        InspectionResult(
          batchLabel: 'Batch #041',
          batchName: 'Gayo Washed Grade 1',
          analyzedAgo: '-',
          qualityScore: 90,
          visibleBeans: 34,
          defectCounts: const {DefectClass.healthy: 33, DefectClass.broken: 1},
          species: 'Arabica',
          roast: 'Light',
          summaryText: '',
          alternatives: const [],
          detections: const [],
          modelVersion: 'Model CV v2.4',
        ),
        createdAt: DateTime(2025, 3, 11),
      );
      await repo.insertResult(
        InspectionResult(
          batchLabel: 'Batch #040',
          batchName: 'Temanggung Fine Robusta',
          analyzedAgo: '-',
          qualityScore: 82,
          visibleBeans: 30,
          defectCounts: const {
            DefectClass.healthy: 26,
            DefectClass.insectDamage: 2,
            DefectClass.scorched: 2,
          },
          species: 'Robusta',
          roast: 'Dark',
          summaryText: '',
          alternatives: const [],
          detections: const [],
          modelVersion: 'Model CV v2.4',
        ),
        createdAt: DateTime(2025, 3, 10),
      );

      final all = await repo.getHistory();
      expect(all, hasLength(3));
      expect(all.first.detail.batchLabel, 'Batch #042'); // terbaru dulu
      expect(all.last.detail.batchLabel, 'Batch #040');

      final robusta = await repo.getHistory(species: 'Robusta');
      expect(robusta, hasLength(1));
      expect(robusta.first.detail.species, 'Robusta');

      final mixed = await repo.getHistory(species: 'Mixed');
      expect(mixed, isEmpty);
    });

    test('getById & deleteAnalysis bekerja', () async {
      final id = await repo.insertResult(
        fixture,
        createdAt: DateTime(2025, 3, 12),
      );

      final item = await repo.getById(id);
      expect(item, isNotNull);
      expect(item!.detail.batchName, 'Mandheling Honey Anaerob');

      await repo.deleteAnalysis(id);
      expect(await repo.getById(id), isNull);
      expect(await repo.getHistory(), isEmpty);
    });

    test('rekomendasi ditolak bila method_id tidak ada di KB (FK)', () async {
      await expectLater(
        repo.insertResult(
          fixture,
          createdAt: DateTime(2025, 3, 12),
          recommendation: const RecommendationRef(
            methodId: 'M001',
            reason: 'uji FK',
          ),
        ),
        throwsA(anything),
      );
    });

    test('formatHistoryDate mengikuti gaya mockup', () {
      final label = formatHistoryDate(DateTime(2025, 3, 12, 10, 24));
      expect(label, contains('12 Mar 2025'));
      expect(label, contains('10:24'));
      expect(label, contains('WIB'));
    });

    test('relativeTimeLabel menghasilkan label relatif', () {
      final now = DateTime(2025, 3, 12, 10, 36);
      expect(
        relativeTimeLabel(now.subtract(const Duration(minutes: 12)), now: now),
        'Dipindai 12 menit yang lalu',
      );
      expect(
        relativeTimeLabel(now.subtract(const Duration(days: 1)), now: now),
        'Dipindai kemarin',
      );
      expect(
        relativeTimeLabel(now.subtract(const Duration(days: 4)), now: now),
        'Dipindai 4 hari yang lalu',
      );
    });
  });
}
