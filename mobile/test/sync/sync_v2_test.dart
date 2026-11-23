// Uji Fase 2–3 sinkronisasi v2 (D-32): sanitasi foto, LWW, tombstone,
// kolom skema v9, dan perilaku repository penulis outbox.
//
// Jaringan Supabase tidak diuji di sini (butuh server). Fokus pada pure
// function + SQLite in-memory via ffi.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart'
    show Database, ConflictAlgorithm, databaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import 'package:pbl_sem5/core/database/schema.dart';
import 'package:pbl_sem5/features/analysis/data/sources/analysis_repository.dart';
import 'package:pbl_sem5/features/brew/data/repositories/brewing_repository_impl.dart';
import 'package:pbl_sem5/features/sync/data/sync_service.dart';
import 'package:pbl_sem5/shared/models/analysis_result.dart';

import '../database/schema_spec_test.dart' show openSchemaDatabase;
import '../brew/user_recipe_repository_test.dart'
    show fixtureRecipe, openRecipeDatabase;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Fase 3 — sanitasi payload', () {
    test('publicImagePath: path lokal NULL, URL dipertahankan', () {
      expect(publicImagePath('/data/user/0/app/cache/scan.jpg'), isNull);
      expect(publicImagePath(''), isNull);
      expect(publicImagePath(null), isNull);
      expect(
        publicImagePath('https://res.cloudinary.com/demo/image/upload/a.jpg'),
        'https://res.cloudinary.com/demo/image/upload/a.jpg',
      );
    });

    test('publicIdFromUrl: buang versi & ekstensi', () {
      expect(
        publicIdFromUrl(
          'https://res.cloudinary.com/demo/image/upload/v1712/roastmate/analyses/abc.jpg',
        ),
        'roastmate/analyses/abc',
      );
      expect(publicIdFromUrl('https://contoh.com/foto.png'), isNull);
    });

    test('analysisToCloudMap: uuid, user_id, updated_at, rating, foto aman', () {
      final map = analysisToCloudMap(
        {
          'uuid': 'u-1',
          'image_path': '/data/user/0/scan.jpg',
          'personal_rating': 4,
          'personal_rating_note': 'enak',
        },
        userId: 'user-1',
        updatedAt: '2026-01-02T00:00:00.000Z',
      );
      expect(map['uuid'], 'u-1');
      expect(map['user_id'], 'user-1');
      expect(map['updated_at'], '2026-01-02T00:00:00.000Z');
      expect(map['image_path'], isNull);
      expect(map['personal_rating'], 4);
      expect(map['personal_rating_note'], 'enak');
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('sync_status'), isFalse);
    });

    test('cloudToAnalysisRow: URL cloud → uploaded, path lokal → none', () {
      final uploaded = cloudToAnalysisRow({
        'uuid': 'u-2',
        'image_path': 'https://res.cloudinary.com/demo/a.jpg',
        'updated_at': '2026-01-02T00:00:00.000Z',
      });
      expect(uploaded['image_sync_status'], 'uploaded');
      expect(uploaded['sync_status'], 'synced');
      expect(uploaded['updated_at'], '2026-01-02T00:00:00.000Z');

      final local = cloudToAnalysisRow({
        'uuid': 'u-3',
        'image_path': '/data/user/0/scan.jpg',
      });
      expect(local['image_sync_status'], 'none');
    });

    test('userRecipe roundtrip: uuid/updated_at/recipe_id terjaga', () {
      final payload = userRecipeToCloudMap(
        {
          'uuid': 'r-1',
          'recipe_id': 'U123',
          'name': 'Resep Uji',
          'created_at': '2026-01-01T00:00:00.000',
        },
        userId: 'user-1',
        updatedAt: '2026-01-02T00:00:00.000Z',
      );
      expect(payload['user_id'], 'user-1');
      expect(payload['recipe_id'], 'U123');
      expect(payload['updated_at'], '2026-01-02T00:00:00.000Z');

      final row = cloudToUserRecipeRow(payload);
      expect(row['uuid'], 'r-1');
      expect(row['recipe_id'], 'U123');
      expect(row['name'], 'Resep Uji');
      expect(row['sync_status'], 'synced');
    });
  });

  group('Fase 3 — last-write-wins', () {
    test('shouldApplyCloud: cloud lebih baru → true, lebih tua → false', () {
      final local = {'updated_at': '2026-01-01T00:00:00.000Z'};
      expect(
        shouldApplyCloud(local, {'updated_at': '2026-01-02T00:00:00.000Z'}),
        isTrue,
      );
      expect(
        shouldApplyCloud(local, {'updated_at': '2025-12-31T00:00:00.000Z'}),
        isFalse,
      );
    });

    test('shouldApplyCloud: tanpa updated_at atau lokal kosong', () {
      expect(shouldApplyCloud({}, {'updated_at': '2026-01-02T00:00:00.000Z'}),
          isTrue);
      expect(shouldApplyCloud({'updated_at': '2026-01-01T00:00:00.000Z'}, {}),
          isFalse);
    });
  });

  group('Fase 2 — skema v9', () {
    late Database db;

    setUp(() async {
      db = await openSchemaDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('sync_deletes + kolom foto tersedia dengan default benar', () async {
      expect(kSchemaVersion, 9);
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_deletes'",
      );
      expect(tables, hasLength(1));

      final cols = await db.rawQuery('PRAGMA table_info(analyses)');
      final names = cols.map((c) => c['name'] as String).toSet();
      expect(names, containsAll({
        'image_sync_status',
        'image_upload_attempts',
        'cloudinary_public_id',
        'personal_rating',
      }));

      await db.insert('analyses', {
        'created_at': '2026-01-01T00:00:00.000',
        'image_path': '/data/user/0/scan.jpg',
      });
      final row = (await db.query('analyses')).single;
      // DDL default = 'none'; repository yang menaikkan ke 'pending'.
      expect(row['image_sync_status'], 'none');
      expect(row['image_upload_attempts'], 0);
    });

    test('Repository: insert → rating → URL foto menandai pending', () async {
      final repo = AnalysisRepository(db);
      final result = InspectionResult(
        batchLabel: 'Batch #T',
        batchName: 'Template',
        analyzedAgo: '-',
        qualityScore: 80,
        visibleBeans: 20,
        defectCounts: const {DefectClass.normal: 20},
        species: 'Arabica',
        roast: 'Light',
        summaryText: '',
        alternatives: const [],
        detections: const [],
        modelVersion: 'v-test',
      );
      final id = await repo.insertResult(
        result,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000'),
        imagePath: '/data/user/0/scan.jpg',
      );

      var row = (await db.query('analyses', where: 'id = ?', whereArgs: [id]))
          .single;
      expect(row['image_sync_status'], 'pending');

      await repo.savePersonalRating(id, stars: 5, note: 'mantap');
      row = (await db.query('analyses', where: 'id = ?', whereArgs: [id])).single;
      expect(row['sync_status'], 'pending');
      expect(row['personal_rating'], 5);

      await repo.updateImagePath(
        id,
        'https://res.cloudinary.com/demo/image/upload/v1/roastmate/analyses/x.jpg',
      );
      row = (await db.query('analyses', where: 'id = ?', whereArgs: [id])).single;
      expect(row['image_sync_status'], 'uploaded');
      expect(row['cloudinary_public_id'], 'roastmate/analyses/x');
      expect(row['sync_status'], 'pending');
    });

    test('deleteAnalysis menulis tombstone sebelum delete lokal', () async {
      final repo = AnalysisRepository(db);
      await db.insert('analyses', {
        'uuid': 'del-1',
        'created_at': '2026-01-01T00:00:00.000',
      });
      final id = (await db.query('analyses')).single['id'] as int;

      await repo.deleteAnalysis(id);

      expect(await db.query('analyses', where: 'uuid = ?', whereArgs: ['del-1']),
          isEmpty);
      final tomb = (await db.query('sync_deletes')).single;
      expect(tomb['uuid'], 'del-1');
      expect(tomb['table_name'], 'analyses');
      expect(tomb['synced'], 0);
    });
  });

  group('Fase 2 — resep', () {
    late Database db;
    late BrewingRepositoryImpl repo;

    setUp(() async {
      db = await openRecipeDatabase();
      repo = BrewingRepositoryImpl(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('deleteUserRecipe menulis tombstone', () async {
      await repo.insertUserRecipe(fixtureRecipe());
      final row = (await db.query('user_brew_recipes')).single;
      final recipeId = row['recipe_id'] as String;
      await db.update(
        'user_brew_recipes',
        {'uuid': 'recipe-uuid-1'},
        where: 'recipe_id = ?',
        whereArgs: [recipeId],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await repo.deleteUserRecipe(recipeId);

      expect(await db.query('user_brew_recipes'), isEmpty);
      final tomb = (await db.query('sync_deletes')).single;
      expect(tomb['uuid'], 'recipe-uuid-1');
      expect(tomb['table_name'], 'user_brew_recipes');
    });
  });

  group('Fase 3 — runner lokal', () {
    test('run() tanpa client: backfill uuid tanpa melempar', () async {
      final db = await openSchemaDatabase();
      addTearDown(db.close);
      await db.insert('analyses', {
        'created_at': '2026-01-01T00:00:00.000',
        'sync_status': 'local',
      });

      final result = await SyncService(db, null, 'user-1').run();

      final row = (await db.query('analyses')).single;
      expect(row['uuid'], isNotNull);
      expect(row['sync_status'], 'pending');
      expect(result.pushed, 0);
      expect(result.pulled, 0);
    });

    test('SyncResult.label merangkum empat angka', () {
      expect(
        SyncResult(pushed: 2, pulled: 3, deleted: 1, uploaded: 4).label,
        contains('2 dikirim, 3 ditarik, 1 dihapus, 4 foto diunggah'),
      );
    });
  });
}
