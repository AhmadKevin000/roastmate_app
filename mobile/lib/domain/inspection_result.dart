import 'dart:ui';

enum DefectClass { healthy, broken, insectDamage, quaker, scorched, foreignMatter }
enum QualityProfile { high, medium, low }
enum IndicativeGrade { specialty, premium, standard, belowStandard, offGrade }

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

  int get healthyCount => defectCounts[DefectClass.healthy] ?? 0;

  double get defectRate => visibleBeans > 0 ? (visibleBeans - healthyCount) / visibleBeans : 0.0;

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
}

class AlternativeMethod {
  final String title;
  final String description;

  AlternativeMethod({required this.title, required this.description});
}

class BeanDetection {
  final DefectClass classLabel;
  final Rect normalizedRect; // 0..1
  final double confidence;

  BeanDetection({
    required this.classLabel,
    required this.normalizedRect,
    required this.confidence,
  });
}
