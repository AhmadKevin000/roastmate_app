import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/cloudinary_service.dart';

/// Kolom `analyses` yang ikut ke cloud (D-29 §16, D-32).
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
  'personal_rating',
  'personal_rating_note',
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

/// Tabel yang boleh dihapus lewat tombstone (whitelist, bukan input bebas).
const Set<String> kSyncableTables = {'analyses', 'user_brew_recipes'};

/// Path foto yang aman dikirim ke cloud: hanya URL publik.
///
/// Path lokal (`/data/user/0/...`) tidak berarti di device lain, jadi
/// dikirim sebagai `null`. Device yang memegang file tetap bisa merender
/// thumbnail lewat baris SQLite-nya sendiri.
String? publicImagePath(Object? value) {
  final v = value as String?;
  if (v == null || v.isEmpty) return null;
  return v.startsWith('http') ? v : null;
}

/// Ambil `public_id` Cloudinary dari `secure_url` (untuk audit & cleanup).
///
/// Dipertahankan sebagai alias agar pemakai lama tetap kompatibel.
String? publicIdFromUrl(String url) => cloudinaryPublicIdFromUrl(url);

/// Mapping baris `analyses` lokal → payload cloud (pure, bisa diuji).
///
/// Kolom sync metadata (`sync_status`, `id`, `user_id` lokal) tidak ikut —
/// cloud memakai `user_id` dari sesi auth.
Map<String, dynamic> analysisToCloudMap(
  Map<String, Object?> row, {
  required String userId,
  String? updatedAt,
}) {
  final map = <String, dynamic>{'uuid': row['uuid'], 'user_id': userId};
  if (updatedAt != null) map['updated_at'] = updatedAt;
  for (final col in kAnalysisSyncColumns) {
    map[col] = col == 'image_path'
        ? publicImagePath(row[col])
        : row[col];
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
    'image_sync_status': (cloud['image_path'] as String?)?.startsWith('http') ==
            true
        ? 'uploaded'
        : 'none',
  };
  if (cloud['updated_at'] != null) row['updated_at'] = cloud['updated_at'];
  for (final col in kAnalysisSyncColumns) {
    row[col] = cloud[col];
  }
  return row;
}

/// Mapping baris `user_brew_recipes` lokal → payload cloud (pure).
Map<String, dynamic> userRecipeToCloudMap(
  Map<String, Object?> row, {
  required String userId,
  String? updatedAt,
}) {
  final map = <String, dynamic>{
    'uuid': row['uuid'],
    'user_id': userId,
    'recipe_id': row['recipe_id'],
  };
  if (updatedAt != null) map['updated_at'] = updatedAt;
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
  if (cloud['updated_at'] != null) row['updated_at'] = cloud['updated_at'];
  for (final col in kUserRecipeSyncColumns) {
    row[col] = cloud[col];
  }
  return row;
}

/// True bila versi cloud lebih baru dari lokal (last-write-wins D-32).
///
/// Baris cloud tanpa `updated_at` dianggap lebih tua (data era D-29).
bool shouldApplyCloud(
  Map<String, Object?> local,
  Map<String, dynamic> cloud,
) {
  final cloudAt = DateTime.tryParse((cloud['updated_at'] as String?) ?? '');
  if (cloudAt == null) return false;
  final localAt = DateTime.tryParse((local['updated_at'] as String?) ?? '');
  if (localAt == null) return true;
  return cloudAt.toUtc().isAfter(localAt.toUtc());
}

/// Hasil satu siklus sync.
class SyncResult {
  SyncResult({
    this.pushed = 0,
    this.pulled = 0,
    this.deleted = 0,
    this.uploaded = 0,
  });

  final int pushed;
  final int pulled;
  final int deleted;
  final int uploaded;

  /// Ringkasan untuk UI (Profil).
  String get label =>
      'Sinkron selesai: $pushed dikirim, $pulled ditarik, '
      '$deleted dihapus, $uploaded foto diunggah.';
}

