// Uji mesin sync (D-29): mapping pure + backfill UUID pada SQLite in-memory.
//
// Push/pull jaringan (Supabase) tidak diuji di sini — butuh server. Yang
// diuji: mapper row ↔ payload cloud (pure) dan backfill `uuid`/`sync_status`
// yang menjadi prasyarat push. Kepatuhan: `docs/DATABASE_SCHEMA.md` §16.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import 'package:pbl_sem5/core/database/schema.dart';
import 'package:pbl_sem5/features/sync/data/sync_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('analysisToCloudMap / cloudToAnalysisRow', () {
    test('mapping lokal → cloud memuat uuid + user_id + kolom sync', () {
      final row = <String, Object?>{
        'id': 1,
        'uuid': 'u-1',
        'sync_status': 'pending',
        'created_at': '2026-01-01T00:00:00.000',
        'species': 'Arabica',
        'roast': 'Medium',
        'quality_score': 90,
        'quality_profile': 'High',
      };
      final cloud = analysisToCloudMap(row, userId: 'user-1');
      expect(cloud['uuid'], 'u-1');
      expect(cloud['user_id'], 'user-1');
      expect(cloud['created_at'], '2026-01-01T00:00:00.000');
      expect(cloud['species'], 'Arabica');
      expect(cloud['quality_score'], 90);
      // Metadata sync lokal tidak ikut ke cloud.
      expect(cloud.containsKey('sync_status'), isFalse);
      expect(cloud.containsKey('id'), isFalse);
    });

    test('mapping cloud → lokal menandai synced & tanpa id lokal', () {
      final row = cloudToAnalysisRow({
        'uuid': 'u-9',
        'user_id': 'user-1',
        'created_at': '2026-01-01T00:00:00.000',
        'species': 'Robusta',
        'roast': 'Dark',
        'quality_score': 75,
        'quality_profile': 'High',
      });
      expect(row['uuid'], 'u-9');
      expect(row['sync_status'], 'synced');
      expect(row.containsKey('id'), isFalse);
      expect(row['species'], 'Robusta');
    });

    test('roundtrip lokal → cloud → lokal mempertahankan kolom sync', () {
      final original = <String, Object?>{
        'id': 3,
        'uuid': 'u-3',
        'sync_status': 'pending',
        'created_at': '2026-02-02T10:00:00.000',
        'name': 'Batch uji',
        'species': 'Liberika',
        'roast': 'Light',
        'visible_beans': 12,
        'defect_rate': 0.1,
        'quality_score': 88,
        'quality_profile': 'High',
      };
      final restored = cloudToAnalysisRow(
        analysisToCloudMap(original, userId: 'user-1'),
      );
      for (final col in kAnalysisSyncColumns) {
        expect(restored[col], original[col], reason: 'kolom $col');
      }
    });
  });

  group('userRecipeToCloudMap / cloudToUserRecipeRow', () {
    test('mapping mempertahankan kolom resep user', () {
      final original = <String, Object?>{
        'recipe_id': 'U1',
        'uuid': 'ur-1',
        'sync_status': 'pending',
        'name': 'Resep uji',
        'method_id': null,
        'method_name': 'Lainnya',
        'species': 'Arabica',
        'quality_profile': 'Medium',
        'roast_context': 'Light',
        'created_at': '2026-03-03T00:00:00.000',
      };
      final cloud = userRecipeToCloudMap(original, userId: 'user-1');
      expect(cloud['uuid'], 'ur-1');
      expect(cloud['recipe_id'], 'U1');

      final restored = cloudToUserRecipeRow(cloud);
      for (final col in kUserRecipeSyncColumns) {
        expect(restored[col], original[col], reason: 'kolom $col');
      }
    });
  });

  group('SyncService.backfillUuids', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      for (final stmt in kCreateTableStatements) {
        await db.execute(stmt);
      }
      for (final stmt in kCreateIndexStatements) {
        await db.execute(stmt);
      }
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> insertAnalysis({String? uuid, String? status}) =>
        db.insert('analyses', {
          'created_at': '2026-01-01T00:00:00.000',
          if (uuid != null) 'uuid': uuid,
          'sync_status': status ?? 'local',
        });

    test('baris local tanpa uuid diberi uuid + status pending', () async {
      final id = await insertAnalysis();
      final service = SyncService(db, null, 'user-1');
      await service.backfillUuids();

      final row = await db.query('analyses', where: 'id = ?', whereArgs: [id]);
      expect(row.single['uuid'], isNotNull);
      expect(row.single['sync_status'], 'pending');
    });

    test('uuid lama tidak ditimpa; baris synced dibiarkan', () async {
      final syncedId = await insertAnalysis(uuid: 'synced-u', status: 'synced');
      final pendingId = await insertAnalysis(uuid: 'kept-u', status: 'pending');
      final service = SyncService(db, null, 'user-1');
      await service.backfillUuids();

      final synced = await db.query(
        'analyses',
        where: 'id = ?',
        whereArgs: [syncedId],
      );
      final pending = await db.query(
        'analyses',
        where: 'id = ?',
        whereArgs: [pendingId],
      );
      expect(synced.single['uuid'], 'synced-u');
      expect(synced.single['sync_status'], 'synced');
      expect(pending.single['uuid'], 'kept-u');
    });

    test('tiap baris diberi uuid unik', () async {
      await insertAnalysis();
      await insertAnalysis();
      await insertAnalysis();
      final service = SyncService(db, null, 'user-1');
      await service.backfillUuids();

      final rows = await db.query('analyses');
      final uuids = rows.map((r) => r['uuid'] as String).toSet();
      expect(uuids.length, rows.length);
    });
  });
}
