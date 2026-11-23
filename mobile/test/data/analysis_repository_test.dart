// Uji roundtrip `AnalysisRepository`: insert hasil analisis (gaya data mock
// riwayat) → baca kembali → bandingkan field per field.
//
// Ekspektasi mengacu ke `docs/DATABASE_SCHEMA.md` §6–§8 dan D-19:
// - deteksi per-biji tidak disimpan,
// - rekomendasi butuh `method_id` valid di `brew_methods` (FK),
// - grade & defectRate diturunkan, tidak disimpan.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart'
    show Database, Sqflite, databaseFactory, inMemoryDatabasePath, openDatabase;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import 'package:pbl_sem5/core/database/knowledge_base_seeder.dart';
import 'package:pbl_sem5/core/database/schema.dart';
import 'package:pbl_sem5/features/analysis/data/sources/analysis_repository.dart';
import 'package:pbl_sem5/shared/models/analysis_result.dart';

void main() {
  // Diperlukan agar `rootBundle` (dipakai seeder KB) tersedia di test.
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(() {
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
      DefectClass.normal: 26,
      DefectClass.quaker: 1,
      DefectClass.broken: 1,
    },
    species: 'Arabica',
    roast: 'Light',
    summaryText: 'ringkasan tidak disimpan',
    alternatives: const [],
    detections: const [],
    modelVersion: 'Model CV v2.4',
    shapeUniformity: 0.88,
    sizeUniformity: 0.84,
    roastUniformity: 0.81,
    roastConfidence: 0.91,
    roastDistribution: const {'Light': 0.8, 'Medium': 0.18, 'Dark': 0.02},
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
    // KB 14 resep (Plan 1) — dibutuhkan uji join rekomendasi (Plan 3).
    await KnowledgeBaseSeeder(db).seedIfEmpty();
    repo = AnalysisRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AnalysisRepository', () {
    test('insert lalu getHistory mengembalikan field yang sama', () async {
      final createdAt = DateTime(2025, 3, 12, 10, 24);
      const imageUrl =
          'https://res.cloudinary.com/demo/image/upload/batch_042.jpg';
      final id = await repo.insertResult(
        fixture,
        createdAt: createdAt,
        imagePath: imageUrl,
      );
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
      // Foto analisis termapping (Plan 3) + id untuk navigasi per id.
      expect(item.imagePath, imageUrl);
      expect(item.detail.analysisId, id);

      // Rekap defect: kelas bernilai 0 tetap terbaca sebagai 0.
      expect(item.defectCounts[DefectClass.normal], 26);
      expect(item.defectCounts[DefectClass.quaker], 1);
      expect(item.defectCounts[DefectClass.broken], 1);
      expect(item.defectCounts[DefectClass.severe], 0);

      // Turunan konsisten dengan entity (D-02): grade & defectRate dihitung.
      // defectRate BERBOBOT (PRD AC-03): (1×0.7 + 1×0.3) / 28 = 1.0/28
      expect(item.detail.grade, IndicativeGrade.specialty);
      expect(item.detail.defectRate, closeTo(1.0 / 28, 1e-9));

      // Kolom uniformity & provenance roast roundtrip (Plan 1).
      expect(item.detail.shapeUniformity, 0.88);
      expect(item.detail.sizeUniformity, 0.84);
      expect(item.detail.roastUniformity, 0.81);
      expect(item.detail.roastConfidence, 0.91);
      expect(
        item.detail.roastDistribution,
        {'Light': 0.8, 'Medium': 0.18, 'Dark': 0.02},
      );

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
          defectCounts: const {DefectClass.normal: 33, DefectClass.broken: 1},
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
            DefectClass.normal: 26,
            DefectClass.severe: 4,
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

    test('deleteAnalysis menghapus defects & recommendations (cascade)',
        () async {
      final id = await repo.insertResult(
        fixture,
        createdAt: DateTime(2025, 3, 12),
        recommendation: const RecommendationRef(
          methodId: 'M001',
          recipeId: 'R004',
          reason: 'uji cascade',
        ),
      );

      expect(
        Sqflite.firstIntValue(
          await db.rawQuery(
              'SELECT COUNT(*) FROM analysis_defects WHERE analysis_id = ?',
              [id]),
        ),
        greaterThan(0),
      );
      expect(
        Sqflite.firstIntValue(
          await db.rawQuery(
              'SELECT COUNT(*) FROM recommendations WHERE analysis_id = ?',
              [id]),
        ),
        1,
      );

      await repo.deleteAnalysis(id);

      expect(
        Sqflite.firstIntValue(
          await db.rawQuery(
              'SELECT COUNT(*) FROM analysis_defects WHERE analysis_id = ?',
              [id]),
        ),
        0,
        reason: 'defects ikut terhapus via ON DELETE CASCADE',
      );
      expect(
        Sqflite.firstIntValue(
          await db.rawQuery(
              'SELECT COUNT(*) FROM recommendations WHERE analysis_id = ?',
              [id]),
        ),
        0,
        reason: 'rekomendasi ikut terhapus via ON DELETE CASCADE',
      );
    });

    test('rekomendasi ditolak bila method_id tidak ada di KB (FK)', () async {
      await expectLater(
        repo.insertResult(
          fixture,
          createdAt: DateTime(2025, 3, 12),
          recommendation: const RecommendationRef(
            methodId: 'M999', // tidak ada di seed KB
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

  // ---------------------------------------------------------------------------
  // getDetail (Plan 3): analyses + defects + foto + join rekomendasi KB.
  // ---------------------------------------------------------------------------
  group('getDetail', () {
    const imageUrl =
        'https://res.cloudinary.com/demo/image/upload/batch_042.jpg';

    test('membaca baris + defect + foto + rekomendasi join KB (R004)',
        () async {
      final id = await repo.insertResult(
        fixture,
        createdAt: DateTime(2025, 3, 12, 10, 24),
        imagePath: imageUrl,
        recommendation: const RecommendationRef(
          methodId: 'M001',
          recipeId: 'R004', // Arabica | Light default
          alternativeMethodId: 'M002',
          reason:
              'Skor Specialty dengan defect rendah — V60 mengoptimalkan clarity.',
        ),
      );

      final detail = await repo.getDetail(id);
      expect(detail, isNotNull);
      expect(detail!.analysisId, id);

      // `analyses` + defects roundtrip (termasuk uniformity & defectRate).
      expect(detail.result.batchName, 'Mandheling Honey Anaerob');
      expect(detail.result.species, 'Arabica');
      expect(detail.result.roast, 'Light');
      expect(detail.result.qualityScore, 86);
      expect(detail.result.visibleBeans, 28);
      expect(detail.result.defectCounts[DefectClass.quaker], 1);
      expect(detail.result.defectCounts[DefectClass.broken], 1);
      expect(detail.result.shapeUniformity, 0.88);
      expect(detail.result.defectRate, closeTo(1.0 / 28, 1e-9));
      expect(detail.result.analysisId, id);

      // Foto analisis = URL yang di-insert.
      expect(detail.imagePath, imageUrl);

      // summaryText di-generate runtime (D-20): deterministik.
      expect(detail.summaryText, contains('Mandheling Honey Anaerob'));
      expect(detail.summaryText, contains('Arabica, Light'));
      expect(detail.summaryText, contains('28 biji'));
      expect(detail.summaryText, contains('skor 86/100 (High)'));
      expect(detail.summaryText, contains('Defect dominan: Quaker'));

      // Rekomendasi dari join KB: R004 (15g/240ml → 1:16, 170s → 02:50).
      final rec = detail.recommendation;
      expect(rec, isNotNull);
      expect(rec!.methodTitle, 'V60 / Pour Over — Metode Drip Perkusi Manual');
      expect(rec.reasonText, contains('V60 mengoptimalkan clarity'));
      expect(rec.ratio, '1:16');
      expect(rec.ratioSub, '15g : 240ml air');
      expect(rec.tempC, '93°C');
      expect(rec.grind, 'Medium-Fine');
      expect(rec.targetTime, '02:50');

      // Alternatif: M002 + resep default species Arabica (R002, 18g/252ml).
      expect(detail.alternatives, hasLength(1));
      final alt = detail.alternatives.single;
      expect(alt.title, 'French Press — Ekstraksi Immersion Rendam Total');
      expect(alt.ratio, '1:14');
      expect(alt.grind, 'Coarse');
      expect(alt.targetTime, '04:00');
    });

    test('id tak dikenal → null', () async {
      expect(await repo.getDetail(9999), isNull);
    });

    test('tanpa recommendations → detail tetap ada, rekomendasi null',
        () async {
      final id = await repo.insertResult(
        fixture,
        createdAt: DateTime(2025, 3, 12),
      );

      final detail = await repo.getDetail(id);
      expect(detail, isNotNull);
      expect(detail!.recommendation, isNull);
      expect(detail.alternatives, isEmpty);
      expect(detail.imagePath, isNull);
      // Ringkasan tetap ter-generate meski tanpa rekomendasi.
      expect(detail.summaryText, contains('skor 86/100'));
    });
  });

  group('Penilaian pribadi (v8, D-31)', () {
    test('savePersonalRating tersimpan & terbaca di history + detail', () async {
      final id = await repo.insertResult(
        fixture,
        createdAt: DateTime(2025, 3, 12),
      );
      // Awal: belum dinilai.
      expect((await repo.getHistory()).first.personalRating, isNull);

      await repo.savePersonalRating(id, stars: 4, note: '  Aroma kuat  ');

      final item = (await repo.getHistory()).first;
      expect(item.personalRating, 4);
      expect(item.personalRatingNote, 'Aroma kuat');

      final detail = await repo.getDetail(id);
      expect(detail!.personalRating, 4);
      expect(detail.personalRatingNote, 'Aroma kuat');
    });

    test('catatan kosong/spasi disimpan sebagai NULL', () async {
      final id = await repo.insertResult(
        fixture,
        createdAt: DateTime(2025, 3, 12),
      );
      await repo.savePersonalRating(id, stars: 5, note: '   ');

      final detail = await repo.getDetail(id);
      expect(detail!.personalRating, 5);
      expect(detail.personalRatingNote, isNull);
    });

    test('bintang di luar 1–5 ditolak sebelum menulis DB', () async {
      final id = await repo.insertResult(
        fixture,
        createdAt: DateTime(2025, 3, 12),
      );
      expect(
        () => repo.savePersonalRating(id, stars: 0),
        throwsArgumentError,
      );
      expect(
        () => repo.savePersonalRating(id, stars: 6),
        throwsArgumentError,
      );
      expect((await repo.getDetail(id))!.personalRating, isNull);
    });

    test('menimpa penilaian lama (satu nilai per analisis)', () async {
      final id = await repo.insertResult(
        fixture,
        createdAt: DateTime(2025, 3, 12),
      );
      await repo.savePersonalRating(id, stars: 2, note: 'asam');
      await repo.savePersonalRating(id, stars: 5, note: null);

      final history = await repo.getHistory();
      expect(history, hasLength(1));
      expect(history.first.personalRating, 5);
      expect(history.first.personalRatingNote, isNull);
    });
  });
}
