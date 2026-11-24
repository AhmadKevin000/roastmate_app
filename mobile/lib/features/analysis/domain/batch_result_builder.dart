import '../../../../inference/batch_aggregation.dart';
import '../../../../inference/inference_pipeline.dart';
import '../../../../shared/models/analysis_result.dart';
import '../../result/domain/entities/analysis_detail.dart';
import 'quality_engine.dart';

/// Bangun [InspectionResult] dari hasil inference nyata (menggantikan
/// [buildResultFromTemplate]).
///
/// Skor dihitung ulang lewat [QualityEngine] dari defect counts (PRD AC-03),
/// bukan menyalin angka dari model.
InspectionResult buildResultFromBatch(
  BatchSummary summary,
  String batchName,
  String batchLabel,
) {
  final qualityScore = QualityEngine.qualityScore(
    QualityEngine.defectRate(summary.defectCounts, summary.visibleBeans),
  );

  final draft = InspectionResult(
    batchLabel: batchLabel,
    batchName: batchName,
    analyzedAgo: 'Dipindai baru saja',
    qualityScore: qualityScore,
    visibleBeans: summary.visibleBeans,
    defectCounts: summary.defectCounts,
    species: summary.species,
    roast: summary.roast,
    summaryText: '',
    alternatives: const [],
    detections: summary.detections,
    modelVersion: kModelVersion,
    shapeUniformity: summary.shapeUniformity,
    sizeUniformity: summary.sizeUniformity,
    roastUniformity: summary.roastUniformity,
    roastConfidence: summary.roastConfidence,
    roastDistribution: summary.roastDistribution,
  );

  // summaryText tidak disimpan di DB (D-20) — di-generate dari hasil.
  return draft.copyWith(summaryText: buildAnalysisSummary(draft));
}
