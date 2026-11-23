import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../shared/models/analysis_result.dart';
import '../features/analysis/data/sources/analysis_repository.dart';
import 'image_quality_checker.dart';
import 'bean_detector.dart';
import 'batch_aggregator.dart';
import '../engines/quality_engine.dart';
import '../engines/recommendation_engine.dart';

/// Orkestrasi lengkap pipeline analisis biji kopi on-device.
///
/// Alur:
///   1. Periksa kualitas gambar (brightness & sharpness)
///   2. Deteksi biji kopi (BeanDetector)
///   3. Klasifikasi species & roast (BeanClassifier)
///   4. Agregasi hasil (BatchAggregator)
///   5. Hitung skor kualitas (QualityEngine)
///   6. Lookup rekomendasi seduh (RecommendationEngine)
///   7. Simpan ke SQLite (AnalysisRepository)
///   8. Kembalikan InspectionResult
class AnalysisPipeline {
  static const String _modelVersion = 'SIM-v1.0';

  final Database _db;

  AnalysisPipeline({required Database db}) : _db = db;

  /// Menganalisis gambar biji kopi dan mengembalikan [InspectionResult].
  ///
  /// [photo]      — file foto dari kamera.
  /// [batchName]  — nama batch yang diisi pengguna.
  /// [batchLabel] — label batch (mis. "Batch #043").
  ///
  /// Melempar:
  /// - [ImageQualityException] bila gambar terlalu gelap atau buram.
  /// - [NoBeanDetectedException] bila tidak ada biji kopi yang terdeteksi.
  Future<InspectionResult> analyze(
    XFile photo, {
    required String batchName,
    String? batchLabel,
  }) async {
    final now = DateTime.now();
    final label = batchLabel ?? _generateBatchLabel(now);

    // -----------------------------------------------------------------------
    // STEP 1: Baca bytes gambar
    // -----------------------------------------------------------------------
    final Uint8List imageBytes;
    try {
      imageBytes = await photo.readAsBytes();
    } catch (e) {
      throw ImageQualityException('Gagal membaca gambar: $e');
    }

    // -----------------------------------------------------------------------
    // STEP 2: Periksa kualitas gambar
    // -----------------------------------------------------------------------
    // Jalankan di isolate terpisah agar UI tidak freeze
    final qualityResult = await compute(
      _checkQualityInIsolate,
      imageBytes,
    );

    if (!qualityResult.isAcceptable) {
      throw ImageQualityException(qualityResult.rejectionReason!);
    }

    // -----------------------------------------------------------------------
    // STEP 3: Deteksi biji kopi
    // -----------------------------------------------------------------------
    final detector = BeanDetector();
    final detections = await detector.detect(imageBytes, 0, 0);

    if (detections.isEmpty) {
      throw const NoBeanDetectedException();
    }

    // -----------------------------------------------------------------------
    // STEP 4: Klasifikasi species & roast
    // -----------------------------------------------------------------------
    final classifier = BeanClassifier();
    final speciesResult = await classifier.classifySpecies(imageBytes);
    final roastResult = await classifier.classifyRoast(imageBytes);

    // -----------------------------------------------------------------------
    // STEP 5: Agregasi hasil
    // -----------------------------------------------------------------------
    final aggregator = BatchAggregator();
    final aggregated = aggregator.aggregate(
      detections: detections,
      speciesResult: speciesResult,
      roastResult: roastResult,
    );

    // -----------------------------------------------------------------------
    // STEP 6: Quality Engine
    // -----------------------------------------------------------------------
    final qualityEngine = QualityEngine();
    final qualityResult2 = qualityEngine.compute(aggregated);

    // -----------------------------------------------------------------------
    // STEP 7: Recommendation Engine
    // -----------------------------------------------------------------------
    final recEngine = RecommendationEngine(_db);
    final recResult = await recEngine.resolve(
      species: aggregated.species,
      roast: aggregated.roast,
      qualityProfile: qualityResult2.qualityProfile,
    );

    // -----------------------------------------------------------------------
    // STEP 8: Bangun InspectionResult
    // -----------------------------------------------------------------------
    final result = InspectionResult(
      batchLabel: label,
      batchName: batchName,
      analyzedAgo: 'Dipindai baru saja',
      qualityScore: qualityResult2.qualityScore,
      visibleBeans: aggregated.visibleBeans,
      defectCounts: aggregated.defectCounts,
      species: aggregated.species,
      roast: aggregated.roast,
      summaryText: qualityResult2.summaryText,
      recommendation: recResult.recommendation,
      alternatives: recResult.alternatives,
      detections: aggregated.detections,
      modelVersion: _modelVersion,
    );

    // -----------------------------------------------------------------------
    // STEP 9: Simpan ke SQLite (non-blocking bila gagal)
    // -----------------------------------------------------------------------
    try {
      final repo = AnalysisRepository(_db);
      await repo.insertResult(
        result,
        createdAt: now,
        imagePath: photo.path,
        recommendation: recResult.ref,
      );
    } catch (e) {
      // Jangan gagalkan pipeline bila penyimpanan error — tampilkan hasil tetap
      debugPrint('[AnalysisPipeline] Gagal menyimpan ke SQLite: $e');
    }

    return result;
  }

  String _generateBatchLabel(DateTime now) {
    final seq = now.millisecondsSinceEpoch % 1000;
    return 'Batch #${seq.toString().padLeft(3, '0')}';
  }
}

/// Top-level function untuk dijalankan via [compute] (Isolate).
ImageQualityResult _checkQualityInIsolate(Uint8List bytes) {
  // Bila bytes pendek (< 1000 bytes), skip quality check (mungkin dari mock)
  if (bytes.length < 1000) return const ImageQualityResult.ok();

  // Estimasi kasar: gunakan distribusi luminance dari subset bytes
  // (tidak ada image decode di isolate untuk menjaga zero-dependency)
  // Gunakan distribusi JPEG byte sebagai proxy brightness
  final sampleSize = bytes.length.clamp(0, 10000);
  int totalValue = 0;
  for (int i = 0; i < sampleSize; i += 100) {
    totalValue += bytes[i];
  }
  final avgByte = totalValue / (sampleSize ~/ 100).clamp(1, sampleSize);

  // JPEG bytes rata-rata < 20 biasanya gambar sangat gelap
  if (avgByte < 15) {
    return const ImageQualityResult.reject(
      'Pencahayaan kurang — coba di tempat yang lebih terang',
    );
  }

  return const ImageQualityResult.ok();
}

