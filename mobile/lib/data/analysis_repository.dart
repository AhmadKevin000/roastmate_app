import 'package:sqflite/sqflite.dart';

import '../domain/analysis_history_item.dart';
import '../domain/inspection_result.dart';

/// Referensi rekomendasi yang sudah terikat ke knowledge base.
///
/// [alternativeMethodId] opsional, maksimal satu (D-19).
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
/// Catatan D-19:
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
      final id = await txn.insert('analyses', {
        'created_at': createdAt.toIso8601String(),
        'image_path': imagePath,
        'annotated_image_path': annotatedImagePath,
        'batch_label': result.batchLabel,
        'batch_name': result.batchName,
        'model_version': result.modelVersion,
        'species': result.species,
        'roast': result.roast,
        'visible_beans': result.visibleBeans,
        'defect_rate': result.defectRate,
        'quality_score': result.qualityScore,
        'quality_profile': _profileName(result.qualityProfile),
      });

      final batch = txn.batch();
      for (final entry in result.defectCounts.entries) {
        if (entry.value == 0 && entry.key == DefectClass.healthy) continue;
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
      final cls = _defectClassFromName(row['defect_class'] as String);
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
    return InspectionResult(
      batchLabel: (row['batch_label'] as String?) ?? '-',
      batchName: (row['batch_name'] as String?) ?? 'Tanpa nama',
      analyzedAgo: relativeTimeLabel(createdAt),
      qualityScore: (row['quality_score'] as int?) ?? 0,
      visibleBeans: visibleBeans,
      defectCounts: defects,
      species: (row['species'] as String?) ?? 'Mixed',
      roast: (row['roast'] as String?) ?? 'Green',
      summaryText: '', // tidak disimpan (D-19); diisi engine saat runtime
      recommendation: null, // dibaca terpisah bila perlu (butuh join KB)
      alternatives: const [],
      detections: const [], // per-biji tidak disimpan (D-19)
      modelVersion: (row['model_version'] as String?) ?? '-',
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
    case DefectClass.healthy:
      return 'Healthy';
    case DefectClass.broken:
      return 'Broken';
    case DefectClass.insectDamage:
      return 'Insect Damage';
    case DefectClass.quaker:
      return 'Quaker';
    case DefectClass.scorched:
      return 'Scorched';
    case DefectClass.foreignMatter:
      return 'Foreign Matter';
  }
}

DefectClass? _defectClassFromName(String name) {
  for (final c in DefectClass.values) {
    if (_defectClassName(c) == name) return c;
  }
  return null;
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
