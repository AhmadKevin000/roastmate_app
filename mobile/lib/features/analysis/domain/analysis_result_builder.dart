import '../../../../shared/models/analysis_result.dart';
import 'entities/analysis_template.dart';
import 'quality_engine.dart';

/// Bangun [InspectionResult] lengkap dari satu [AnalysisTemplate]
/// (pengganti sementara pipeline ML — Plan 1/2).
///
/// Skor & defect rate dihitung ulang dari counts via [QualityEngine]
/// (PRD AC-03), bukan menyalin nilai siap jadi, agar konsisten dengan
/// rumus kanonik.
InspectionResult buildResultFromTemplate(
  AnalysisTemplate template,
  String batchName,
  String batchLabel,
) {
  return InspectionResult(
    batchLabel: batchLabel,
    batchName: batchName,
    analyzedAgo: 'Dipindai baru saja',
    qualityScore:
        QualityEngine.qualityScore(
          QualityEngine.defectRate(
            template.defectCounts,
            template.visibleBeans,
          ),
        ),
    visibleBeans: template.visibleBeans,
    defectCounts: template.defectCounts,
    species: template.species,
    roast: template.roast,
    summaryText: template.summaryText,
    alternatives: const [],
    detections: const [],
    modelVersion: 'template-v1',
    shapeUniformity: template.shapeUniformity,
    sizeUniformity: template.sizeUniformity,
    roastUniformity: template.roastUniformity,
    roastConfidence: template.roastConfidence,
    roastDistribution: template.roastDistribution,
  );
}
