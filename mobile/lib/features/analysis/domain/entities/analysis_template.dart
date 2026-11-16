/// Template analisis statis — pengganti sementara hasil pipeline ML.
///
/// Sumber data: `assets/knowledge/analysis_templates.json`. Satu template
/// mengisi semua kolom `analyses` yang berkaitan dengan hasil analisis
/// (species/roast/uniformity) plus komposisi defect 4 kelas. Nilai di sini
/// bersifat dummy deterministik dan akan digantikan hasil inference nyata
/// (PRD AC-01/AC-03).
library;

import '../../../../shared/enums/defect_class.dart';

class AnalysisTemplate {
  const AnalysisTemplate({
    required this.id,
    required this.species,
    required this.roast,
    required this.roastConfidence,
    required this.roastDistribution,
    required this.visibleBeans,
    required this.defectCounts,
    required this.shapeUniformity,
    required this.sizeUniformity,
    required this.roastUniformity,
    required this.summaryText,
  });

  /// ID unik template, mis. `TPL-AR-L`.
  final String id;

  /// Species kanonik: `Arabica` / `Robusta` / `Liberika` / `Mixed`.
  final String species;

  /// Roast kanonik: `Light` / `Medium` / `Dark` (`Green` tidak termasuk — AC-04).
  final String roast;

  /// Confidence deteksi roast (0.0–1.0), hanya atribut provenance.
  final double roastConfidence;

  /// Sebaran roast per biji, mis. `{'Light': 0.8, 'Medium': 0.2}`.
  final Map<String, double> roastDistribution;

  /// Jumlah biji terlihat di foto.
  final int visibleBeans;

  /// Komposisi defect 4 kelas; total == [visibleBeans].
  final Map<DefectClass, int> defectCounts;

  /// Uniformity bentuk (0.0–1.0). Ditampilkan, tidak masuk skor (PRD §8).
  final double shapeUniformity;

  /// Uniformity ukuran (0.0–1.0). Ditampilkan, tidak masuk skor (PRD §8).
  final double sizeUniformity;

  /// Uniformity roast (0.0–1.0). Ditampilkan, tidak masuk skor (PRD §8).
  final double roastUniformity;

  /// Narasi ringkas hasil analisis (tampilan Detail Inspeksi).
  final String summaryText;

  /// Parsing dari bentuk JSON asset (key snake_case, nama defect Title Case).
  factory AnalysisTemplate.fromMap(Map<String, dynamic> map) {
    final countsRaw = map['defect_counts'] as Map<String, dynamic>;
    final counts = <DefectClass, int>{};
    countsRaw.forEach((key, value) {
      final cls = defectClassFromName(key);
      if (cls != null) counts[cls] = (value as num).toInt();
    });

    final distRaw = map['roast_distribution'] as Map<String, dynamic>;

    return AnalysisTemplate(
      id: map['id'] as String,
      species: map['species'] as String,
      roast: map['roast'] as String,
      roastConfidence: (map['roast_confidence'] as num).toDouble(),
      roastDistribution: <String, double>{
        for (final e in distRaw.entries) e.key: (e.value as num).toDouble(),
      },
      visibleBeans: (map['visible_beans'] as num).toInt(),
      defectCounts: counts,
      shapeUniformity: (map['shape_uniformity'] as num).toDouble(),
      sizeUniformity: (map['size_uniformity'] as num).toDouble(),
      roastUniformity: (map['roast_uniformity'] as num).toDouble(),
      summaryText: map['summary_text'] as String,
    );
  }
}
