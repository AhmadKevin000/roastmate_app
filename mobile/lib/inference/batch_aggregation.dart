/// Agregasi hasil per-biji menjadi metrik batch (pure Dart, mudah diuji).
///
/// Aturan mengikuti `docs/ARCHITECTURE_ML.md` §7–§8:
/// - `defect_rate` = rata-rata *soft expected severity* per biji
///   (dot product distribusi defect ⊗ bobot severity).
/// - Species dengan confidence < 0.70 → `Mixed`.
/// - Roast dengan confidence < 0.45 → ditandai `uncertain` (nilai kelas tetap
///   disimpan agar CHECK kolom `roast` terpenuhi; UI memakai confidence).
library;

import 'dart:math' as math;
import 'dart:ui' show Rect;

import '../shared/enums/defect_class.dart';
import '../shared/models/bean_detection.dart';
import 'model_labels.dart';

/// Prediksi satu biji (hasil deteksi + 3 classifier).
class BeanPrediction {
  const BeanPrediction({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.detectConfidence,
    required this.speciesProbs,
    required this.roastProbs,
    required this.defectProbs,
  });

  /// Kotak ternormalisasi 0..1 pada gambar asli.
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double detectConfidence;

  final List<double> speciesProbs; // 3 kelas
  final List<double> roastProbs; // 4 kelas
  final List<double> defectProbs; // 4 kelas

  double get width => x2 - x1;
  double get height => y2 - y1;
}

/// Ringkasan satu batch.
class BatchSummary {
  const BatchSummary({
    required this.visibleBeans,
    required this.species,
    required this.speciesConfidence,
    required this.roast,
    required this.roastConfidence,
    required this.roastDistribution,
    required this.defectCounts,
    required this.defectRate,
    required this.shapeUniformity,
    required this.sizeUniformity,
    required this.roastUniformity,
    required this.detections,
  });

  final int visibleBeans;

  /// Title Case: `Arabica` / `Liberika` / `Robusta` / `Mixed`.
  final String species;
  final double speciesConfidence;

  /// Title Case: `Green` / `Light` / `Medium` / `Dark`.
  final String roast;

  /// Confidence kelas roast terpilih (0..1) — `< 0.45` = uncertain.
  final double roastConfidence;

  /// `{'Light': 0.8, 'Medium': 0.2}` (fraksi, jumlah ≈ 1).
  final Map<String, double> roastDistribution;

  final Map<DefectClass, int> defectCounts;
  final double defectRate;

  /// Uniformity bentuk (interim: konsistensi rasio aspek bbox).
  final double shapeUniformity;

  /// Uniformity ukuran (interim: konsistensi diameter ekuivalen bbox).
  final double sizeUniformity;

  /// Uniformity roast (pangsa kelas dominan).
  final double roastUniformity;

  final List<BeanDetection> detections;

  /// True bila confidence roast di bawah ambang (`ARCHITECTURE_ML.md` §8).
  bool get roastUncertain => roastConfidence < kRoastConfidenceThreshold;
}

