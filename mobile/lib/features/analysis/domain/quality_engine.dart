/// Engine penilai kualitas batch berdasarkan taksonomi defect 4 kelas.
///
/// Rumus mengikuti PRD AC-03 (defect rate **berbobot**):
/// `dr = Σ(count[c] × weight[c]) / n`, `score = round(100 × (1 − dr))`.
/// Ambang profil (keputusan desain, PRD §8): High ≥ 75 · Medium ≥ 60 · Low < 60.
///
/// Pure & stateless — tanpa dependensi DB/network sehingga mudah diuji.
library;

import '../../../../shared/enums/defect_class.dart';
import '../../../../shared/enums/quality_profile.dart';

class QualityEngine {
  /// Bobot keparahan per kelas defect (PRD AC-03).
  static const Map<DefectClass, double> severityWeight = {
    DefectClass.normal: 0.0,
    DefectClass.quaker: 0.7,
    DefectClass.broken: 0.3,
    DefectClass.severe: 1.0,
  };

  /// Defect rate berbobot (0.0–1.0).
  ///
  /// [counts] boleh kurang dari 4 kelas (kelas tak ada dianggap 0).
  /// `visibleBeans == 0` → 0.0.
  static double defectRate(Map<DefectClass, int> counts, int visibleBeans) =>
      visibleBeans == 0
          ? 0.0
          : counts.entries
                  .fold<double>(
                    0,
                    (sum, e) => sum + e.value * severityWeight[e.key]!,
                  ) /
                  visibleBeans;

  /// Skor kualitas 0–100 dari [defectRate].
  static int qualityScore(double defectRate) => (100 * (1 - defectRate)).round();

  /// Ambang profil kualitas: High ≥ 75 · Medium ≥ 60 · Low < 60.
  static QualityProfile profile(int score) {
    if (score >= 75) return QualityProfile.high;
    if (score >= 60) return QualityProfile.medium;
    return QualityProfile.low;
  }
}
