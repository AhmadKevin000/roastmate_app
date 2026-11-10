import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pbl_sem5/data/database/app_database.dart';
import 'package:pbl_sem5/data/repositories/analysis_repository.dart';
import 'package:pbl_sem5/domain/inspection_result.dart';

void main() {
  // Setup sqflite ffi untuk environment desktop / unit testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late AnalysisRepository repository;

  setUp(() async {
    // Gunakan in-memory database unik untuk setiap test case
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE analyses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              batch_label TEXT,
              batch_name TEXT,
              created_at TEXT NOT NULL,
              image_path TEXT,
              species TEXT,
              roast TEXT,
              visible_beans INTEGER,
              defect_rate REAL,
              quality_score INTEGER,
              quality_profile TEXT,
              grade TEXT,
              summary_text TEXT,
              model_version TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE analysis_defects (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              analysis_id INTEGER NOT NULL REFERENCES analyses(id) ON DELETE CASCADE,
              defect_class TEXT NOT NULL,
              count INTEGER NOT NULL DEFAULT 0,
              UNIQUE (analysis_id, defect_class)
            )
          ''');

          await db.execute('''
            CREATE TABLE bean_detections (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              analysis_id INTEGER NOT NULL REFERENCES analyses(id) ON DELETE CASCADE,
              class_label TEXT NOT NULL,
              rect_left REAL NOT NULL,
              rect_top REAL NOT NULL,
              rect_width REAL NOT NULL,
              rect_height REAL NOT NULL,
              confidence REAL NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE recommendations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              analysis_id INTEGER NOT NULL UNIQUE REFERENCES analyses(id) ON DELETE CASCADE,
              method_title TEXT NOT NULL,
              reason_text TEXT NOT NULL,
              ratio TEXT NOT NULL,
              ratio_sub TEXT NOT NULL,
              temp_c TEXT NOT NULL,
              temp_c_sub TEXT NOT NULL,
              grind TEXT NOT NULL,
              grind_sub TEXT NOT NULL,
              target_time TEXT NOT NULL,
              target_time_sub TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE alternative_methods (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              analysis_id INTEGER NOT NULL REFERENCES analyses(id) ON DELETE CASCADE,
              title TEXT NOT NULL,
              description TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    AppDatabase.instance.setDatabase(db);
    repository = AnalysisRepository(appDatabase: AppDatabase.instance);
  });

  tearDown(() async {
    await db.close();
  });

  test('Menyimpan dan memuat hasil analisis lengkap dari SQLite (Roundtrip)', () async {
    final sampleResult = InspectionResult(
      batchLabel: "Batch #001",
      batchName: "Gayo Honey",
      analyzedAgo: "Baru saja",
      createdAt: DateTime.now(),
      qualityScore: 88,
      visibleBeans: 30,
      defectCounts: {
        DefectClass.healthy: 26,
        DefectClass.broken: 2,
        DefectClass.insectDamage: 1,
        DefectClass.quaker: 1,
        DefectClass.scorched: 0,
        DefectClass.foreignMatter: 0,
      },
      species: "Arabica",
      roast: "Light",
      summaryText: "Kualitas Specialty sangat tinggi.",
      recommendation: BrewRecommendation(
        methodTitle: "V60 Drip",
        reasonText: "Optimal untuk floral and fruity clarity.",
        ratio: "1:15",
        ratioSub: "15g : 225ml",
        tempC: "92°C",
        tempCSub: "90-93°C",
        grind: "Medium-Fine",
        grindSub: "14 klik",
        targetTime: "02:30",
        targetTimeSub: "Total tuang",
      ),
      alternatives: [
        AlternativeMethod(title: "Aeropress", description: "Body lebih creamy"),
      ],
      detections: [
        BeanDetection(
          classLabel: DefectClass.healthy,
          normalizedRect: const Rect.fromLTWH(0.1, 0.1, 0.2, 0.2),
          confidence: 0.95,
        ),
      ],
      modelVersion: "v1.0.0",
    );

    // 1. Simpan
    final id = await repository.saveInspection(sampleResult);
    expect(id, isPositive);

    // 2. Baca kembali
    final loaded = await repository.getInspectionById(id);
    expect(loaded, isNotNull);
    expect(loaded!.id, id);
    expect(loaded.batchName, "Gayo Honey");
    expect(loaded.qualityScore, 88);
    expect(loaded.species, "Arabica");
    expect(loaded.roast, "Light");
    expect(loaded.defectCounts[DefectClass.healthy], 26);
    expect(loaded.defectCounts[DefectClass.broken], 2);
    expect(loaded.recommendation, isNotNull);
    expect(loaded.recommendation!.methodTitle, "V60 Drip");
    expect(loaded.alternatives.length, 1);
    expect(loaded.alternatives.first.title, "Aeropress");
    expect(loaded.detections.length, 1);
    expect(loaded.detections.first.classLabel, DefectClass.healthy);

    // 3. Hitung jumlah
    final count = await repository.countInspections();
    expect(count, 1);

    // 4. Hapus
    final deleted = await repository.deleteInspection(id);
    expect(deleted, 1);

    final countAfter = await repository.countInspections();
    expect(countAfter, 0);

    // Verifikasi cascade delete
    final defectCountRows = await db.query('analysis_defects', where: 'analysis_id = ?', whereArgs: [id]);
    expect(defectCountRows.isEmpty, isTrue);
  });
}
