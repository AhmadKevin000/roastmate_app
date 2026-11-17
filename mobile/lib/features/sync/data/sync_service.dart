import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

/// Kolom `analyses` yang ikut ke cloud (D-29 §16).
const List<String> kAnalysisSyncColumns = [
  'created_at',
  'name',
  'image_path',
  'annotated_image_path',
  'batch_label',
  'batch_name',
  'model_version',
  'species',
  'roast',
  'roast_confidence',
  'roast_distribution',
  'visible_beans',
  'defect_rate',
  'shape_uniformity',
  'size_uniformity',
  'roast_uniformity',
  'quality_score',
  'quality_profile',
];

/// Kolom resep user yang ikut ke cloud.
const List<String> kUserRecipeSyncColumns = [
  'name',
  'method_id',
  'method_name',
  'species',
  'quality_profile',
  'roast_context',
  'dose_g',
  'water_volume_ml',
  'grind_size',
  'temperature_c',
  'brewing_time_s',
  'steps',
  'video_url',
  'notes',
  'created_at',
];

/// Mapping baris `analyses` lokal → payload cloud (pure, bisa diuji).
///
/// Kolom sync metadata (`sync_status`, `user_id` lokal) tidak ikut — cloud
/// menaruh `user_id` dari sesi auth.
Map<String, dynamic> analysisToCloudMap(
  Map<String, Object?> row, {
  required String userId,
}) {
  final map = <String, dynamic>{'uuid': row['uuid'], 'user_id': userId};
  for (final col in kAnalysisSyncColumns) {
    map[col] = row[col];
  }
  return map;
}

/// Mapping payload cloud → baris `analyses` lokal baru (pure, bisa diuji).
///
/// `sync_status` langsung `'synced'` — berasal dari pull.
Map<String, Object?> cloudToAnalysisRow(Map<String, dynamic> cloud) {
  final row = <String, Object?>{
    'uuid': cloud['uuid'] as String,
    'sync_status': 'synced',
  };
  for (final col in kAnalysisSyncColumns) {
    row[col] = cloud[col];
  }
  return row;
}

/// Mapping baris `user_brew_recipes` lokal → payload cloud (pure).
Map<String, dynamic> userRecipeToCloudMap(
  Map<String, Object?> row, {
  required String userId,
}) {
  final map = <String, dynamic>{
    'uuid': row['uuid'],
    'user_id': userId,
    'recipe_id': row['recipe_id'],
  };
  for (final col in kUserRecipeSyncColumns) {
    map[col] = row[col];
  }
  return map;
}

/// Mapping payload cloud → baris `user_brew_recipes` lokal (pure).
Map<String, Object?> cloudToUserRecipeRow(Map<String, dynamic> cloud) {
  final row = <String, Object?>{
    'recipe_id': (cloud['recipe_id'] as String?) ?? 'U${cloud['uuid']}',
    'uuid': cloud['uuid'] as String,
    'sync_status': 'synced',
  };
  for (final col in kUserRecipeSyncColumns) {
    row[col] = cloud[col];
  }
  return row;
}

/// Hasil satu siklus sync.
class SyncResult {
  SyncResult({this.pushed = 0, this.pulled = 0});

  final int pushed;
  final int pulled;
}

/// Mesin sync riwayat antar device (D-29).
///
/// Strategi: **union by `uuid`** — push baris `pending`, pull baris cloud
/// yang belum ada lokal. Data riwayat append-only sehingga tidak ada konflik
/// update; `updated_at` hanya audit.
class SyncService {
  SyncService(this._db, this._client, this._userId);

  final Database _db;

  /// Boleh null (mis. Supabase tidak dikonfigurasi) — backfill tetap bisa
  /// jalan; push/pull no-op.
  final SupabaseClient? _client;
  final String _userId;

  static const _uuid = Uuid();

  /// Jalankan siklus penuh: backfill uuid → push → pull.
  Future<SyncResult> run() async {
    await backfillUuids();
    final pushed = await push();
    final pulled = await pull();
    return SyncResult(pushed: pushed, pulled: pulled);
  }

  /// Beri UUID + tanda `pending` pada baris lama yang belum punya uuid
  /// (backfill D-29 §12 — dilakukan saat sync, bukan di migrasi).
  Future<void> backfillUuids() async {
    await _db.transaction((txn) async {
      await _backfillTable(txn, 'analyses');
      await _backfillTable(txn, 'analysis_defects');
      await _backfillTable(txn, 'recommendations');
      await _backfillTable(txn, 'user_brew_recipes');
    });
  }

  Future<void> _backfillTable(Transaction txn, String table) async {
    final rows = await txn.query(
      table,
      columns: table == 'user_brew_recipes' ? ['recipe_id'] : ['id'],
      where: 'uuid IS NULL AND sync_status != ?',
      whereArgs: ['synced'],
    );
    for (final row in rows) {
      final whereCol = row.containsKey('recipe_id') ? 'recipe_id' : 'id';
      await txn.update(
        table,
        {'uuid': _uuid.v4(), 'sync_status': 'pending'},
        where: '$whereCol = ?',
        whereArgs: [row[whereCol]],
      );
    }
  }

