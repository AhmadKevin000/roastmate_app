// Uji `QualityEngine` — rumus defect rate berbobot PRD AC-03 & ambang profile.

import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/features/analysis/domain/quality_engine.dart';
import 'package:pbl_sem5/shared/enums/defect_class.dart';
import 'package:pbl_sem5/shared/enums/quality_profile.dart';

void main() {
  group('QualityEngine', () {
    test('defect rate berbobot: 28 biji N24 Q1 B2 S1 → 2.3/28 → skor 92', () {
      final dr = QualityEngine.defectRate(
        const {
          DefectClass.normal: 24,
          DefectClass.quaker: 1,
          DefectClass.broken: 2,
          DefectClass.severe: 1,
        },
        28,
      );
      expect(dr, closeTo(2.3 / 28, 1e-9));
      expect(QualityEngine.qualityScore(dr), 92);
    });

    test('visibleBeans = 0 → defect rate 0.0 (tanpa divide-by-zero)', () {
      expect(QualityEngine.defectRate(const {DefectClass.severe: 1}, 0), 0.0);
      expect(QualityEngine.qualityScore(0.0), 100);
    });

    test('pembulatan: TPL-AR-L (0.7 + 0.6)/28 ≈ 0.0464 → skor 95', () {
      final dr = QualityEngine.defectRate(
        const {
          DefectClass.normal: 25,
          DefectClass.quaker: 1,
          DefectClass.broken: 2,
        },
        28,
      );
      expect(dr, closeTo(1.3 / 28, 1e-9));
      expect(QualityEngine.qualityScore(dr), 95);
    });

    test('kelas defect yang absen dihitung 0', () {
      final dr = QualityEngine.defectRate(
        const {DefectClass.quaker: 2},
        10,
      );
      expect(dr, closeTo(0.14, 1e-9));
    });

    test('ambang profile: 75 → High, 74 → Medium, 60 → Medium, 59 → Low', () {
      expect(QualityEngine.profile(100), QualityProfile.high);
      expect(QualityEngine.profile(75), QualityProfile.high);
      expect(QualityEngine.profile(74), QualityProfile.medium);
      expect(QualityEngine.profile(60), QualityProfile.medium);
      expect(QualityEngine.profile(59), QualityProfile.low);
      expect(QualityEngine.profile(0), QualityProfile.low);
    });
  });
}
