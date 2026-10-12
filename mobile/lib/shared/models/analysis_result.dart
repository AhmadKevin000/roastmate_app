import '../enums/defect_class.dart';
import '../enums/indicative_grade.dart';
import '../enums/quality_profile.dart';
import 'bean_detection.dart';

// Re-export enum & model terkait agar konsumen cukup mengimpor satu berkas hasil.
export '../enums/defect_class.dart';
export '../enums/indicative_grade.dart';
export '../enums/quality_profile.dart';
export 'bean_detection.dart';

/// Hasil lengkap satu sesi analisis batch (Detail Inspeksi).
class InspectionResult {
  final String batchLabel;
  final String batchName;
  final String analyzedAgo;
  final int qualityScore;
  final int visibleBeans;
  final Map<DefectClass, int> defectCounts;
  final String species;
  final String roast;
  final String summaryText;
  final BrewRecommendation? recommendation;
  final List<AlternativeMethod> alternatives;
  final List<BeanDetection> detections;
  final String modelVersion;

  InspectionResult({
    required this.batchLabel,
    required this.batchName,
    required this.analyzedAgo,
    required this.qualityScore,
    required this.visibleBeans,
    required this.defectCounts,
    required this.species,
    required this.roast,
    required this.summaryText,
    this.recommendation,
    required this.alternatives,
    required this.detections,
    required this.modelVersion,
  });

  /// Salinan dengan sebagian field diganti (mis. menimpa `batchName` dari
  /// nama yang diisi pengguna pada form sebelum scan).
  InspectionResult copyWith({
    String? batchLabel,
    String? batchName,
    String? analyzedAgo,
    int? qualityScore,
    int? visibleBeans,
    Map<DefectClass, int>? defectCounts,
    String? species,
    String? roast,
    String? summaryText,
    BrewRecommendation? recommendation,
    List<AlternativeMethod>? alternatives,
    List<BeanDetection>? detections,
    String? modelVersion,
  }) {
    return InspectionResult(
      batchLabel: batchLabel ?? this.batchLabel,
      batchName: batchName ?? this.batchName,
      analyzedAgo: analyzedAgo ?? this.analyzedAgo,
      qualityScore: qualityScore ?? this.qualityScore,
      visibleBeans: visibleBeans ?? this.visibleBeans,
      defectCounts: defectCounts ?? this.defectCounts,
      species: species ?? this.species,
      roast: roast ?? this.roast,
      summaryText: summaryText ?? this.summaryText,
      recommendation: recommendation ?? this.recommendation,
      alternatives: alternatives ?? this.alternatives,
      detections: detections ?? this.detections,
      modelVersion: modelVersion ?? this.modelVersion,
    );
  }

  int get healthyCount => defectCounts[DefectClass.healthy] ?? 0;

  double get defectRate =>
      visibleBeans > 0 ? (visibleBeans - healthyCount) / visibleBeans : 0.0;

  QualityProfile get qualityProfile {
    if (qualityScore >= 75) return QualityProfile.high;
    if (qualityScore >= 60) return QualityProfile.medium;
    return QualityProfile.low;
  }

  IndicativeGrade get grade {
    if (qualityScore >= 85) return IndicativeGrade.specialty;
    if (qualityScore >= 75) return IndicativeGrade.premium;
    if (qualityScore >= 60) return IndicativeGrade.standard;
    if (qualityScore >= 40) return IndicativeGrade.belowStandard;
    return IndicativeGrade.offGrade;
  }

  String get defectLabel {
    if (defectRate <= 0.10) return "Defect Rendah";
    if (defectRate <= 0.20) return "Defect Sedang";
    return "Defect Tinggi";
  }

  double percentageForClass(DefectClass defectClass) {
    if (visibleBeans == 0) return 0.0;
    return ((defectCounts[defectClass] ?? 0) / visibleBeans) * 100;
  }
}

class BrewRecommendation {
  final String methodTitle;
  final String reasonText;
  final String ratio;
  final String ratioSub;
  final String tempC;
  final String tempCSub;
  final String grind;
  final String grindSub;
  final String targetTime;
  final String targetTimeSub;

  BrewRecommendation({
    required this.methodTitle,
    required this.reasonText,
    required this.ratio,
    required this.ratioSub,
    required this.tempC,
    required this.tempCSub,
    required this.grind,
    required this.grindSub,
    required this.targetTime,
    required this.targetTimeSub,
  });

  /// Konversi ke representasi seragam untuk tab rekomendasi seduh.
  BrewMethodInfo toInfo() => BrewMethodInfo(
        title: methodTitle,
        description: reasonText,
        ratio: ratio,
        ratioSub: ratioSub,
        tempC: tempC,
        tempCSub: tempCSub,
        grind: grind,
        grindSub: grindSub,
        targetTime: targetTime,
        targetTimeSub: targetTimeSub,
      );
}

class AlternativeMethod {
  final String title;
  final String description;
  final String ratio;
  final String ratioSub;
  final String tempC;
  final String tempCSub;
  final String grind;
  final String grindSub;
  final String targetTime;
  final String targetTimeSub;

  AlternativeMethod({
    required this.title,
    required this.description,
    required this.ratio,
    required this.ratioSub,
    required this.tempC,
    required this.tempCSub,
    required this.grind,
    required this.grindSub,
    required this.targetTime,
    required this.targetTimeSub,
  });

  /// Konversi ke representasi seragam untuk tab rekomendasi seduh.
  BrewMethodInfo toInfo() => BrewMethodInfo(
        title: title,
        description: description,
        ratio: ratio,
        ratioSub: ratioSub,
        tempC: tempC,
        tempCSub: tempCSub,
        grind: grind,
        grindSub: grindSub,
        targetTime: targetTime,
        targetTimeSub: targetTimeSub,
      );
}

/// Representasi seragam satu metode seduh (utama maupun alternatif).
///
/// Dipakai agar isi tiap tab rekomendasi memiliki struktur identik.
class BrewMethodInfo {
  final String title;
  final String description;
  final String ratio;
  final String ratioSub;
  final String tempC;
  final String tempCSub;
  final String grind;
  final String grindSub;
  final String targetTime;
  final String targetTimeSub;

  const BrewMethodInfo({
    required this.title,
    required this.description,
    required this.ratio,
    required this.ratioSub,
    required this.tempC,
    required this.tempCSub,
    required this.grind,
    required this.grindSub,
    required this.targetTime,
    required this.targetTimeSub,
  });
}