/// Agregasi daftar prediksi biji menjadi [BatchSummary].
BatchSummary aggregateBatch(List<BeanPrediction> beans) {
  if (beans.isEmpty) {
    return const BatchSummary(
      visibleBeans: 0,
      species: kSpeciesMixed,
      speciesConfidence: 0,
      roast: 'Medium',
      roastConfidence: 0,
      roastDistribution: <String, double>{},
      defectCounts: <DefectClass, int>{
        DefectClass.normal: 0,
        DefectClass.quaker: 0,
        DefectClass.broken: 0,
        DefectClass.severe: 0,
      },
      defectRate: 0,
      shapeUniformity: 0,
      sizeUniformity: 0,
      roastUniformity: 0,
      detections: <BeanDetection>[],
    );
  }

  final speciesMeans = _meanProbs(beans.map((b) => b.speciesProbs));
  final roastMeans = _meanProbs(beans.map((b) => b.roastProbs));

  final speciesIndex = _argMax(speciesMeans);
  final speciesConfidence = speciesMeans[speciesIndex];
  final species = speciesConfidence < kSpeciesConfidenceThreshold
      ? kSpeciesMixed
      : displayLabelForIndex(kSpeciesLabels, speciesIndex);

  final roastIndex = _argMax(roastMeans);
  final roastConfidence = roastMeans[roastIndex];
  final roast = displayLabelForIndex(kRoastLabels, roastIndex);

  // Distribusi roast ternormalisasi per kelas tampilan.
  final roastTotal = roastMeans.fold<double>(0, (a, b) => a + b);
  final roastDistribution = <String, double>{};
  for (var i = 0; i < roastMeans.length; i++) {
    final share = roastTotal <= 0 ? 0.0 : roastMeans[i] / roastTotal;
    if (share <= 0) continue;
    roastDistribution[displayLabelForIndex(kRoastLabels, i)] = share;
  }

  // Hitungan defect = argmax per biji (satu biji satu kelas).
  final defectCounts = <DefectClass, int>{
    DefectClass.normal: 0,
    DefectClass.quaker: 0,
    DefectClass.broken: 0,
    DefectClass.severe: 0,
  };
  final detections = <BeanDetection>[];

  for (final bean in beans) {
    final defectIndex = _argMax(bean.defectProbs);
    final defectClass = defectClassForIndex(defectIndex);
    defectCounts[defectClass] = (defectCounts[defectClass] ?? 0) + 1;

    detections.add(
      BeanDetection(
        classLabel: defectClass,
        normalizedRect: Rect.fromLTRB(bean.x1, bean.y1, bean.x2, bean.y2),
        confidence: bean.detectConfidence,
      ),
    );
  }

  // Defect rate = hitungan keras berbobot (rumus identik `QualityEngine`),
  // agar skor di UI konsisten dengan kolom `analyses.defect_rate` (AC-03).
  final defectRate = _hardDefectRate(defectCounts, beans.length);

  return BatchSummary(
    visibleBeans: beans.length,
    species: species,
    speciesConfidence: speciesConfidence,
    roast: roast,
    roastConfidence: roastConfidence,
    roastDistribution: roastDistribution,
    defectCounts: defectCounts,
    defectRate: defectRate,
    shapeUniformity: _aspectUniformity(beans),
    sizeUniformity: _sizeUniformity(beans),
    roastUniformity: roastConfidence,
    detections: detections,
  );
}

/// Uniformity bentuk interim — 1 − CV rasio aspek bbox (0..1).
///
/// Interim sampai Shape Analysis OpenCV tersedia (`ARCHITECTURE_ML.md` §6).
double _aspectUniformity(List<BeanPrediction> beans) {
  final values = <double>[];
  for (final b in beans) {
    if (b.height <= 0) continue;
    values.add(b.width / b.height);
  }
  return _uniformityFromCv(values);
}

/// Uniformity ukuran interim — 1 − CV diameter ekuivalen bbox (0..1).
double _sizeUniformity(List<BeanPrediction> beans) {
  final values = <double>[
    for (final b in beans) math.sqrt((b.width * b.height).abs()),
  ];
  return _uniformityFromCv(values);
}

/// `1 − CV`, di-clamp 0..1 (CV = std/mean).
double _uniformityFromCv(List<double> values) {
  if (values.length < 2) return 0;
  final mean = values.reduce((a, b) => a + b) / values.length;
  if (mean <= 0) return 0;
  final variance =
      values.fold<double>(0, (sum, v) => sum + (v - mean) * (v - mean)) /
      values.length;
  final cv = math.sqrt(variance) / mean;
  return (1 - cv).clamp(0.0, 1.0);
}

List<double> _meanProbs(Iterable<List<double>> all) {
  final list = all.toList(growable: false);
  if (list.isEmpty) return const <double>[];
  final length = list.first.length;
  final means = List<double>.filled(length, 0);
  for (final probs in list) {
    for (var i = 0; i < length; i++) {
      means[i] += probs[i];
    }
  }
  for (var i = 0; i < length; i++) {
    means[i] /= list.length;
  }
  return means;
}

int _argMax(List<double> values) {
  var best = 0;
  for (var i = 1; i < values.length; i++) {
    if (values[i] > values[best]) best = i;
  }
  return best;
}

/// Defect rate berbobot dari hitungan keras (identik `QualityEngine`).
double _hardDefectRate(Map<DefectClass, int> counts, int visibleBeans) {
  if (visibleBeans <= 0) return 0;
  var weighted = 0.0;
  for (final entry in counts.entries) {
    weighted += entry.value * _severityWeight(entry.key);
  }
  return weighted / visibleBeans;
}

double _severityWeight(DefectClass defectClass) {
  switch (defectClass) {
    case DefectClass.normal:
      return 0.0;
    case DefectClass.quaker:
      return 0.7;
    case DefectClass.broken:
      return 0.3;
    case DefectClass.severe:
      return 1.0;
  }
}
