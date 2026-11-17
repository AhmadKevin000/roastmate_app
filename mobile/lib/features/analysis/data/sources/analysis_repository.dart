import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/entities/analysis_history_item.dart';
import '../../../result/domain/entities/analysis_detail.dart';
import '../../../../shared/models/analysis_result.dart';

/// Referensi rekomendasi yang sudah terikat ke knowledge base.
///
/// [alternativeMethodId] opsional, maksimal satu (D-20).
class RecommendationRef {
  final String methodId;
  final String? recipeId;
  final String? alternativeMethodId;
  final String reason;

  const RecommendationRef({
    required this.methodId,
    this.recipeId,
    this.alternativeMethodId,
    required this.reason,
  });
}

/// Repository riwayat analisis: satu-satunya jalur baca/tulis tabel
/// `analyses` + `analysis_defects` (mirror `DATABASE_SCHEMA.md` §6–§7).
///
/// Catatan D-20:
/// - Deteksi per-biji (bounding box) TIDAK disimpan; [InspectionResult.detections]
///   dari data baru akan kosong saat dibaca kembali.
/// - Rekomendasi hanya disimpan bila [RecommendationRef] diberikan — butuh
///   `method_id` yang valid di `brew_methods` (FK). Jangan mengarang ID.
class AnalysisRepository {
  const AnalysisRepository(this._db);

  final Database _db;

