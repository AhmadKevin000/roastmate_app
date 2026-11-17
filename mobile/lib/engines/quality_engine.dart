import '../shared/models/analysis_result.dart';
import '../inference/batch_aggregator.dart';

/// Hasil dari Quality Engine.
class QualityEngineResult {
  final int qualityScore;
  final String summaryText;
  final QualityProfile qualityProfile;

  const QualityEngineResult({
    required this.qualityScore,
    required this.summaryText,
    required this.qualityProfile,
  });
}

/// Engine penentu skor kualitas batch biji kopi berdasarkan aturan (rule-based).
///
/// Skor kualitas TIDAK berasal langsung dari prediksi ML, melainkan dari
/// aturan yang diturunkan dari standar SCAA (SCA Arabica Defects Table).
///
/// Prinsip deduct:
/// - Base score: 100
/// - broken:       -2 poin per biji
/// - insectDamage: -5 poin per biji
/// - quaker:       -3 poin per biji
/// - scorched:     -4 poin per biji
/// - foreignMatter:-6 poin per biji
/// - Defect rate > 20%: tambahan -15 poin
/// - Green bean (roast == Green): cap 40, pesan khusus
class QualityEngine {
  static const int _baseScore = 100;

  // Poin deduct per defect class (per biji)
  static const Map<DefectClass, int> _deductPerBean = {
    DefectClass.healthy: 0,
    DefectClass.broken: 2,
    DefectClass.insectDamage: 5,
    DefectClass.quaker: 3,
    DefectClass.scorched: 4,
    DefectClass.foreignMatter: 6,
  };

  static const double _highDefectRateThreshold = 0.20;
  static const int _highDefectRateDeduct = 15;
  static const int _greenBeanScoreCap = 40;

  QualityEngineResult compute(AggregatedResult aggregated) {
    final defectCounts = aggregated.defectCounts;
    final visibleBeans = aggregated.visibleBeans;
    final roast = aggregated.roast;

    // Biji mentah (green bean) — tidak bisa diseduh, return langsung
    if (roast.toLowerCase() == 'green') {
      return QualityEngineResult(
        qualityScore: _greenBeanScoreCap,
        summaryText:
            'Biji masih mentah (green bean), belum melalui proses roasting. '
            'Tidak dapat memberikan rekomendasi seduh.',
        qualityProfile: QualityProfile.low,
      );
    }

    if (visibleBeans == 0) {
      return const QualityEngineResult(
        qualityScore: 0,
        summaryText: 'Tidak ada biji yang terdeteksi.',
        qualityProfile: QualityProfile.low,
      );
    }

    // Hitung total poin deduct
    int totalDeduct = 0;
    int defectBeans = 0;
    for (final entry in defectCounts.entries) {
      if (entry.key == DefectClass.healthy) continue;
      final deduct = (_deductPerBean[entry.key] ?? 0) * entry.value;
      totalDeduct += deduct;
      defectBeans += entry.value;
    }

    // Tambahan penalti bila defect rate > 20%
    final defectRate = defectBeans / visibleBeans;
    if (defectRate > _highDefectRateThreshold) {
      totalDeduct += _highDefectRateDeduct;
    }

    int score = (_baseScore - totalDeduct).clamp(0, 100);

    // Tentukan quality profile
    final QualityProfile profile;
    if (score >= 75) {
      profile = QualityProfile.high;
    } else if (score >= 60) {
      profile = QualityProfile.medium;
    } else {
      profile = QualityProfile.low;
    }

    // Buat teks ringkasan
    final summaryText = _buildSummary(
      score: score,
      defectRate: defectRate,
      defectBeans: defectBeans,
      visibleBeans: visibleBeans,
      roast: roast,
      species: aggregated.species,
      isSpeciesUncertain: aggregated.isSpeciesUncertain,
    );

    return QualityEngineResult(
      qualityScore: score,
      summaryText: summaryText,
      qualityProfile: profile,
    );
  }

  String _buildSummary({
    required int score,
    required double defectRate,
    required int defectBeans,
    required int visibleBeans,
    required String roast,
    required String species,
    required bool isSpeciesUncertain,
  }) {
    final defectPercent = (defectRate * 100).round();
    final speciesLabel =
        isSpeciesUncertain ? 'campuran (tidak pasti)' : species;
    final roastLabel = _roastLabel(roast);

    if (score >= 85) {
      return 'Kualitas Specialty — $speciesLabel $roastLabel dengan tingkat defect '
          'sangat rendah ($defectPercent%). Sangat direkomendasikan untuk '
          'metode seduh single origin.';
    } else if (score >= 75) {
      return 'Kualitas Premium — $speciesLabel $roastLabel. Sebagian besar biji '
          'dalam kondisi baik ($defectBeans dari $visibleBeans biji berdefect). '
          'Cocok untuk berbagai metode seduh.';
    } else if (score >= 60) {
      return 'Kualitas Standar — $speciesLabel $roastLabel. Terdapat $defectBeans '
          'biji berdefect ($defectPercent%) dari $visibleBeans biji terdeteksi. '
          'Proses sortir sebelum seduh dianjurkan.';
    } else if (score >= 40) {
      return 'Kualitas Di Bawah Standar — ditemukan $defectBeans biji berdefect '
          '($defectPercent%) dari $visibleBeans biji. Lakukan sortir menyeluruh '
          'sebelum diseduh.';
    } else {
      return 'Kualitas Off-Grade — tingkat defect sangat tinggi ($defectPercent%). '
          'Tidak disarankan untuk diseduh tanpa sortir ulang secara menyeluruh.';
    }
  }

  String _roastLabel(String roast) {
    switch (roast.toLowerCase()) {
      case 'light':
        return 'light roast';
      case 'medium':
        return 'medium roast';
      case 'dark':
        return 'dark roast';
      default:
        return roast.toLowerCase();
    }
  }
}