/// Mesin sync riwayat antar device (D-29, D-32).
///
/// Urutan satu siklus: backfill uuid → push tombstone → retry upload foto →
/// push baris `pending` → pull baris baru/terbaru → terapkan tombstone cloud.
///
/// Strategi:
/// - data immutable (analisis, defect, rekomendasi): union by `uuid`,
///   append-only;
/// - data mutable (rating, resep user): last-write-wins `updated_at` server;
/// - hapus: tombstone `deleted_records` agar tidak hidup lagi saat pull;
/// - upload foto bersifat opsional dan terpisah dari push data: baris dengan
///   `image_sync_status = 'pending'` tetap dikirim dengan `image_path = null`
///   (sanitasi), lalu dikirim ulang dengan URL setelah upload berhasil.
class SyncService {
  SyncService(
    this._db,
    this._client,
    this._userId, {
    CloudinaryService? cloudinary,
  }) : _cloudinary = cloudinary;

  final Database _db;

  /// Boleh null (mis. Supabase tidak dikonfigurasi) — backfill tetap bisa
  /// jalan; push/pull no-op.
  final SupabaseClient? _client;
  final String _userId;
  final CloudinaryService? _cloudinary;

  static const _uuid = Uuid();
  static const int _pageSize = 1000;
  static const int maxUploadAttempts = 5;

  /// Jalankan siklus penuh.
  Future<SyncResult> run() async {
    await backfillUuids();
    final deleted = await pushDeletes();
    final uploaded = await retryUploads();
    final pushed = await push();
    final pulled = await pull();
    await pullTombstones();
    return SyncResult(
      pushed: pushed,
      pulled: pulled,
      deleted: deleted,
      uploaded: uploaded,
    );
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
    final pk = table == 'user_brew_recipes' ? 'recipe_id' : 'id';
    final rows = await txn.query(
      table,
      columns: [pk],
      where: 'uuid IS NULL AND sync_status != ?',
      whereArgs: ['synced'],
    );
    for (final row in rows) {
      await txn.update(
        table,
        {'uuid': _uuid.v4(), 'sync_status': 'pending'},
        where: '$pk = ?',
        whereArgs: [row[pk]],
      );
    }
  }

  /// Kirim tombstone lokal lalu hapus baris cloud. Idempoten: aman diulang.
  Future<int> pushDeletes() async {
    final client = _client;
    if (client == null) return 0;
    final pending = await _db.query('sync_deletes', where: 'synced = 0');
    var deleted = 0;
    for (final row in pending) {
      final uuid = row['uuid'] as String;
      final table = row['table_name'] as String;
      if (!kSyncableTables.contains(table)) continue;
      try {
        await client.from('deleted_records').upsert({
          'uuid': uuid,
          'user_id': _userId,
          'table_name': table,
        });
        await client
            .from(table)
            .delete()
            .eq('uuid', uuid)
            .eq('user_id', _userId);
        await _db.update(
          'sync_deletes',
          {'synced': 1},
          where: 'uuid = ?',
          whereArgs: [uuid],
        );
        deleted++;
      } catch (e) {
        // Biarkan `synced = 0` — dicoba lagi pada siklus berikutnya.
        debugPrint('[Sync] hapus cloud gagal ($table/$uuid): $e');
      }
    }
    return deleted;
  }

