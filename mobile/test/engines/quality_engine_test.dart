import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_sem5/engines/quality_engine.dart';
import 'package:pbl_sem5/inference/batch_aggregator.dart';
import 'package:pbl_sem5/shared/models/analysis_result.dart';

void main() {
  group('QualityEngine Tests', () {
    late QualityEngine engine;

    setUp(() {
      engine = QualityEngine();
    });

    test('Green bean selalu menghasilkan skor cap 40 dan pesan edukasi', () {
      final aggregated = AggregatedResult(
        defectCounts: {for (final c in DefectClass.values) c: 0},
        species: 'Arabica',
        roast: 'Green',
        visibleBeans: 20,
        detections: const [],
      );

      final result = engine.compute(aggregated);
      expect(result.qualityScore, 40);
      expect(result.qualityProfile, QualityProfile.low);
      expect(result.summaryText, contains('green bean'));
    });

    test('Batch tanpa defect mendapatkan skor 100 (Specialty)', () {
      final aggregated = AggregatedResult(
        defectCounts: {
          DefectClass.healthy: 25,
          DefectClass.broken: 0,
          DefectClass.insectDamage: 0,
          DefectClass.quaker: 0,
          DefectClass.scorched: 0,
          DefectClass.foreignMatter: 0,
        },
        species: 'Arabica',
        roast: 'Light',
        visibleBeans: 25,
        detections: const [],
      );

      final result = engine.compute(aggregated);
      expect(result.qualityScore, 100);
      expect(result.qualityProfile, QualityProfile.high);
      expect(result.summaryText, contains('Specialty'));
    });

    test('Pengurangan skor sesuai bobot defect SCAA', () {
      // Base: 100
      // 1 broken (-2) + 1 insectDamage (-5) = -7 -> 93
      // defect rate = 2 / 25 = 8% (di bawah 20%, tidak ada penalti tambahan)
      final aggregated = AggregatedResult(
        defectCounts: {
          DefectClass.healthy: 23,
          DefectClass.broken: 1,
          DefectClass.insectDamage: 1,
          DefectClass.quaker: 0,
          DefectClass.scorched: 0,
          DefectClass.foreignMatter: 0,
        },
        species: 'Arabica',
        roast: 'Medium',
        visibleBeans: 25,
        detections: const [],
      );

      final result = engine.compute(aggregated);
      expect(result.qualityScore, 93);
      expect(result.qualityProfile, QualityProfile.high);
    });

    test('Penalti ekstra bila tingkat defect > 20%', () {
      // 10 healthy, 10 broken (-20) -> defect rate 50% (>20% -> -15)
      // Base: 100 - 20 - 15 = 65
      final aggregated = AggregatedResult(
        defectCounts: {
          DefectClass.healthy: 10,
          DefectClass.broken: 10,
          DefectClass.insectDamage: 0,
          DefectClass.quaker: 0,
          DefectClass.scorched: 0,
          DefectClass.foreignMatter: 0,
        },
        species: 'Robusta',
        roast: 'Dark',
        visibleBeans: 20,
        detections: const [],
      );

      final result = engine.compute(aggregated);
      expect(result.qualityScore, 65);
      expect(result.qualityProfile, QualityProfile.medium);
    });
  });
}
