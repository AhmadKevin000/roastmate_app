import 'dart:ui';
import 'package:sqflite/sqflite.dart';
import '../../domain/inspection_result.dart';
import '../database/app_database.dart';

class AnalysisRepository {
  final AppDatabase _appDatabase;

  AnalysisRepository({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db async => await _appDatabase.database;

  /// Menyimpan hasil analisis inspeksi lengkap ke SQLite dalam satu transaksi.
  Future<int> saveInspection(InspectionResult result) async {
    final db = await _db;
    final now = result.createdAt ?? DateTime.now();

    return await db.transaction<int>((txn) async {
      // 1. Simpan Header Analisis
      final analysisId = await txn.insert(
        'analyses',
        {
          'batch_label': result.batchLabel,
          'batch_name': result.batchName,
          'created_at': now.toIso8601String(),
          'image_path': result.imagePath,
          'species': result.species,
          'roast': result.roast,
          'visible_beans': result.visibleBeans,
          'defect_rate': result.defectRate,
          'quality_score': result.qualityScore,
          'quality_profile': result.qualityProfile.name,
          'grade': result.grade.name,
          'summary_text': result.summaryText,
          'model_version': result.modelVersion,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Simpan Rincian Defect per Kelas
      for (final entry in result.defectCounts.entries) {
        await txn.insert(
          'analysis_defects',
          {
            'analysis_id': analysisId,
            'defect_class': entry.key.name,
            'count': entry.value,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 3. Simpan Bounding Box Deteksi Biji
      for (final d in result.detections) {
        await txn.insert(
          'bean_detections',
          {
            'analysis_id': analysisId,
            'class_label': d.classLabel.name,
            'rect_left': d.normalizedRect.left,
            'rect_top': d.normalizedRect.top,
            'rect_width': d.normalizedRect.width,
            'rect_height': d.normalizedRect.height,
            'confidence': d.confidence,
          },
        );
      }

      // 4. Simpan Rekomendasi Seduh (jika ada)
      if (result.recommendation != null) {
        final rec = result.recommendation!;
        await txn.insert(
          'recommendations',
          {
            'analysis_id': analysisId,
            'method_title': rec.methodTitle,
            'reason_text': rec.reasonText,
            'ratio': rec.ratio,
            'ratio_sub': rec.ratioSub,
            'temp_c': rec.tempC,
            'temp_c_sub': rec.tempCSub,
            'grind': rec.grind,
            'grind_sub': rec.grindSub,
            'target_time': rec.targetTime,
            'target_time_sub': rec.targetTimeSub,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 5. Simpan Opsi Metode Alternatif
      for (final alt in result.alternatives) {
        await txn.insert(
          'alternative_methods',
          {
            'analysis_id': analysisId,
            'title': alt.title,
            'description': alt.description,
          },
        );
      }

      return analysisId;
    });
  }

  /// Mengambil data inspeksi lengkap berdasarkan ID analisis.
  Future<InspectionResult?> getInspectionById(int id) async {
    final db = await _db;

    final analysisRows = await db.query(
      'analyses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (analysisRows.isEmpty) return null;
    final row = analysisRows.first;

    // Ambil defects
    final defectRows = await db.query(
      'analysis_defects',
      where: 'analysis_id = ?',
      whereArgs: [id],
    );
    final Map<DefectClass, int> defectCounts = {
      for (var d in DefectClass.values) d: 0,
    };
    for (final dRow in defectRows) {
      final className = dRow['defect_class'] as String;
      final count = dRow['count'] as int;
      final match = DefectClass.values.firstWhere(
        (e) => e.name == className,
        orElse: () => DefectClass.healthy,
      );
      defectCounts[match] = count;
    }

    // Ambil detections
    final detectionRows = await db.query(
      'bean_detections',
      where: 'analysis_id = ?',
      whereArgs: [id],
    );
    final detections = detectionRows.map((dRow) {
      final className = dRow['class_label'] as String;
      final match = DefectClass.values.firstWhere(
        (e) => e.name == className,
        orElse: () => DefectClass.healthy,
      );
      final left = (dRow['rect_left'] as num).toDouble();
      final top = (dRow['rect_top'] as num).toDouble();
      final width = (dRow['rect_width'] as num).toDouble();
      final height = (dRow['rect_height'] as num).toDouble();
      final confidence = (dRow['confidence'] as num).toDouble();

      return BeanDetection(
        classLabel: match,
        normalizedRect: Rect.fromLTWH(left, top, width, height),
        confidence: confidence,
      );
    }).toList();

    // Ambil rekomendasi
    final recRows = await db.query(
      'recommendations',
      where: 'analysis_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    BrewRecommendation? recommendation;
    if (recRows.isNotEmpty) {
      final r = recRows.first;
      recommendation = BrewRecommendation(
        methodTitle: r['method_title'] as String,
        reasonText: r['reason_text'] as String,
        ratio: r['ratio'] as String,
        ratioSub: r['ratio_sub'] as String,
        tempC: r['temp_c'] as String,
        tempCSub: r['temp_c_sub'] as String,
        grind: r['grind'] as String,
        grindSub: r['grind_sub'] as String,
        targetTime: r['target_time'] as String,
        targetTimeSub: r['target_time_sub'] as String,
      );
    }

    // Ambil alternatif
    final altRows = await db.query(
      'alternative_methods',
      where: 'analysis_id = ?',
      whereArgs: [id],
    );
    final alternatives = altRows.map((a) {
      return AlternativeMethod(
        title: a['title'] as String,
        description: a['description'] as String,
      );
    }).toList();

    final createdAtStr = row['created_at'] as String;
    final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();

    return InspectionResult(
      id: id,
      batchLabel: (row['batch_label'] as String?) ?? 'Batch #${id.toString().padLeft(3, '0')}',
      batchName: (row['batch_name'] as String?) ?? 'Analisis Biji',
      analyzedAgo: _formatRelativeTime(createdAt),
      createdAt: createdAt,
      imagePath: row['image_path'] as String?,
      qualityScore: row['quality_score'] as int? ?? 0,
      visibleBeans: row['visible_beans'] as int? ?? 0,
      defectCounts: defectCounts,
      species: (row['species'] as String?) ?? 'Arabica',
      roast: (row['roast'] as String?) ?? 'Medium',
      summaryText: (row['summary_text'] as String?) ?? '',
      recommendation: recommendation,
      alternatives: alternatives,
      detections: detections,
      modelVersion: (row['model_version'] as String?) ?? 'Model CV v1.0',
    );
  }

  /// Mengambil semua analisis (diurutkan dari yang terbaru).
  Future<List<InspectionResult>> getAllInspections() async {
    final db = await _db;
    final rows = await db.query(
      'analyses',
      orderBy: 'created_at DESC',
    );

    final List<InspectionResult> results = [];
    for (final row in rows) {
      final id = row['id'] as int;
      final fullResult = await getInspectionById(id);
      if (fullResult != null) {
        results.add(fullResult);
      }
    }
    return results;
  }

  /// Menghapus satu analisis beserta seluruh anak relasinya.
  Future<int> deleteInspection(int id) async {
    final db = await _db;
    return await db.delete('analyses', where: 'id = ?', whereArgs: [id]);
  }

  /// Menghitung total data analisis tersimpan.
  Future<int> countInspections() async {
    final db = await _db;
    final res = await db.rawQuery('SELECT COUNT(*) as total FROM analyses');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  /// Memastikan data awal ada di database (auto-seed untuk kemudahan testing on-device).
  Future<void> ensureSeedData(InspectionResult defaultSample) async {
    final count = await countInspections();
    if (count == 0) {
      await saveInspection(defaultSample);
    }
  }

  static String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return 'Dipindai ${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return 'Dipindai ${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return 'Dipindai ${difference.inDays} hari yang lalu';
    } else {
      return 'Dipindai pada ${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

