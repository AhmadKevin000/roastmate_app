import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_sem5/inference/batch_aggregation.dart';
import 'package:pbl_sem5/inference/model_labels.dart';
import 'package:pbl_sem5/shared/enums/defect_class.dart';

/// Biji sintetis: kotak 20×10 (rasio aspek 2) di posisi berbeda.
BeanPrediction _bean({
  required List<double> species,
  required List<double> roast,
  required List<double> defect,
  double x = 0.1,
  double y = 0.1,
  double w = 0.2,
  double h = 0.1,
}) {
  return BeanPrediction(
    x1: x,
    y1: y,
    x2: x + w,
    y2: y + h,
    detectConfidence: 0.9,
    speciesProbs: species,
    roastProbs: roast,
    defectProbs: defect,
  );
}

void main() {
  group('aggregateBatch — species', () {
    test('memakai kelas dominan bila confidence ≥ 0.70', () {
      final summary = aggregateBatch([
        _bean(
          species: const [0.9, 0.05, 0.05],
          roast: const [0, 1, 0, 0],
          defect: const [1, 0, 0, 0],
        ),
        _bean(
          species: const [0.8, 0.1, 0.1],
          roast: const [0, 1, 0, 0],
          defect: const [1, 0, 0, 0],
        ),
      ]);

      expect(summary.species, 'Arabica');
      expect(summary.speciesConfidence, closeTo(0.85, 1e-9));
    });

    test('menjadi Mixed bila confidence < 0.70', () {
      final summary = aggregateBatch([
        _bean(
          species: const [0.4, 0.3, 0.3],
          roast: const [0, 1, 0, 0],
          defect: const [1, 0, 0, 0],
        ),
      ]);

      expect(summary.species, kSpeciesMixed);
    });
  });

  group('aggregateBatch — roast', () {
    test('menyimpan kelas dominan + confidence + distribusi', () {
      final summary = aggregateBatch([
        _bean(
          species: const [1, 0, 0],
          roast: const [0, 0.8, 0.2, 0],
          defect: const [1, 0, 0, 0],
        ),
      ]);

      expect(summary.roast, 'Light');
      expect(summary.roastConfidence, closeTo(0.8, 1e-9));
      expect(summary.roastUncertain, isFalse);
      expect(summary.roastDistribution['Light'], closeTo(0.8, 1e-9));
      expect(summary.roastDistribution['Medium'], closeTo(0.2, 1e-9));
    });

    test('roastUncertain true bila confidence < 0.45', () {
      final summary = aggregateBatch([
        _bean(
          species: const [1, 0, 0],
          roast: const [0, 0.40, 0.35, 0.25],
          defect: const [1, 0, 0, 0],
        ),
      ]);

      expect(summary.roast, 'Light');
      expect(summary.roastUncertain, isTrue);
    });
  });

  group('aggregateBatch — defect', () {
    test('menghitung per kelas dari argmax dan defect rate berbobot', () {
      final summary = aggregateBatch([
        _bean(
          species: const [1, 0, 0],
          roast: const [0, 1, 0, 0],
          defect: const [1, 0, 0, 0],
        ),
        _bean(
          species: const [1, 0, 0],
          roast: const [0, 1, 0, 0],
          defect: const [0, 1, 0, 0],
        ),
        _bean(
          species: const [1, 0, 0],
          roast: const [0, 1, 0, 0],
          defect: const [0, 0, 0, 1],
        ),
        _bean(
          species: const [1, 0, 0],
          roast: const [0, 1, 0, 0],
          defect: const [0, 0, 1, 0],
        ),
      ]);

      expect(summary.visibleBeans, 4);
      expect(summary.defectCounts[DefectClass.normal], 1);
      expect(summary.defectCounts[DefectClass.quaker], 1);
      expect(summary.defectCounts[DefectClass.severe], 1);
      expect(summary.defectCounts[DefectClass.broken], 1);

      // (0 + 0.7 + 1.0 + 0.3) / 4 = 0.5
      expect(summary.defectRate, closeTo(0.5, 1e-9));
    });

    test('defect rate 0 bila semua normal', () {
      final summary = aggregateBatch([
        _bean(
          species: const [1, 0, 0],
          roast: const [0, 1, 0, 0],
          defect: const [1, 0, 0, 0],
        ),
      ]);

      expect(summary.defectRate, 0);
    });
  });

  group('aggregateBatch — uniformity', () {
    test('uniformity 1 bila semua biji identik bentuk & ukuran', () {
      final summary = aggregateBatch([
        _bean(
          species: const [1, 0, 0],
          roast: const [0, 1, 0, 0],
          defect: const [1, 0, 0, 0],
        ),
        _bean(
          species: const [1, 0, 0],
          roast: const [0, 1, 0, 0],
          defect: const [1, 0, 0, 0],
          x: 0.5,
        ),
      ]);

      expect(summary.shapeUniformity, closeTo(1, 1e-9));
      expect(summary.sizeUniformity, closeTo(1, 1e-9));
    });

    test('uniformity turun bila bentuk biji beragam', () {
      final summary = aggregateBatch([
        _bean(
          species: const [1, 0, 0],
          roast: const [0, 1, 0, 0],
          defect: const [1, 0, 0, 0],
          w: 0.2,
          h: 0.1,
        ),
        _bean(
          species: const [1, 0, 0],
          roast: const [0, 1, 0, 0],
          defect: const [1, 0, 0, 0],
          w: 0.1,
          h: 0.2,
        ),
      ]);

      expect(summary.shapeUniformity, lessThan(1));
      expect(summary.shapeUniformity, greaterThanOrEqualTo(0));
    });
  });

  group('aggregateBatch — kasus kosong', () {
    test('tidak melempar dan mengembalikan nilai netral', () {
      final summary = aggregateBatch(const []);

      expect(summary.visibleBeans, 0);
      expect(summary.species, kSpeciesMixed);
      expect(summary.defectRate, 0);
      expect(summary.detections, isEmpty);
    });
  });

  group('detections', () {
    test('membawa kotak ternormalisasi + kelas defect per biji', () {
      final summary = aggregateBatch([
        _bean(
          species: const [1, 0, 0],
          roast: const [0, 1, 0, 0],
          defect: const [0, 0, 1, 0],
          x: 0.25,
          y: 0.5,
          w: 0.2,
          h: 0.1,
        ),
      ]);

      final detection = summary.detections.single;
      expect(detection.classLabel, DefectClass.broken);
      expect(detection.normalizedRect.left, closeTo(0.25, 1e-9));
      expect(detection.normalizedRect.bottom, closeTo(0.6, 1e-9));
    });
  });
}