  /// Coba ulang upload foto yang tertunda (maks 5 per siklus).
  Future<int> retryUploads() async {
    final cloudinary = _cloudinary;
    if (cloudinary == null) return 0;
    final rows = await _db.query(
      'analyses',
      columns: ['id', 'image_path', 'image_upload_attempts'],
      where: "image_sync_status = 'pending' AND image_upload_attempts < ?",
      whereArgs: [maxUploadAttempts],
      orderBy: 'id ASC',
      limit: 5,
    );
    var uploaded = 0;
    for (final row in rows) {
      final id = row['id'] as int;
      final path = row['image_path'] as String?;
      if (path == null || path.startsWith('http') || !File(path).existsSync()) {
        await _db.update(
          'analyses',
          {'image_sync_status': 'failed'},
          where: 'id = ?',
          whereArgs: [id],
        );
        continue;
      }
      final url = await cloudinary.uploadImage(File(path));
      if (url == null) {
        await _db.rawUpdate(
          "UPDATE analyses SET image_upload_attempts = image_upload_attempts + 1, "
          "image_sync_status = CASE WHEN image_upload_attempts + 1 >= ? "
          "THEN 'failed' ELSE 'pending' END WHERE id = ?",
          [maxUploadAttempts, id],
        );
        continue;
      }
      await _db.update(
        'analyses',
        {
          'image_path': url,
          'cloudinary_public_id': publicIdFromUrl(url),
          'image_sync_status': 'uploaded',
          'image_upload_attempts': 0,
          'sync_status': 'pending',
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      uploaded++;
    }
    return uploaded;
  }

  /// Push semua baris `pending` ke cloud (upsert by uuid), lalu tandai
  /// `synced`. Satu baris gagal tidak menghentikan siklus.
  Future<int> push() async {
    final client = _client;
    if (client == null) return 0;
    var pushed = 0;

    final pending = await _db.query(
      'analyses',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );
    for (final row in pending) {
      // Foto dan data adalah dua jalur independen: `publicImagePath()` sudah
      // mengubah path lokal menjadi null, jadi tidak ada alasan untuk
      // menunda pengiriman baris hanya karena upload foto belum sukses.
      final localId = row['id'] as int;
      final uuid = row['uuid'] as String;
      try {
        final nowIso = DateTime.now().toUtc().toIso8601String();
        final payload = analysisToCloudMap(
          {...row, 'updated_at': nowIso},
          userId: _userId,
        );
        final result = await client
            .from('analyses')
            .upsert(payload)
            .select('updated_at')
            .single();
        await _pushChildren(client, localId, uuid);
        await _db.update(
          'analyses',
          {
            'sync_status': 'synced',
            'updated_at': result['updated_at'],
            'user_id': _userId,
          },
          where: 'id = ?',
          whereArgs: [localId],
        );
        pushed++;
      } catch (e) {
        debugPrint('[Sync] push analyses gagal ($uuid): $e');
      }
    }

    // Resep user — tabel terpisah, tanpa anak.
    final pendingRecipes = await _db.query(
      'user_brew_recipes',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );
    for (final row in pendingRecipes) {
      try {
        final nowIso = DateTime.now().toUtc().toIso8601String();
        final result = await client
            .from('user_brew_recipes')
            .upsert(userRecipeToCloudMap(
              {...row, 'updated_at': nowIso},
              userId: _userId,
            ))
            .select('updated_at')
            .single();
        await _db.update(
          'user_brew_recipes',
          {
            'sync_status': 'synced',
            'updated_at': result['updated_at'],
            'user_id': _userId,
          },
          where: 'recipe_id = ?',
          whereArgs: [row['recipe_id']],
        );
        pushed++;
      } catch (e) {
        debugPrint('[Sync] push resep gagal (${row['uuid']}): $e');
      }
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
      try {
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
      } catch (e) {
        debugPrint('[Sync] push defect gagal: $e');
      }
    }

    final recs = await _db.query(
      'recommendations',
      where: 'analysis_id = ? AND sync_status = ?',
      whereArgs: [localId, 'pending'],
    );
    for (final r in recs) {
      try {
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
      } catch (e) {
        debugPrint('[Sync] push rekomendasi gagal: $e');
      }
    }
  }

  /// Pull baris cloud milik user (paging 1000 baris per halaman).
  Future<int> pull() async {
    final client = _client;
    if (client == null) return 0;
    var pulled = 0;
    pulled += await _pullAnalyses(client);
    pulled += await _pullRecipes(client);
    return pulled;
  }

  Future<int> _pullAnalyses(SupabaseClient client) async {
    var pulled = 0;
    var offset = 0;
    while (true) {
      final batch = await client
          .from('analyses')
          .select()
          .eq('user_id', _userId)
          .order('created_at')
          .range(offset, offset + _pageSize - 1);
      final rows = batch.cast<Map<String, dynamic>>();
      for (final cloud in rows) {
        final uuid = cloud['uuid'] as String?;
        if (uuid == null) continue;
        try {
          final existing = await _db.query(
            'analyses',
            where: 'uuid = ?',
            whereArgs: [uuid],
            limit: 1,
          );
          if (existing.isEmpty) {
            final id = await _db.insert('analyses', cloudToAnalysisRow(cloud));
            await _pullDefects(client, uuid, id);
            await _pullRecommendation(client, uuid, id);
            pulled++;
            continue;
          }
          if (await _mergeAnalysis(existing.first, cloud)) pulled++;
        } catch (e) {
          debugPrint('[Sync] pull analyses gagal ($uuid): $e');
        }
      }
      if (rows.length < _pageSize) break;
      offset += _pageSize;
    }
    return pulled;
  }

  /// Terapkan perubahan cloud ke baris lokal yang sudah ada (LWW).
  Future<bool> _mergeAnalysis(
    Map<String, Object?> local,
    Map<String, dynamic> cloud,
  ) async {
    if (!shouldApplyCloud(local, cloud)) return false;

    final cloudImage = cloud['image_path'] as String?;
    final localImage = local['image_path'] as String?;
    final imageImproves =
        (cloudImage?.startsWith('http') ?? false) &&
        !(localImage?.startsWith('http') ?? false);

    final ratingChanged =
        local['personal_rating'] != cloud['personal_rating'] ||
        local['personal_rating_note'] != cloud['personal_rating_note'];
    if (!ratingChanged && !imageImproves) return false;

    await _db.update(
      'analyses',
      {
        if (ratingChanged) ...{
          'personal_rating': cloud['personal_rating'],
          'personal_rating_note': cloud['personal_rating_note'],
        },
        if (imageImproves) ...{
          'image_path': cloudImage,
          'image_sync_status': 'uploaded',
        },
        'updated_at': cloud['updated_at'],
      },
      where: 'uuid = ?',
      whereArgs: [local['uuid']],
    );
    return true;
  }

  Future<int> _pullRecipes(SupabaseClient client) async {
    var pulled = 0;
    var offset = 0;
    while (true) {
      final batch = await client
          .from('user_brew_recipes')
          .select()
          .eq('user_id', _userId)
          .order('created_at')
          .range(offset, offset + _pageSize - 1);
      final rows = batch.cast<Map<String, dynamic>>();
      for (final cloud in rows) {
        final uuid = cloud['uuid'] as String?;
        if (uuid == null) continue;
        try {
          final existing = await _db.query(
            'user_brew_recipes',
            where: 'uuid = ?',
            whereArgs: [uuid],
            limit: 1,
          );
          if (existing.isEmpty) {
            await _db.insert('user_brew_recipes', cloudToUserRecipeRow(cloud));
            pulled++;
            continue;
          }
          if (!shouldApplyCloud(existing.first, cloud)) continue;
          final update = cloudToUserRecipeRow(cloud)
            ..remove('recipe_id')
            ..remove('uuid')
            ..remove('sync_status');
          await _db.update(
            'user_brew_recipes',
            update,
            where: 'uuid = ?',
            whereArgs: [uuid],
          );
          pulled++;
        } catch (e) {
          debugPrint('[Sync] pull resep gagal ($uuid): $e');
        }
      }
      if (rows.length < _pageSize) break;
      offset += _pageSize;
    }
    return pulled;
  }

  /// Terapkan tombstone cloud: hapus baris lokal yang sudah dihapus user
  /// (dari device mana pun). Idempoten.
  Future<void> pullTombstones() async {
    final client = _client;
    if (client == null) return;
    final rows = await client
        .from('deleted_records')
        .select('uuid, table_name')
        .eq('user_id', _userId);
    for (final r in rows.cast<Map<String, dynamic>>()) {
      final table = r['table_name'] as String?;
      final uuid = r['uuid'] as String?;
      if (table == null || uuid == null) continue;
      if (!kSyncableTables.contains(table)) continue;
      try {
        await _db.delete(table, where: 'uuid = ?', whereArgs: [uuid]);
      } catch (e) {
        debugPrint('[Sync] apply tombstone gagal ($table/$uuid): $e');
      }
    }
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