  /// Push semua baris `pending` ke cloud (upsert by uuid), lalu tandai
  /// `synced`. Analyses di-push bersama defects & recommendations-nya.
  Future<int> push() async {
    final client = _client;
    if (client == null) return 0;
    final pending = await _db.query(
      'analyses',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );
    var pushed = 0;
    for (final row in pending) {
      final localId = row['id'] as int;
      final uuid = row['uuid'] as String;

      await client
          .from('analyses')
          .upsert(analysisToCloudMap(row, userId: _userId));

      await _pushChildren(client, localId, uuid);

      await _db.update(
        'analyses',
        {
          'sync_status': 'synced',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'user_id': _userId,
        },
        where: 'id = ?',
        whereArgs: [localId],
      );
      pushed++;
    }

    // Resep user — tabel terpisah, tanpa anak.
    final pendingRecipes = await _db.query(
      'user_brew_recipes',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );
    for (final row in pendingRecipes) {
      await client
          .from('user_brew_recipes')
          .upsert(userRecipeToCloudMap(row, userId: _userId));
      await _db.update(
        'user_brew_recipes',
        {
          'sync_status': 'synced',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'user_id': _userId,
        },
        where: 'recipe_id = ?',
        whereArgs: [row['recipe_id']],
      );
      pushed++;
    }
    return pushed;
  }

  Future<void> _pushChildren(
    SupabaseClient client,
    int localId,
    String analysisUuid,
  ) async {
    final defects = await _db.query(
      'analysis_defects',
      where: 'analysis_id = ? AND sync_status = ?',
      whereArgs: [localId, 'pending'],
    );
    for (final d in defects) {
      await client.from('analysis_defects').upsert({
        'uuid': d['uuid'],
        'user_id': _userId,
        'analysis_uuid': analysisUuid,
        'defect_class': d['defect_class'],
        'count': d['count'],
      });
      await _db.update(
        'analysis_defects',
        {'sync_status': 'synced'},
        where: 'id = ?',
        whereArgs: [d['id']],
      );
    }

    final recs = await _db.query(
      'recommendations',
      where: 'analysis_id = ? AND sync_status = ?',
      whereArgs: [localId, 'pending'],
    );
    for (final r in recs) {
      await client.from('recommendations').upsert({
        'uuid': r['uuid'],
        'user_id': _userId,
        'analysis_uuid': analysisUuid,
        'primary_method_id': r['primary_method_id'],
        'primary_recipe_id': r['primary_recipe_id'],
        'alternative_method_id': r['alternative_method_id'],
        'reason': r['reason'],
      });
      await _db.update(
        'recommendations',
        {'sync_status': 'synced'},
        where: 'id = ?',
        whereArgs: [r['id']],
      );
    }
  }

  /// Pull baris cloud milik user yang belum ada di SQLite lokal.
  /// Idempoten: uuid duplikat diabaikan.
  Future<int> pull() async {
    final client = _client;
    if (client == null) return 0;
    var pulled = 0;

    final cloudAnalyses = await client
        .from('analyses')
        .select()
        .eq('user_id', _userId);
    for (final cloud in cloudAnalyses.cast<Map<String, dynamic>>()) {
      final uuid = cloud['uuid'] as String;
      final existing = await _db.query(
        'analyses',
        where: 'uuid = ?',
        whereArgs: [uuid],
        limit: 1,
      );
      if (existing.isNotEmpty) continue;

      final id = await _db.insert('analyses', cloudToAnalysisRow(cloud));
      await _pullDefects(client, uuid, id);
      await _pullRecommendation(client, uuid, id);
      pulled++;
    }

    final cloudRecipes = await client
        .from('user_brew_recipes')
        .select()
        .eq('user_id', _userId);
    for (final cloud in cloudRecipes.cast<Map<String, dynamic>>()) {
      final uuid = cloud['uuid'] as String;
      final existing = await _db.query(
        'user_brew_recipes',
        where: 'uuid = ?',
        whereArgs: [uuid],
        limit: 1,
      );
      if (existing.isNotEmpty) continue;
      await _db.insert('user_brew_recipes', cloudToUserRecipeRow(cloud));
      pulled++;
    }
    return pulled;
  }

  Future<void> _pullDefects(
    SupabaseClient client,
    String analysisUuid,
    int localId,
  ) async {
    final cloudDefects = await client
        .from('analysis_defects')
        .select()
        .eq('analysis_uuid', analysisUuid);
    for (final d in cloudDefects.cast<Map<String, dynamic>>()) {
      final duuid = d['uuid'] as String;
      final exists = await _db.query(
        'analysis_defects',
        where: 'uuid = ?',
        whereArgs: [duuid],
        limit: 1,
      );
      if (exists.isNotEmpty) continue;
      await _db.insert('analysis_defects', {
        'uuid': duuid,
        'sync_status': 'synced',
        'analysis_id': localId,
        'defect_class': d['defect_class'],
        'count': d['count'],
      });
    }
  }

  Future<void> _pullRecommendation(
    SupabaseClient client,
    String analysisUuid,
    int localId,
  ) async {
    final cloudRecs = await client
        .from('recommendations')
        .select()
        .eq('analysis_uuid', analysisUuid)
        .limit(1);
    if (cloudRecs.isEmpty) return;
    final r = cloudRecs.first;
    final exists = await _db.query(
      'recommendations',
      where: 'uuid = ?',
      whereArgs: [r['uuid']],
      limit: 1,
    );
    if (exists.isNotEmpty) return;
    await _db.insert('recommendations', {
      'uuid': r['uuid'],
      'sync_status': 'synced',
      'analysis_id': localId,
      'primary_method_id': r['primary_method_id'],
      'primary_recipe_id': r['primary_recipe_id'],
      'alternative_method_id': r['alternative_method_id'],
      'reason': r['reason'],
    });
  }
}