  /// Menyimpan satu sesi analisis (analyses + analysis_defects, dan
  /// recommendations bila [recommendation] diberikan) dalam satu transaksi.
  ///
  /// Mengembalikan `id` baris `analyses` yang baru.
  Future<int> insertResult(
    InspectionResult result, {
    required DateTime createdAt,
    String? imagePath,
    String? annotatedImagePath,
    RecommendationRef? recommendation,
  }) async {
    return _db.transaction((txn) async {
      final distribution = result.roastDistribution;
      final id = await txn.insert('analyses', {
        'created_at': createdAt.toIso8601String(),
        'image_path': imagePath,
        'annotated_image_path': annotatedImagePath,
        'name': result.batchName,
        'batch_label': result.batchLabel,
        'batch_name': result.batchName,
        'model_version': result.modelVersion,
        'species': result.species,
        'roast': result.roast,
        'roast_confidence': result.roastConfidence,
        'roast_distribution':
            distribution == null ? null : jsonEncode(distribution),
        'visible_beans': result.visibleBeans,
        'defect_rate': result.defectRate,
        'shape_uniformity': result.shapeUniformity,
        'size_uniformity': result.sizeUniformity,
        'roast_uniformity': result.roastUniformity,
        'quality_score': result.qualityScore,
        'quality_profile': _profileName(result.qualityProfile),
      });

      final batch = txn.batch();
      for (final entry in result.defectCounts.entries) {
        if (entry.value == 0 && entry.key == DefectClass.normal) continue;
        batch.insert('analysis_defects', {
          'analysis_id': id,
          'defect_class': _defectClassName(entry.key),
          'count': entry.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      if (recommendation != null) {
        batch.insert('recommendations', {
          'analysis_id': id,
          'primary_method_id': recommendation.methodId,
          'primary_recipe_id': recommendation.recipeId,
          'alternative_method_id': recommendation.alternativeMethodId,
          'reason': recommendation.reason,
        });
      }

      await batch.commit(noResult: true);
      return id;
    });
  }

  /// Label batch berikutnya gaya mockup: `Batch #001` (urut dari jumlah
  /// baris `analyses` + 1, 3 digit).
  Future<String> nextBatchLabel() async {
    final count = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM analyses'),
    ) ??
        0;
    return 'Batch #${(count + 1).toString().padLeft(3, '0')}';
  }

  /// Perbarui `image_path` setelah upload Cloudinary sukses (Plan 2).
  Future<void> updateImagePath(int analysisId, String imageUrl) =>
      _db.update(
        'analyses',
        {'image_path': imageUrl},
        where: 'id = ?',
        whereArgs: [analysisId],
      );

  /// Daftar riwayat, terbaru dulu. Filter [species] opsional
  /// (`Arabica` / `Robusta` / `Mixed`).
  Future<List<AnalysisHistoryItem>> getHistory({String? species}) async {
    final rows = await _db.query(
      'analyses',
      where: species == null ? null : 'species = ?',
      whereArgs: species == null ? null : [species],
      orderBy: 'created_at DESC',
    );

    final items = <AnalysisHistoryItem>[];
    for (final row in rows) {
      final id = row['id'] as int;
      final createdAt = DateTime.parse(row['created_at'] as String);
      final defects = await _defectCounts(id);
      items.add(
        AnalysisHistoryItem(
          dateLabel: formatHistoryDate(createdAt),
          detail: _fromRow(row, defects, createdAt),
          imagePath: row['image_path'] as String?,
        ),
      );
    }
    return items;
  }

  /// Satu item riwayat berdasarkan id, atau null bila tidak ada.
  Future<AnalysisHistoryItem?> getById(int id) async {
    final rows = await _db.query(
      'analyses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final createdAt = DateTime.parse(row['created_at'] as String);
    final defects = await _defectCounts(id);
    return AnalysisHistoryItem(
      dateLabel: formatHistoryDate(createdAt),
      detail: _fromRow(row, defects, createdAt),
      imagePath: row['image_path'] as String?,
    );
  }

  /// Detail lengkap satu analisis per id untuk layar Detail Inspeksi
  /// (Plan 3): baris `analyses` + counts defect + foto + rekomendasi
  /// (join knowledge base). Null bila id tidak ada.
  Future<AnalysisDetail?> getDetail(int id) async {
    final rows = await _db.query(
      'analyses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final createdAt = DateTime.parse(row['created_at'] as String);
    final defects = await _defectCounts(id);
    final result = _fromRow(row, defects, createdAt);

    final recRows = await _db.rawQuery('''
      SELECT rec.*,
             pm.method_name  AS primary_method_name,
             pm.subtitle     AS primary_method_subtitle,
             pr.recipe_id    AS primary_recipe_id,
             pr.method_id    AS primary_method_id_r,
             pr.dose_g, pr.water_volume_ml, pr.grind_size,
             pr.temperature_c, pr.brewing_time_s,
             am.method_name  AS alt_method_name,
             am.subtitle     AS alt_method_subtitle,
             ar.dose_g AS a_dose, ar.water_volume_ml AS a_water,
             ar.grind_size AS a_grind,
             ar.temperature_c AS a_temp, ar.brewing_time_s AS a_time
      FROM recommendations rec
      JOIN brew_methods pm ON pm.method_id = rec.primary_method_id
      JOIN brew_recipes pr ON pr.recipe_id = rec.primary_recipe_id
      LEFT JOIN brew_methods am ON am.method_id = rec.alternative_method_id
      LEFT JOIN brew_recipes ar
             ON ar.method_id = rec.alternative_method_id
            AND ar.species = (SELECT species FROM analyses WHERE id = ?)
            AND ar.is_default = 1
      WHERE rec.analysis_id = ?
    ''', [id, id]);

    BrewRecommendation? recommendation;
    List<AlternativeMethod> alternatives = const [];
    if (recRows.isNotEmpty) {
      final recRow = recRows.first;
      recommendation = toBrewRecommendation(recRow);
      alternatives = [?toAlternativeMethod(recRow)];
    }

    return AnalysisDetail(
      analysisId: id,
      result: result,
      imagePath: row['image_path'] as String?,
      recommendation: recommendation,
      alternatives: alternatives,
      summaryText: buildAnalysisSummary(result),
    );
  }

  /// Menghapus satu analisis. Defects & recommendations ikut lewat
  /// `ON DELETE CASCADE`.
  Future<void> deleteAnalysis(int id) async {
    await _db.delete('analyses', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<DefectClass, int>> _defectCounts(int analysisId) async {
    final rows = await _db.query(
      'analysis_defects',
      columns: ['defect_class', 'count'],
      where: 'analysis_id = ?',
      whereArgs: [analysisId],
    );
    final counts = {for (final c in DefectClass.values) c: 0};
    for (final row in rows) {
      final cls = defectClassFromName(row['defect_class'] as String);
      if (cls != null) counts[cls] = row['count'] as int;
    }
    return counts;
  }

  InspectionResult _fromRow(
    Map<String, Object?> row,
    Map<DefectClass, int> defects,
    DateTime createdAt,
  ) {
    final visibleBeans = (row['visible_beans'] as int?) ?? 0;
    final distributionRaw = row['roast_distribution'] as String?;
    Map<String, double>? distribution;
    if (distributionRaw != null && distributionRaw.isNotEmpty) {
      distribution = <String, double>{
        for (final e in (jsonDecode(distributionRaw) as Map<String, dynamic>)
            .entries)
          e.key: (e.value as num).toDouble(),
      };
    }
    return InspectionResult(
      batchLabel: (row['batch_label'] as String?) ?? '-',
      batchName: (row['batch_name'] as String?) ?? 'Tanpa nama',
      analyzedAgo: relativeTimeLabel(createdAt),
      qualityScore: (row['quality_score'] as int?) ?? 0,
      visibleBeans: visibleBeans,
      defectCounts: defects,
      species: (row['species'] as String?) ?? 'Mixed',
      roast: (row['roast'] as String?) ?? 'Green',
      summaryText: '', // tidak disimpan (D-20); diisi engine saat runtime
      recommendation: null, // dibaca terpisah bila perlu (butuh join KB)
      alternatives: const [],
      detections: const [], // per-biji tidak disimpan (D-20)
      modelVersion: (row['model_version'] as String?) ?? '-',
      analysisId: row['id'] as int?,
      shapeUniformity: (row['shape_uniformity'] as num?)?.toDouble() ?? 0,
      sizeUniformity: (row['size_uniformity'] as num?)?.toDouble() ?? 0,
      roastUniformity: (row['roast_uniformity'] as num?)?.toDouble() ?? 0,
      roastConfidence: (row['roast_confidence'] as num?)?.toDouble(),
      roastDistribution: distribution,
    );
  }
}

// ---------------------------------------------------------------------------
// Mapper & label helper (pure, bisa diuji terpisah)
// ---------------------------------------------------------------------------

String _profileName(QualityProfile profile) {
  switch (profile) {
    case QualityProfile.high:
      return 'High';
    case QualityProfile.medium:
      return 'Medium';
    case QualityProfile.low:
      return 'Low';
  }
}

String _defectClassName(DefectClass cls) {
  switch (cls) {
    case DefectClass.normal:
      return 'Normal';
    case DefectClass.quaker:
      return 'Quaker';
    case DefectClass.broken:
      return 'Broken';
    case DefectClass.severe:
      return 'Severe';
  }
}

const List<String> _monthAbbrev = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Format tanggal riwayat gaya mockup: `12 Mar 2025, 10:24 WIB`.
///
/// Waktu ditampilkan dalam zona lokal perangkat; label zona diambil dari
/// offset terhadap UTC.
String formatHistoryDate(DateTime createdAt) {
  final local = createdAt.toLocal();
  final zone = local.timeZoneOffsetInHours == 7
      ? 'WIB'
      : local.timeZoneOffsetInHours == 8
      ? 'WITA'
      : local.timeZoneOffsetInHours == 9
      ? 'WIT'
      : 'UTC+${local.timeZoneOffsetInHours}';
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${_monthAbbrev[local.month - 1]} ${local.year}, '
      '$hh:$mm $zone';
}

/// Label relatif gaya mockup: `Dipindai 12 menit yang lalu`.
String relativeTimeLabel(DateTime createdAt, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(createdAt.toLocal());
  if (diff.inMinutes < 1) return 'Dipindai baru saja';
  if (diff.inMinutes < 60) return 'Dipindai ${diff.inMinutes} menit yang lalu';
  if (diff.inHours < 24) return 'Dipindai ${diff.inHours} jam yang lalu';
  final days = diff.inDays;
  if (days == 1) return 'Dipindai kemarin';
  if (days < 7) return 'Dipindai $days hari yang lalu';
  final weeks = days ~/ 7;
  if (weeks < 5) return 'Dipindai $weeks minggu yang lalu';
  final months = days ~/ 30;
  if (months < 12) return 'Dipindai $months bulan yang lalu';
  return 'Dipindai ${days ~/ 365} tahun yang lalu';
}

extension on DateTime {
  int get timeZoneOffsetInHours => timeZoneOffset.inHours;
}
