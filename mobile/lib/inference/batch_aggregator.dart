import '../shared/models/analysis_result.dart';
import 'bean_detector.dart';

/// Hasil agregasi dari seluruh biji yang terdeteksi dalam satu foto batch.
class AggregatedResult {
  final Map<DefectClass, int> defectCounts;
  final String species;
  final String roast;
  final int visibleBeans;
  final List<BeanDetection> detections;
  final bool isSpeciesUncertain;
  final bool isRoastUncertain;

  const AggregatedResult({
    required this.defectCounts,
    required this.species,
    required this.roast,
    required this.visibleBeans,
    required this.detections,
    this.isSpeciesUncertain = false,
    this.isRoastUncertain = false,
  });
}

/// Mengagregasi hasil per-biji menjadi satu ringkasan batch.
///
/// Prinsip:
/// - Species & roast ditentukan dari classifier pada gambar penuh (bukan per-biji).
/// - Defect counts dikumpulkan dari setiap BeanDetection.
/// - Confidence < 0.50 → tandai sebagai 'uncertain'.
class BatchAggregator {
  static const double _minConfidenceThreshold = 0.50;

  /// Menggabungkan deteksi biji + klasifikasi species/roast.
  ///
  /// [detections]  — list BeanDetection dari BeanDetector.
  /// [speciesResult] — hasil classifySpecies.
  /// [roastResult]   — hasil classifyRoast.
  AggregatedResult aggregate({
    required List<BeanDetection> detections,
    required ({String species, double confidence}) speciesResult,
    required ({String roast, double confidence}) roastResult,
  }) {
    // Hitung defect counts dari deteksi
    final counts = {for (final c in DefectClass.values) c: 0};
    for (final d in detections) {
      counts[d.classLabel] = (counts[d.classLabel] ?? 0) + 1;
    }

    final isSpeciesUncertain =
        speciesResult.confidence < _minConfidenceThreshold;
    final isRoastUncertain = roastResult.confidence < _minConfidenceThreshold;

    // Bila species uncertain tapi masih bisa baca → tetap pakai, tandai flag
    final species = isSpeciesUncertain ? 'Mixed' : speciesResult.species;

    // Bila roast uncertain → 'Medium' sebagai default aman
    final roast = isRoastUncertain ? 'Medium' : roastResult.roast;

    return AggregatedResult(
      defectCounts: counts,
      species: species,
      roast: roast,
      visibleBeans: detections.length,
      detections: detections,
      isSpeciesUncertain: isSpeciesUncertain,
      isRoastUncertain: isRoastUncertain,
    );
  }
}

