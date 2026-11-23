import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../shared/models/analysis_result.dart';

/// Exception bila tidak ada biji kopi yang terdeteksi.
class NoBeanDetectedException implements Exception {
  const NoBeanDetectedException();

  @override
  String toString() =>
      'NoBeanDetectedException: Tidak ada biji kopi terdeteksi pada gambar';
}

/// Hasil inferensi untuk satu biji.
class PerBeanResult {
  final DefectClass defect;
  final String species;
  final String roast;
  final double defectConfidence;
  final double speciesConfidence;
  final double roastConfidence;
  final Rect normalizedRect;

  const PerBeanResult({
    required this.defect,
    required this.species,
    required this.roast,
    required this.defectConfidence,
    required this.speciesConfidence,
    required this.roastConfidence,
    required this.normalizedRect,
  });
}

/// Detektor biji kopi berbasis TFLite (detector.tflite).
///
/// Ketika model tidak tersedia, kelas ini akan mencatat peringatan dan
/// melakukan **simulasi realistis** agar pipeline tetap berjalan.
class BeanDetector {
  static const String _modelAsset = 'assets/models/detector.tflite';

  /// Minimum confidence untuk dianggap deteksi valid.
  static const double _minConfidence = 0.45;

  /// Simulasi jumlah biji minimum agar tidak trigger NoBeanDetected.
  static const int _mockMinBeans = 15;
  static const int _mockMaxBeans = 32;

  /// Mendeteksi bounding box biji kopi dari gambar.
  ///
  /// Mengembalikan list BeanDetection ternormalisasi (0..1).
  /// Melempar [NoBeanDetectedException] bila tidak ada biji yang terdeteksi.
  Future<List<BeanDetection>> detect(
    Uint8List imageBytes,
    int imageWidth,
    int imageHeight,
  ) async {
    try {
      return await _detectWithModel(imageBytes, imageWidth, imageHeight);
    } catch (e) {
      debugPrint('[BeanDetector] Model tidak tersedia ($_modelAsset): $e');
      debugPrint('[BeanDetector] Menggunakan simulasi deteksi realistis.');
      return _simulateDetections();
    }
  }

  /// Inferensi dengan TFLite (dipanggil bila model tersedia).
  /// Saat ini selalu throw karena model belum ada — dikembangkan bila
  /// file .tflite sudah ditempatkan di assets/models/.
  Future<List<BeanDetection>> _detectWithModel(
    Uint8List imageBytes,
    int imageWidth,
    int imageHeight,
  ) async {
    // TODO(ml-team): Aktifkan bila detector.tflite tersedia:
    //   final interpreter = await Interpreter.fromAsset(_modelAsset);
    //   ... run inference & parse output tensor ...
    throw UnsupportedError('Model $_modelAsset belum tersedia');
  }

  /// Simulasi deteksi biji kopi dengan distribusi grid yang realistis.
  List<BeanDetection> _simulateDetections() {
    final rng = math.Random(DateTime.now().millisecondsSinceEpoch);
    final count = _mockMinBeans + rng.nextInt(_mockMaxBeans - _mockMinBeans);

    final defectWeights = {
      DefectClass.healthy: 0.72,
      DefectClass.broken: 0.10,
      DefectClass.insectDamage: 0.07,
      DefectClass.quaker: 0.06,
      DefectClass.scorched: 0.03,
      DefectClass.foreignMatter: 0.02,
    };

    final detections = <BeanDetection>[];
    final cols = math.sqrt(count.toDouble()).ceil();
    final rows = (count / cols).ceil();

    final cellW = 1.0 / cols;
    final cellH = 1.0 / rows;

    var beanIdx = 0;
    for (int r = 0; r < rows && beanIdx < count; r++) {
      for (int c = 0; c < cols && beanIdx < count; c++) {
        final baseX = c * cellW;
        final baseY = r * cellH;
        final jitterX = (rng.nextDouble() - 0.5) * cellW * 0.3;
        final jitterY = (rng.nextDouble() - 0.5) * cellH * 0.3;

        final beanW = cellW * (0.55 + rng.nextDouble() * 0.25);
        final beanH = cellH * (0.50 + rng.nextDouble() * 0.25);

        final x = (baseX + jitterX).clamp(0.0, 1.0 - beanW);
        final y = (baseY + jitterY).clamp(0.0, 1.0 - beanH);

        final defect = _weightedRandom(defectWeights, rng);
        final confidence = 0.72 + rng.nextDouble() * 0.25;

        detections.add(BeanDetection(
          classLabel: defect,
          normalizedRect: Rect.fromLTWH(x, y, beanW, beanH),
          confidence: confidence,
        ));
        beanIdx++;
      }
    }

    return detections;
  }

  T _weightedRandom<T>(Map<T, double> weights, math.Random rng) {
    final total = weights.values.reduce((a, b) => a + b);
    var roll = rng.nextDouble() * total;
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll <= 0) return entry.key;
    }
    return weights.keys.first;
  }
}

/// Klasifikasi species dan roast level per gambar batch.
///
/// Ketika model tidak tersedia, menggunakan simulasi probabilistik.
class BeanClassifier {
  static const String _speciesAsset = 'assets/models/species.tflite';
  static const String _roastAsset = 'assets/models/roast.tflite';

  /// Confidence minimum; di bawah ini dianggap 'uncertain'.
  static const double _minConfidence = 0.50;

  /// Klasifikasi species (Arabica/Robusta/Mixed) dari gambar.
  Future<({String species, double confidence})> classifySpecies(
    Uint8List imageBytes,
  ) async {
    try {
      return await _speciesWithModel(imageBytes);
    } catch (_) {
      debugPrint('[BeanClassifier] Model $_speciesAsset tidak tersedia — simulasi.');
      return _simulateSpecies();
    }
  }

  /// Klasifikasi roast level dari gambar.
  Future<({String roast, double confidence})> classifyRoast(
    Uint8List imageBytes,
  ) async {
    try {
      return await _roastWithModel(imageBytes);
    } catch (_) {
      debugPrint('[BeanClassifier] Model $_roastAsset tidak tersedia — simulasi.');
      return _simulateRoast();
    }
  }

  Future<({String species, double confidence})> _speciesWithModel(
    Uint8List bytes,
  ) async {
    // TODO(ml-team): implementasi TFLite inference
    throw UnsupportedError('Model $_speciesAsset belum tersedia');
  }

  Future<({String roast, double confidence})> _roastWithModel(
    Uint8List bytes,
  ) async {
    // TODO(ml-team): implementasi TFLite inference
    throw UnsupportedError('Model $_roastAsset belum tersedia');
  }

  ({String species, double confidence}) _simulateSpecies() {
    final rng = math.Random();
    const species = ['Arabica', 'Robusta', 'Mixed'];
    const weights = [0.55, 0.30, 0.15];
    final s = _weightedRandom(species, weights, rng);
    return (species: s, confidence: 0.68 + rng.nextDouble() * 0.25);
  }

  ({String roast, double confidence}) _simulateRoast() {
    final rng = math.Random();
    const roasts = ['Light', 'Medium', 'Dark'];
    const weights = [0.30, 0.50, 0.20];
    final r = _weightedRandom(roasts, weights, rng);
    return (roast: r, confidence: 0.65 + rng.nextDouble() * 0.28);
  }

  T _weightedRandom<T>(List<T> items, List<double> weights, math.Random rng) {
    final total = weights.reduce((a, b) => a + b);
    var roll = rng.nextDouble() * total;
    for (int i = 0; i < items.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return items[i];
    }
    return items.last;
  }
}

