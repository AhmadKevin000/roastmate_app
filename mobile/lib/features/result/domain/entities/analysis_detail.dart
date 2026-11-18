import '../../../analysis/domain/entities/analysis_history_item.dart';
import '../../../../shared/models/analysis_result.dart';
import '../../../../shared/utils/brew_label_helpers.dart';

/// Data lengkap satu analisis yang dibaca dari SQLite per [analysisId]
/// (Plan 3): [result] (`analyses` + `analysis_defects`), foto
/// [imagePath] (URL Cloudinary atau path lokal), rekomendasi + alternatif
/// dari join knowledge base, dan [summaryText] yang di-generate saat baca
/// (D-20 — tidak disimpan di DB).
class AnalysisDetail {
  const AnalysisDetail({
    required this.analysisId,
    required this.result,
    this.imagePath,
    this.recommendation,
    this.alternatives = const [],
    required this.summaryText,
    this.personalRating,
    this.personalRatingNote,
  });

  final int analysisId;

  /// Hasil `_fromRow` repository + counts defect 4 kelas.
  final InspectionResult result;

  /// URL Cloudinary atau path lokal; null/kosong → placeholder UI.
  final String? imagePath;

  /// Dari join `recommendations` + `brew_methods`/`brew_recipes`;
  /// null untuk baris lama tanpa rekomendasi.
  final BrewRecommendation? recommendation;

  /// Maksimal satu alternatif (D-20).
  final List<AlternativeMethod> alternatives;

  /// Satu kalimat deterministic, di-generate runtime (D-20).
  final String summaryText;

  /// Penilaian pribadi user (bintang 1–5), null = belum dinilai.
  final int? personalRating;

  /// Catatan penilaian pribadi (opsional).
  final String? personalRatingNote;

  /// [result] dengan rekomendasi, alternatif, dan ringkasan terisi —
  /// satu bentuk data untuk layar detail dan seluruh kartunya.
  InspectionResult get displayResult => result.copyWith(
        summaryText: summaryText,
        recommendation: recommendation,
        alternatives: alternatives,
      );
}

/// Bangun [BrewRecommendation] dari baris join `getDetail`
/// (metode + resep utama + `reason`). Pure — bisa diuji tanpa DB.
BrewRecommendation toBrewRecommendation(Map<String, Object?> row) {
  final methodName = (row['primary_method_name'] as String?) ?? '';
  final subtitle = (row['primary_method_subtitle'] as String?) ?? '';
  final dose = (row['dose_g'] as num?)?.toDouble();
  final water = (row['water_volume_ml'] as num?)?.toInt();
  final temp = (row['temperature_c'] as num?)?.toInt();
  final time = (row['brewing_time_s'] as num?)?.toInt();

  return BrewRecommendation(
    methodTitle: subtitle.isNotEmpty ? '$methodName — $subtitle' : methodName,
    reasonText: (row['reason'] as String?) ?? '',
    ratio: brewRatioLabel(doseG: dose, waterVolumeMl: water),
    ratioSub: dose == null || water == null
        ? '—'
        : '${formatDoseGrams(dose)}g : ${water}ml air',
    tempC: temp == null ? '—' : '$temp°C',
    tempCSub: '',
    grind: (row['grind_size'] as String?) ?? '',
    grindSub: '',
    targetTime: time == null ? '—' : formatBrewSeconds(time),
    targetTimeSub: '',
  );
}

/// Bangun [AlternativeMethod] dari baris join `getDetail`
/// (metode alternatif + resep default species analisis).
/// Null bila metode alternatif tidak ada/terisi.
AlternativeMethod? toAlternativeMethod(Map<String, Object?> row) {
  final methodName = row['alt_method_name'] as String?;
  if (methodName == null) return null;
  final subtitle = (row['alt_method_subtitle'] as String?) ?? '';
  final dose = (row['a_dose'] as num?)?.toDouble();
  final water = (row['a_water'] as num?)?.toInt();
  final temp = (row['a_temp'] as num?)?.toInt();
  final time = (row['a_time'] as num?)?.toInt();

  final ratio = brewRatioLabel(doseG: dose, waterVolumeMl: water);
  final timeLabel = time == null ? null : formatBrewSeconds(time);

  return AlternativeMethod(
    title: subtitle.isNotEmpty ? '$methodName — $subtitle' : methodName,
    description: [if (ratio != '—') 'Rasio $ratio', ?timeLabel].join(' · '),
    ratio: ratio,
    ratioSub: dose == null || water == null
        ? '—'
        : '${formatDoseGrams(dose)}g : ${water}ml air',
    tempC: temp == null ? '—' : '$temp°C',
    tempCSub: '',
    grind: (row['a_grind'] as String?) ?? '',
    grindSub: '',
    targetTime: timeLabel ?? '—',
    targetTimeSub: '',
  );
}

/// Generate `summaryText` deterministic satu kalimat (D-20 — tidak
/// disimpan di DB): identitas batch, defect rate berbobot, skor, profile,
/// plus klause kelas defect dominan bila ada.
String buildAnalysisSummary(InspectionResult result) {
  final profile = switch (result.qualityProfile) {
    QualityProfile.high => 'High',
    QualityProfile.medium => 'Medium',
    QualityProfile.low => 'Low',
  };
  final text = '${result.batchName} (${result.species}, ${result.roast}): '
      '${result.visibleBeans} biji, '
      'defect rate ${(result.defectRate * 100).toStringAsFixed(1)}%, '
      'skor ${result.qualityScore}/100 ($profile).';

  final dominant = _dominantDefectClass(result);
  if (dominant == null) return text;
  return '$text Defect dominan: ${defectShortLabel(dominant)}.';
}

/// Kelas defect (selain Normal) dengan jumlah terbanyak; null bila
/// tidak ada defect.
DefectClass? _dominantDefectClass(InspectionResult result) {
  DefectClass? best;
  var bestCount = 0;
  for (final entry in result.defectCounts.entries) {
    if (entry.key == DefectClass.normal || entry.value <= bestCount) continue;
    best = entry.key;
    bestCount = entry.value;
  }
  return best;
}
